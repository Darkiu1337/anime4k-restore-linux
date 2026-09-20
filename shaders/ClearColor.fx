// ClearColor — gentle saturation + contrast lift for washed-out / flat 3D art.
// Part of the "Clear" preset family (3D VN clarity, shaders/presets.json).
// Single technique, no depth, no uniforms (values are tuned constants, so it
// works in vkBasalt without extra config plumbing). Runs after `cas` in the
// Clear_Vivid chain so sharpening never shifts the grade.

texture ClearColor_Input : COLOR;

sampler SampInput
{
	Texture = ClearColor_Input;
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
	SRGBTexture = FALSE;
};

void ClearColor_VS(uint id : SV_VertexID, out float4 pos : SV_Position, out float2 uv : TEXCOORD0)
{
	uv = float2((id << 1) & 2, id & 2);
	pos = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

void ClearColor_PS(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out : SV_Target0)
{
	float3 c = tex2Dlod(SampInput, float4(uv, 0, 0)).rgb;

	// Luma-preserving saturation around perceptual luma.
	float luma = dot(c, float3(0.2126, 0.7152, 0.0722));
	float3 sat = lerp(float3(luma, luma, luma), c, 1.15);

	// Vibrance: push already-dull pixels more than vivid ones.
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float chroma = mx - mn;
	float vib = 1.0 + 0.18 * (1.0 - saturate(chroma * 2.0));
	float3 vivid = lerp(float3(luma, luma, luma), sat, vib);

	// Gentle contrast around mid-grey; saturate() keeps highlights/shadows sane.
	float3 graded = saturate((vivid - 0.5) * 1.04 + 0.5);

	Out = float4(graded, 1.0);
}

technique ClearColor
{
	pass P1
	{
		VertexShader = ClearColor_VS;
		PixelShader = ClearColor_PS;
	}
}
