#!/usr/bin/env python3
"""Transliterate Magpie Anime4K Restore HLSL (compute, MagpieFX) to ReShade FX (.fx).

Strategy per pass:
- Gather-style passes (Pass1): replicate the exact gather block with base B = output
  pixel p and evaluate the (i,j)=(1,1) iteration only. tex2Dgather == D3D Gather.
- Sample-style passes: near-verbatim copy with type renames + SampleLevel rewrite.
- L intermediate passes write 2 textures -> split into a/b single-output passes
  (MRT support varies across runtimes; splitting is portable).
- MulAdd() provided as a macro (identical semantics to HLSL mul()+add).

Usage: gen_restore_fx.py --variant S|M|L|Soft_S|Soft_M|Soft_L|VL|UL|Soft_VL|Soft_UL
           [--magpie-dir DIR] [--out PATH]

  --magpie-dir defaults to ../magpie-upstream/Magpie (a Magpie checkout is
  needed only to *regenerate* shaders; the committed .fx files need nothing).
  --out defaults to <this-dir>/Anime4K_Restore_<VARIANT>.fx.
"""
import argparse
import os
import re
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_ap = argparse.ArgumentParser(description="Port Magpie Anime4K Restore HLSL to ReShade FX.")
_ap.add_argument("--variant", required=True,
                 choices=["S", "M", "L", "Soft_S", "Soft_M", "Soft_L",
                          "VL", "UL", "Soft_VL", "Soft_UL"])
_ap.add_argument("--magpie-dir", default=os.path.join(_HERE, "..", "magpie-upstream", "Magpie"))
_ap.add_argument("--out", default=None)
_args = _ap.parse_args()

VARIANT = _args.variant


def _hlsl_path(base, variant):
    """Find the source HLSL. Magpie checkouts differ: upstream has
    src/Effects/Anime4K, some trees ship effects/Anime4K, and --magpie-dir may
    point straight at the Anime4K folder."""
    name = f"Anime4K_Restore_{variant}.hlsl"
    for cand in (os.path.join(base, "src", "Effects", "Anime4K", name),
                 os.path.join(base, "effects", "Anime4K", name),
                 os.path.join(base, name)):
        if os.path.isfile(cand):
            return cand
    return os.path.join(base, "src", "Effects", "Anime4K", name)


HLSL_PATH = _hlsl_path(_args.magpie_dir, VARIANT)
OUT_PATH = _args.out or os.path.join(_HERE, f"Anime4K_Restore_{VARIANT}.fx")

src = open(HLSL_PATH).read()

# ---------------------------------------------------------------- helpers

def tex_to_sampler(t):
    return {"INPUT": "SampInput", "tex1": "SampT1", "tex2": "SampT2",
            "tex3": "SampT3", "tex4": "SampT4", "tex5": "SampT5",
            "tex6": "SampT6", "tex7": "SampT7", "tex8": "SampT8"}[t]

def rename_types(line):
    line = line.replace("MF4x4", "float4x4").replace("MF3x4", "float3x4").replace("MF4x3", "float4x3")
    line = re.sub(r"\bMF4\b", "float4", line)
    line = re.sub(r"\bMF3\b", "float3", line)
    return line

def norm_src_refs(line):
    # src[i +/- d][j +/- e] with (i,j) == (1,1), offsets optional,
    # then flatten array to scalars: src[a][b] -> srcAB
    # (ReShade FX has no local arrays)
    def rep(m):
        di = int(m.group(2)) if m.group(2) else 0
        if m.group(1) == "-":
            di = -di
        dj = int(m.group(4)) if m.group(4) else 0
        if m.group(3) == "-":
            dj = -dj
        return f"src{1 + di}{1 + dj}"
    return re.sub(r"src\[i\s*(?:([+-])\s*(\d+))?\]\[j\s*(?:([+-])\s*(\d+))?\]", rep, line)

def expand_muladd(line):
    """MulAdd(EXPR, floatRxC(a0, ...), BIAS)  ->  floatC(dot..) + BIAS.
    ReShade FX has no rectangular matrices; expand to dots.
    HLSL constructor fills row-major, mul(x, M)[j] = dot(x, column j),
    so output j = dot(x, (args[j], args[j+C], ...)). Identical to mul()."""
    # Accept an optional type prefix so declarations used as initializers
    # (e.g. "MF3 target4 = MulAdd(...)", renamed to float3 first) convert too.
    m = re.match(r"^(\s*(?:float[34]\s+)?\w+\s*=\s*)MulAdd\((.*)$", line)
    if not m:
        return line
    prefix, rest = m.group(1), m.group(2)
    mm = re.search(r",\s*float([34])x([34])\(", rest)
    if not mm:
        return line
    expr = rest[:mm.start()].strip()
    rows, cols = int(mm.group(1)), int(mm.group(2))
    after = rest[mm.end():]
    # ARGS up to balanced close paren (flat numbers only)
    depth, idx = 0, 0
    for idx, ch in enumerate(after):
        if ch == "(":
            depth += 1
        elif ch == ")":
            if depth == 0:
                break
            depth -= 1
    argstr = after[:idx]
    bias = after[idx + 1:].lstrip()
    assert bias.startswith(","), bias
    bias = bias[1:].rstrip()
    assert bias.endswith(";"), bias
    bias = bias[:-1].strip()
    assert bias.endswith(")"), bias  # MulAdd's own closing paren
    bias = bias[:-1].strip()
    args = [a.strip() for a in argstr.split(",")]
    assert len(args) == rows * cols, (len(args), rows, cols)
    dots = []
    for j in range(cols):
        col = [args[i * cols + j] for i in range(rows)]
        dots.append(f"dot(({expr}), float{rows}({', '.join(col)}))")
    return f"{prefix}float{cols}({', '.join(dots)}) + ({bias});"

def convert_sample(line):
    # tex.SampleLevel(sam, POS, 0) -> tex2Dlod(SampT, float4(POS, 0, 0))
    # NOTE: greedy (.*) so nested float2(-rcp.x, 0) commas don't split early.
    def rep(m):
        return f"tex2Dlod({tex_to_sampler(m.group(1))}, float4({m.group(2)}, 0, 0))"
    return re.sub(r"(\bINPUT\b|\btex\d\b)\.SampleLevel\(sam,\s*(.*),\s*0\)", rep, line)

def split_passes(text):
    parts = re.split(r"//!PASS \d+", text)
    descs = re.findall(r"//!PASS \d+", text)
    bodies = []
    for marker, part in zip(descs, parts[1:]):
        in_match = re.search(r"//!IN\s+(.*)", part)
        out_match = re.search(r"//!OUT\s+(.*)", part)
        ins = [t.strip() for t in in_match.group(1).split(",")] if in_match else []
        outs = [t.strip() for t in out_match.group(1).split(",")] if out_match else []
        # function body: from first '{' after 'void Pass' to matching close at col 0
        fn = re.search(r"void Pass\d+\(.*?\{(.*)^\}", part, re.S | re.M)
        bodies.append({"ins": ins, "outs": outs, "body": fn.group(1) if fn else ""})
    return bodies

# ---------------------------------------------------------------- header builder

HEADER_TOP = """// Anime4K Restore CNN (%s) ported to ReShade FX.
// Source: Magpie Anime4K_Restore_%s.hlsl <- bloc97/Anime4K glsl/Restore.
// 1:1 restoration (removes compression artifacts, blur, ringing). No scaling.
// Works in vkBasalt and gamescope --reshade-effect (single technique, no depth).
// NOTE: matrix/vector math expanded to dot() (ReShade FX lacks float3x4 etc).

texture Anime4K_Input : COLOR;

"""

def emit_texture(n):
    return f"""texture Anime4K_T{n}
{{
\tWidth = BUFFER_WIDTH;
\tHeight = BUFFER_HEIGHT;
\tFormat = RGBA16F;
\tMipLevels = 1;
}};
"""

def emit_sampler(n):
    tex = "Anime4K_Input" if n == 0 else f"Anime4K_T{n}"
    samp = "SampInput" if n == 0 else f"SampT{n}"
    return f"""sampler {samp}
{{
\tTexture = {tex};
\tMagFilter = POINT;
\tMinFilter = POINT;
\tMipFilter = POINT;
\tAddressU = CLAMP;
\tAddressV = CLAMP;
\tSRGBTexture = FALSE;
}};
"""

VS = """void Anime4K_VS(uint id : SV_VertexID, out float4 pos : SV_Position, out float2 uv : TEXCOORD0)
{
\tuv = float2((id << 1) & 2, id & 2);
\tpos = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

"""

def build_header(variant, ntex):
    parts = [HEADER_TOP % (variant, variant)]
    parts += [emit_texture(i) for i in range(1, ntex + 1)]
    parts.append(emit_sampler(0))
    parts += [emit_sampler(i) for i in range(1, ntex + 1)]
    parts.append(VS)
    return "\n".join(parts)


PIXEL_PREAMBLE = ("\tint2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));\n"
                  "\tfloat2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);\n")

# ---------------------------------------------------------------- gather block emitter

def emit_gather(tex, nch, arrtype):
    """Emit 4 gather groups filling src[4][4] for output pixel block base b=pix."""
    samp = tex_to_sampler(tex)
    comp = ["x", "y", "z", "w"]
    chan = list(range(nch))
    vardecls = ", ".join(f"src{a}{b}" for a in range(4) for b in range(4))
    lines = [f"\t{arrtype} {vardecls};"]
    for (ox, oy) in [(0, 0), (0, 2), (2, 0), (2, 2)]:
        lines.append(f"\tfloat2 tpos_{ox}_{oy} = (float2(pix) + float2({ox}, {oy})) * rcp;")
        for c in chan:
            lines.append(f"\tfloat4 g{ox}_{oy}_{comp[c]} = tex2Dgather({samp}, tpos_{ox}_{oy}, {c});")
        vals = lambda k: ", ".join(f"g{ox}_{oy}_{comp[c]}.{k}" for c in chan)
        # swizzle: [i][j]=w, [i][j+1]=x, [i+1][j]=z, [i+1][j+1]=y
        lines.append(f"\tsrc{ox}{oy} = {arrtype}({vals('w')});")
        lines.append(f"\tsrc{ox}{oy + 1} = {arrtype}({vals('x')});")
        lines.append(f"\tsrc{ox + 1}{oy} = {arrtype}({vals('z')});")
        lines.append(f"\tsrc{ox + 1}{oy + 1} = {arrtype}({vals('y')});")
    return "\n".join(lines)

# ---------------------------------------------------------------- pass transformers

def brace_init(line):
    # floatN name = {a, b, ...};  ->  floatN name = floatN(a, b, ...);
    # (ReShade parses {...} as an array otherwise)
    return re.sub(r"\b(float[34])\s+(\w+)\s*=\s*\{(.*?)\};",
                  lambda m: f"{m.group(1)} {m.group(2)} = {m.group(1)}({m.group(3)});", line)

def chain_lines(body, targets):
    """Extract 'target = ...' lines (initializer + MulAdd chain) for wanted targets."""
    out = []
    for line in body.splitlines():
        s = line.strip()
        m = re.match(r"(float\d|MF\d)\s+(target\d+|result)\s*=", s)  # may already be renamed? no, raw
        m2 = re.match(r"(target\d+|result)\s*=\s*(MulAdd|max|min|\{|\()", s)
        if m or m2:
            name = (m.group(2) if m else m2.group(1))
            if name in targets:
                out.append("\t" + expand_muladd(norm_src_refs(brace_init(rename_types(s)))))
    return out

def gather_pass(psname, hlslname, tex, nch, arrtype, targets, outvar):
    """Build a single-output gather-style pass from HLSL Pass1-like body."""
    body = next(p["body"] for p in PASSES if p.get("hlname") == hlslname)
    lines = [f"void {psname}(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 {outvar} : SV_Target0)",
             "{", PIXEL_PREAMBLE.rstrip(),
             emit_gather(tex, nch, arrtype)]
    lines += chain_lines(body, targets)
    lines.append(f"\t{outvar} = {targets[0]};")
    lines.append("}")
    return "\n".join(lines)

def sample_pass(psname, hlslname, outvar, keep_targets=None, out_src=None):
    """Near-verbatim copy of a SampleLevel-style pass.
    keep_targets: only keep initializer+chain lines for these LHS names
      (used to split dual-output passes into a/b). None = keep all.
    out_src: only honor texture writes from this source name
      (e.g. 'tex3' writes; others dropped). None = honor all , mapped to outvar."""
    body = next(p["body"] for p in PASSES if p.get("hlname") == hlslname)
    out = [f"void {psname}(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 {outvar} : SV_Target0)", "{"]
    out.append(PIXEL_PREAMBLE.rstrip())
    for line in body.splitlines():
        s = line.strip()
        if not s:
            continue
        if s.startswith("//") or s.startswith("[unroll]") or s.startswith("#"):
            continue
        if re.match(r"(uint|uint2|float2 inputPt|const uint2 output|const uint2 input)", s):
            continue
        if "GetInputSize" in s or "GetOutputSize" in s or "Rmp8x8" in s:
            continue
        if re.match(r"if\s*\(gxy", s):
            continue
        if s == "return;":
            continue
        if s in ("{", "}"):
            continue
        if "GetInputPt()" in s:
            continue
        s = s.replace("inputPt", "rcp")
        if re.match(r"float2 pos = ", s):
            out.append("\tfloat2 pos = (float2(pix) + 0.5) * rcp;")
            continue
        raw = line.strip()
        m_assign = re.match(r"(target\d+|result)\s*=", raw)
        if m_assign and keep_targets is not None and m_assign.group(1) not in keep_targets:
            continue  # other target's chain (split pass)
        m = re.match(r"(INPUT|tex\d)\[gxy\]\s*=\s*(.*);", raw)
        if m:
            if out_src is not None and m.group(1) != out_src:
                continue  # other target's write (split pass)
            out.append(f"\t{outvar} = {rename_types(m.group(2))};")
            continue
        m = re.match(r"OUTPUT\[gxy\]\s*=\s*MF4\((.*),\s*1\);", raw)
        if m:
            out.append(f"\t{outvar} = float4({rename_types(m.group(1))}, 1.0);")
            continue
        if "OUTPUT[gxy]" in raw:
            continue
        s = rename_types(s)
        s = brace_init(s)
        s = convert_sample(s)
        s = expand_muladd(s)  # no-op when the line is not a MulAdd
        out.append("\t" + s)
    out.append("}")
    return "\n".join(out)

# ---------------------------------------------------------------- main

raw_passes = split_passes(src)
PASSES = []
for i, p in enumerate(raw_passes, 1):
    p["hlname"] = f"HLPass{i}"
    PASSES.append(p)

# Pass specs: ("gather", hl, ps, src_tex, nch, arrtype, [targets], out_tex)
#          or ("sample", hl, ps, out_tex_or_None, keep_or_None, out_src_or_None)
# Dual-output HLSL passes are split into a/b single-output passes (no MRT).
SPECS = {
    # S and Soft_S share the shape (verified identical IN/OUT wiring).
    "S": {"ntex": 2, "passes": [
        ("gather", "HLPass1", "Anime4K_PS1", "INPUT", 3, "float3", ["result"], "Anime4K_T1"),
        ("gather", "HLPass2", "Anime4K_PS2", "tex1", 4, "float4", ["result"], "Anime4K_T2"),
        ("gather", "HLPass3", "Anime4K_PS3", "tex2", 4, "float4", ["result"], "Anime4K_T1"),
        ("sample", "HLPass4", "Anime4K_PS4", None, None, None),
    ]},
    "Soft_S": {"ntex": 2, "passes": [
        ("gather", "HLPass1", "Anime4K_PS1", "INPUT", 3, "float3", ["result"], "Anime4K_T1"),
        ("gather", "HLPass2", "Anime4K_PS2", "tex1", 4, "float4", ["result"], "Anime4K_T2"),
        ("gather", "HLPass3", "Anime4K_PS3", "tex2", 4, "float4", ["result"], "Anime4K_T1"),
        ("sample", "HLPass4", "Anime4K_PS4", None, None, None),
    ]},
    # L and Soft_L share the shape (verified identical IN/OUT wiring).
    "L": {"ntex": 4, "passes": [
        ("gather", "HLPass1", "Anime4K_PS1a", "INPUT", 3, "float3", ["target1"], "Anime4K_T1"),
        ("gather", "HLPass1", "Anime4K_PS1b", "INPUT", 3, "float3", ["target2"], "Anime4K_T2"),
        ("sample", "HLPass2", "Anime4K_PS2a", "Anime4K_T3", ("target1",), "tex3"),
        ("sample", "HLPass2", "Anime4K_PS2b", "Anime4K_T4", ("target2",), "tex4"),
        ("sample", "HLPass3", "Anime4K_PS3a", "Anime4K_T1", ("target1",), "tex1"),
        ("sample", "HLPass3", "Anime4K_PS3b", "Anime4K_T2", ("target2",), "tex2"),
        ("sample", "HLPass4", "Anime4K_PS4a", "Anime4K_T3", ("target1",), "tex3"),
        ("sample", "HLPass4", "Anime4K_PS4b", "Anime4K_T4", ("target2",), "tex4"),
        ("sample", "HLPass5", "Anime4K_PS5", None, None, None),
    ]},
    "Soft_L": {"ntex": 4, "passes": [
        ("gather", "HLPass1", "Anime4K_PS1a", "INPUT", 3, "float3", ["target1"], "Anime4K_T1"),
        ("gather", "HLPass1", "Anime4K_PS1b", "INPUT", 3, "float3", ["target2"], "Anime4K_T2"),
        ("sample", "HLPass2", "Anime4K_PS2a", "Anime4K_T3", ("target1",), "tex3"),
        ("sample", "HLPass2", "Anime4K_PS2b", "Anime4K_T4", ("target2",), "tex4"),
        ("sample", "HLPass3", "Anime4K_PS3a", "Anime4K_T1", ("target1",), "tex1"),
        ("sample", "HLPass3", "Anime4K_PS3b", "Anime4K_T2", ("target2",), "tex2"),
        ("sample", "HLPass4", "Anime4K_PS4a", "Anime4K_T3", ("target1",), "tex3"),
        ("sample", "HLPass4", "Anime4K_PS4b", "Anime4K_T4", ("target2",), "tex4"),
        ("sample", "HLPass5", "Anime4K_PS5", None, None, None),
    ]},
    # M: 6x gather chain (dense final over all intermediates + INPUT residual).
    "M": {"ntex": 6, "passes": [
        ("gather", "HLPass1", "Anime4K_PS1", "INPUT", 3, "float3", ["result"], "Anime4K_T1"),
        ("gather", "HLPass2", "Anime4K_PS2", "tex1", 4, "float4", ["result"], "Anime4K_T2"),
        ("gather", "HLPass3", "Anime4K_PS3", "tex2", 4, "float4", ["result"], "Anime4K_T3"),
        ("gather", "HLPass4", "Anime4K_PS4", "tex3", 4, "float4", ["result"], "Anime4K_T4"),
        ("gather", "HLPass5", "Anime4K_PS5", "tex4", 4, "float4", ["result"], "Anime4K_T5"),
        ("gather", "HLPass6", "Anime4K_PS6", "tex5", 4, "float4", ["result"], "Anime4K_T6"),
        ("sample", "HLPass7", "Anime4K_PS7", None, None, None),
    ]},
}

# Soft_M has identical pass wiring to M (only the trained weights differ), so
# it reuses M's spec shape.
SPECS["Soft_M"] = {"ntex": 6, "passes": SPECS["M"]["passes"]}

# UL: 8 HLSL passes, 8 logical textures, multi-output passes split 1:1.
# Pass1 is gather (3 targets), Pass2-7 are sample passes (3 targets, the last
# three also a 4th), Pass8 is the final residual. Derived from the HLSL
# texN[gxy]/[destPos] write lines.
UL_PASSES = [
    ("gather", "HLPass1", "Anime4K_PS1a", "INPUT", 3, "float3", ["target1"], "Anime4K_T1"),
    ("gather", "HLPass1", "Anime4K_PS1b", "INPUT", 3, "float3", ["target2"], "Anime4K_T2"),
    ("gather", "HLPass1", "Anime4K_PS1c", "INPUT", 3, "float3", ["target3"], "Anime4K_T3"),
    ("sample", "HLPass2", "Anime4K_PS2a", "Anime4K_T4", ("target1",), "tex4"),
    ("sample", "HLPass2", "Anime4K_PS2b", "Anime4K_T5", ("target2",), "tex5"),
    ("sample", "HLPass2", "Anime4K_PS2c", "Anime4K_T6", ("target3",), "tex6"),
    ("sample", "HLPass3", "Anime4K_PS3a", "Anime4K_T1", ("target1",), "tex1"),
    ("sample", "HLPass3", "Anime4K_PS3b", "Anime4K_T2", ("target2",), "tex2"),
    ("sample", "HLPass3", "Anime4K_PS3c", "Anime4K_T3", ("target3",), "tex3"),
    ("sample", "HLPass4", "Anime4K_PS4a", "Anime4K_T4", ("target1",), "tex4"),
    ("sample", "HLPass4", "Anime4K_PS4b", "Anime4K_T5", ("target2",), "tex5"),
    ("sample", "HLPass4", "Anime4K_PS4c", "Anime4K_T6", ("target3",), "tex6"),
    ("sample", "HLPass5", "Anime4K_PS5a", "Anime4K_T1", ("target1",), "tex1"),
    ("sample", "HLPass5", "Anime4K_PS5b", "Anime4K_T2", ("target2",), "tex2"),
    ("sample", "HLPass5", "Anime4K_PS5c", "Anime4K_T3", ("target3",), "tex3"),
    ("sample", "HLPass5", "Anime4K_PS5d", "Anime4K_T7", ("target4",), "tex7"),
    ("sample", "HLPass6", "Anime4K_PS6a", "Anime4K_T4", ("target1",), "tex4"),
    ("sample", "HLPass6", "Anime4K_PS6b", "Anime4K_T5", ("target2",), "tex5"),
    ("sample", "HLPass6", "Anime4K_PS6c", "Anime4K_T6", ("target3",), "tex6"),
    ("sample", "HLPass6", "Anime4K_PS6d", "Anime4K_T8", ("target4",), "tex8"),
    ("sample", "HLPass7", "Anime4K_PS7a", "Anime4K_T1", ("target1",), "tex1"),
    ("sample", "HLPass7", "Anime4K_PS7b", "Anime4K_T2", ("target2",), "tex2"),
    ("sample", "HLPass7", "Anime4K_PS7c", "Anime4K_T3", ("target3",), "tex3"),
    ("sample", "HLPass7", "Anime4K_PS7d", "Anime4K_T7", ("target4",), "tex7"),
    ("sample", "HLPass8", "Anime4K_PS8", None, None, None),
]
SPECS["UL"] = {"ntex": 8, "passes": UL_PASSES}
SPECS["Soft_UL"] = {"ntex": 8, "passes": UL_PASSES}

# VL: 8 HLSL passes, 6 logical textures (Pass1 gather 2 targets; the sample
# passes carry 3 targets each; Pass8 is the final residual).
VL_PASSES = [
    ("gather", "HLPass1", "Anime4K_PS1a", "INPUT", 3, "float3", ["target1"], "Anime4K_T1"),
    ("gather", "HLPass1", "Anime4K_PS1b", "INPUT", 3, "float3", ["target2"], "Anime4K_T2"),
    ("sample", "HLPass2", "Anime4K_PS2a", "Anime4K_T3", ("target1",), "tex3"),
    ("sample", "HLPass2", "Anime4K_PS2b", "Anime4K_T4", ("target2",), "tex4"),
    ("sample", "HLPass3", "Anime4K_PS3a", "Anime4K_T1", ("target1",), "tex1"),
    ("sample", "HLPass3", "Anime4K_PS3b", "Anime4K_T2", ("target2",), "tex2"),
    ("sample", "HLPass3", "Anime4K_PS3c", "Anime4K_T5", ("target3",), "tex5"),
    ("sample", "HLPass4", "Anime4K_PS4a", "Anime4K_T3", ("target1",), "tex3"),
    ("sample", "HLPass4", "Anime4K_PS4b", "Anime4K_T4", ("target2",), "tex4"),
    ("sample", "HLPass4", "Anime4K_PS4c", "Anime4K_T6", ("target3",), "tex6"),
    ("sample", "HLPass5", "Anime4K_PS5a", "Anime4K_T1", ("target1",), "tex1"),
    ("sample", "HLPass5", "Anime4K_PS5b", "Anime4K_T2", ("target2",), "tex2"),
    ("sample", "HLPass5", "Anime4K_PS5c", "Anime4K_T5", ("target3",), "tex5"),
    ("sample", "HLPass6", "Anime4K_PS6a", "Anime4K_T3", ("target1",), "tex3"),
    ("sample", "HLPass6", "Anime4K_PS6b", "Anime4K_T4", ("target2",), "tex4"),
    ("sample", "HLPass6", "Anime4K_PS6c", "Anime4K_T6", ("target3",), "tex6"),
    ("sample", "HLPass7", "Anime4K_PS7a", "Anime4K_T1", ("target1",), "tex1"),
    ("sample", "HLPass7", "Anime4K_PS7b", "Anime4K_T2", ("target2",), "tex2"),
    ("sample", "HLPass7", "Anime4K_PS7c", "Anime4K_T5", ("target3",), "tex5"),
    ("sample", "HLPass8", "Anime4K_PS8", None, None, None),
]
SPECS["VL"] = {"ntex": 6, "passes": VL_PASSES}
SPECS["Soft_VL"] = {"ntex": 6, "passes": VL_PASSES}

if VARIANT not in SPECS:
    raise SystemExit(f"unknown variant {VARIANT} (have: {', '.join(SPECS)})")
spec = SPECS[VARIANT]

parts = [build_header(VARIANT, spec["ntex"])]
tech_passes = []
out_counter = [0]

def _outvar():
    out_counter[0] += 1
    return f"Out{out_counter[0]}"

for entry in spec["passes"]:
    if entry[0] == "gather":
        _, hl, ps, tex, nch, arr, targets, out_tex = entry
        parts.append(gather_pass(ps, hl, tex, nch, arr, targets, _outvar()))
        tech_passes.append((ps, out_tex))
    else:
        _, hl, ps, out_tex, keep, out_src = entry
        parts.append(sample_pass(ps, hl, _outvar(), keep_targets=keep, out_src=out_src))
        tech_passes.append((ps, out_tex))

fx = "\n\n".join(parts)

tech = [f"technique Anime4K_Restore_{VARIANT}", "{"]
for i, (ps, rt) in enumerate(tech_passes, 1):
    tech.append(f"\tpass P{i}")
    tech.append("\t{")
    tech.append("\t\tVertexShader = Anime4K_VS;")
    tech.append(f"\t\tPixelShader = {ps};")
    if rt:
        tech.append(f"\t\tRenderTarget0 = {rt};")
    tech.append("\t}")
tech.append("}")
fx += "\n\n" + "\n".join(tech) + "\n"

open(OUT_PATH, "w").write(fx)
print(f"wrote {OUT_PATH} ({len(fx)} bytes)")
