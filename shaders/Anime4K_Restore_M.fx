// Anime4K Restore CNN (M) ported to ReShade FX.
// Source: Magpie Anime4K_Restore_M.hlsl <- bloc97/Anime4K glsl/Restore.
// 1:1 restoration (removes compression artifacts, blur, ringing). No scaling.
// Works in vkBasalt and gamescope --reshade-effect (single technique, no depth).
// NOTE: matrix/vector math expanded to dot() (ReShade FX lacks float3x4 etc).

texture Anime4K_Input : COLOR;


texture Anime4K_T1
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA16F;
	MipLevels = 1;
};

texture Anime4K_T2
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA16F;
	MipLevels = 1;
};

texture Anime4K_T3
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA16F;
	MipLevels = 1;
};

texture Anime4K_T4
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA16F;
	MipLevels = 1;
};

texture Anime4K_T5
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA16F;
	MipLevels = 1;
};

texture Anime4K_T6
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA16F;
	MipLevels = 1;
};

sampler SampInput
{
	Texture = Anime4K_Input;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
	SRGBTexture = FALSE;
};

sampler SampT1
{
	Texture = Anime4K_T1;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
	SRGBTexture = FALSE;
};

sampler SampT2
{
	Texture = Anime4K_T2;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
	SRGBTexture = FALSE;
};

sampler SampT3
{
	Texture = Anime4K_T3;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
	SRGBTexture = FALSE;
};

sampler SampT4
{
	Texture = Anime4K_T4;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
	SRGBTexture = FALSE;
};

sampler SampT5
{
	Texture = Anime4K_T5;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
	SRGBTexture = FALSE;
};

sampler SampT6
{
	Texture = Anime4K_T6;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
	SRGBTexture = FALSE;
};

void Anime4K_VS(uint id : SV_VertexID, out float4 pos : SV_Position, out float2 uv : TEXCOORD0)
{
	uv = float2((id << 1) & 2, id & 2);
	pos = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}



void Anime4K_PS1(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out1 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float3 src00, src01, src02, src03, src10, src11, src12, src13, src20, src21, src22, src23, src30, src31, src32, src33;
	float2 tpos_0_0 = (float2(pix) + float2(0, 0)) * rcp;
	float4 g0_0_x = tex2Dgather(SampInput, tpos_0_0, 0);
	float4 g0_0_y = tex2Dgather(SampInput, tpos_0_0, 1);
	float4 g0_0_z = tex2Dgather(SampInput, tpos_0_0, 2);
	src00 = float3(g0_0_x.w, g0_0_y.w, g0_0_z.w);
	src01 = float3(g0_0_x.x, g0_0_y.x, g0_0_z.x);
	src10 = float3(g0_0_x.z, g0_0_y.z, g0_0_z.z);
	src11 = float3(g0_0_x.y, g0_0_y.y, g0_0_z.y);
	float2 tpos_0_2 = (float2(pix) + float2(0, 2)) * rcp;
	float4 g0_2_x = tex2Dgather(SampInput, tpos_0_2, 0);
	float4 g0_2_y = tex2Dgather(SampInput, tpos_0_2, 1);
	float4 g0_2_z = tex2Dgather(SampInput, tpos_0_2, 2);
	src02 = float3(g0_2_x.w, g0_2_y.w, g0_2_z.w);
	src03 = float3(g0_2_x.x, g0_2_y.x, g0_2_z.x);
	src12 = float3(g0_2_x.z, g0_2_y.z, g0_2_z.z);
	src13 = float3(g0_2_x.y, g0_2_y.y, g0_2_z.y);
	float2 tpos_2_0 = (float2(pix) + float2(2, 0)) * rcp;
	float4 g2_0_x = tex2Dgather(SampInput, tpos_2_0, 0);
	float4 g2_0_y = tex2Dgather(SampInput, tpos_2_0, 1);
	float4 g2_0_z = tex2Dgather(SampInput, tpos_2_0, 2);
	src20 = float3(g2_0_x.w, g2_0_y.w, g2_0_z.w);
	src21 = float3(g2_0_x.x, g2_0_y.x, g2_0_z.x);
	src30 = float3(g2_0_x.z, g2_0_y.z, g2_0_z.z);
	src31 = float3(g2_0_x.y, g2_0_y.y, g2_0_z.y);
	float2 tpos_2_2 = (float2(pix) + float2(2, 2)) * rcp;
	float4 g2_2_x = tex2Dgather(SampInput, tpos_2_2, 0);
	float4 g2_2_y = tex2Dgather(SampInput, tpos_2_2, 1);
	float4 g2_2_z = tex2Dgather(SampInput, tpos_2_2, 2);
	src22 = float3(g2_2_x.w, g2_2_y.w, g2_2_z.w);
	src23 = float3(g2_2_x.x, g2_2_y.x, g2_2_z.x);
	src32 = float3(g2_2_x.z, g2_2_y.z, g2_2_z.z);
	src33 = float3(g2_2_x.y, g2_2_y.y, g2_2_z.y);
	float4 result = float4( -0.061233472, 0.39222646, 0.029704979, 0.02586828 );
	result = float4(dot((src00), float3(-0.09991986, -0.3437488, 0.08607224)), dot((src00), float3(0.13782342, 0.05450952, 0.044988394)), dot((src00), float3(-0.031251684, 0.34347802, 0.137179)), dot((src00), float3(-0.06356843, 0.46335372, 0.17976908))) + (result);
	result = float4(dot((src01), float3(-0.024212424, -0.13254678, -0.06375679)), dot((src01), float3(-0.09278509, 0.113105185, 0.009184115)), dot((src01), float3(-0.00040907756, 0.005667946, 0.115518734)), dot((src01), float3(0.34552294, -0.00036919137, -0.115506776))) + (result);
	result = float4(dot((src02), float3(-0.14101827, -0.44348842, -0.15880394)), dot((src02), float3(0.023523493, -0.08818877, -0.013732858)), dot((src02), float3(0.044094566, -0.4026149, -0.020751135)), dot((src02), float3(-0.019271746, -0.21995795, 0.012719151))) + (result);
	result = float4(dot((src10), float3(0.013001821, 0.24760444, -0.058132876)), dot((src10), float3(-0.34503505, -0.016173402, 0.016784398)), dot((src10), float3(0.39219138, 0.10154511, -0.05808539)), dot((src10), float3(0.18792126, 0.15453082, -0.11039915))) + (result);
	result = float4(dot((src11), float3(0.37024534, 0.19555596, 0.21228147)), dot((src11), float3(0.041440863, 0.20855539, -0.0295346)), dot((src11), float3(-0.3374568, -0.27974075, -0.56700057)), dot((src11), float3(-0.44994286, -0.5372628, 0.030042822))) + (result);
	result = float4(dot((src12), float3(-0.12940632, -0.13704006, -0.06166251)), dot((src12), float3(0.057526, -0.047685407, -0.01883519)), dot((src12), float3(0.090682045, 0.44615674, 0.2032237)), dot((src12), float3(-0.06985033, -0.48056605, -0.11328760))) + (result);
	result = float4(dot((src20), float3(0.010856669, -0.03967303, 0.015120559)), dot((src20), float3(-0.35820737, 0.038705572, -0.15314877)), dot((src20), float3(0.16757219, 0.32652855, 0.23442009)), dot((src20), float3(0.082619876, -0.012030017, 0.09767922))) + (result);
	result = float4(dot((src21), float3(-0.046272673, 0.58619463, -0.17025311)), dot((src21), float3(-0.17752305, -0.060903464, 0.05136993)), dot((src21), float3(0.082018286, -0.022793597, 0.029383298)), dot((src21), float3(-0.2512824, 0.077803515, -0.15475409))) + (result);
	result = float4(dot((src22), float3(-0.11212024, -0.11176219, 0.13326839)), dot((src22), float3(0.13378005, -0.048429377, 0.0430627)), dot((src22), float3(-0.2027488, -0.08396386, 0.051362377)), dot((src22), float3(0.08056421, 0.10507829, 0.06482755))) + (result);
	Out1 = result;
}

void Anime4K_PS2(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out2 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float4 src00, src01, src02, src03, src10, src11, src12, src13, src20, src21, src22, src23, src30, src31, src32, src33;
	float2 tpos_0_0 = (float2(pix) + float2(0, 0)) * rcp;
	float4 g0_0_x = tex2Dgather(SampT1, tpos_0_0, 0);
	float4 g0_0_y = tex2Dgather(SampT1, tpos_0_0, 1);
	float4 g0_0_z = tex2Dgather(SampT1, tpos_0_0, 2);
	float4 g0_0_w = tex2Dgather(SampT1, tpos_0_0, 3);
	src00 = float4(g0_0_x.w, g0_0_y.w, g0_0_z.w, g0_0_w.w);
	src01 = float4(g0_0_x.x, g0_0_y.x, g0_0_z.x, g0_0_w.x);
	src10 = float4(g0_0_x.z, g0_0_y.z, g0_0_z.z, g0_0_w.z);
	src11 = float4(g0_0_x.y, g0_0_y.y, g0_0_z.y, g0_0_w.y);
	float2 tpos_0_2 = (float2(pix) + float2(0, 2)) * rcp;
	float4 g0_2_x = tex2Dgather(SampT1, tpos_0_2, 0);
	float4 g0_2_y = tex2Dgather(SampT1, tpos_0_2, 1);
	float4 g0_2_z = tex2Dgather(SampT1, tpos_0_2, 2);
	float4 g0_2_w = tex2Dgather(SampT1, tpos_0_2, 3);
	src02 = float4(g0_2_x.w, g0_2_y.w, g0_2_z.w, g0_2_w.w);
	src03 = float4(g0_2_x.x, g0_2_y.x, g0_2_z.x, g0_2_w.x);
	src12 = float4(g0_2_x.z, g0_2_y.z, g0_2_z.z, g0_2_w.z);
	src13 = float4(g0_2_x.y, g0_2_y.y, g0_2_z.y, g0_2_w.y);
	float2 tpos_2_0 = (float2(pix) + float2(2, 0)) * rcp;
	float4 g2_0_x = tex2Dgather(SampT1, tpos_2_0, 0);
	float4 g2_0_y = tex2Dgather(SampT1, tpos_2_0, 1);
	float4 g2_0_z = tex2Dgather(SampT1, tpos_2_0, 2);
	float4 g2_0_w = tex2Dgather(SampT1, tpos_2_0, 3);
	src20 = float4(g2_0_x.w, g2_0_y.w, g2_0_z.w, g2_0_w.w);
	src21 = float4(g2_0_x.x, g2_0_y.x, g2_0_z.x, g2_0_w.x);
	src30 = float4(g2_0_x.z, g2_0_y.z, g2_0_z.z, g2_0_w.z);
	src31 = float4(g2_0_x.y, g2_0_y.y, g2_0_z.y, g2_0_w.y);
	float2 tpos_2_2 = (float2(pix) + float2(2, 2)) * rcp;
	float4 g2_2_x = tex2Dgather(SampT1, tpos_2_2, 0);
	float4 g2_2_y = tex2Dgather(SampT1, tpos_2_2, 1);
	float4 g2_2_z = tex2Dgather(SampT1, tpos_2_2, 2);
	float4 g2_2_w = tex2Dgather(SampT1, tpos_2_2, 3);
	src22 = float4(g2_2_x.w, g2_2_y.w, g2_2_z.w, g2_2_w.w);
	src23 = float4(g2_2_x.x, g2_2_y.x, g2_2_z.x, g2_2_w.x);
	src32 = float4(g2_2_x.z, g2_2_y.z, g2_2_z.z, g2_2_w.z);
	src33 = float4(g2_2_x.y, g2_2_y.y, g2_2_z.y, g2_2_w.y);
	float4 result = float4( -0.018297346, -0.080951825, -0.062163066, -0.08050014 );
	result = float4(dot((max(src00, 0)), float4(-0.16410656, 0.105412476, 0.12558138, -0.14220351)), dot((max(src00, 0)), float4(-0.40521824, -0.060401272, -0.020861467, 0.20736893)), dot((max(src00, 0)), float4(0.13121907, -0.043063477, 0.030370515, 0.003321564)), dot((max(src00, 0)), float4(-0.02314597, -0.13933973, 0.13178016, -0.29241714))) + (result);
	result = float4(dot((max(src01, 0)), float4(0.18517321, 0.025527012, 0.12750523, 0.0839921)), dot((max(src01, 0)), float4(0.29162985, -0.067319244, -0.091435954, 0.10186618)), dot((max(src01, 0)), float4(-0.26783395, 0.055004176, 0.13818842, -0.17237376)), dot((max(src01, 0)), float4(0.039760686, 0.048916563, 0.36704224, 0.13282418))) + (result);
	result = float4(dot((max(src02, 0)), float4(-0.1657887, -0.12756164, 0.15870757, 0.07099966)), dot((max(src02, 0)), float4(0.0131325135, -0.08437298, -0.013529402, -0.024063632)), dot((max(src02, 0)), float4(-0.17222486, -0.29052997, -0.0581753, 0.31834844)), dot((max(src02, 0)), float4(0.091398895, 0.3269337, 0.11802371, -0.11183859))) + (result);
	result = float4(dot((max(src10, 0)), float4(0.46036887, 0.10555414, 0.028316498, 0.04953974)), dot((max(src10, 0)), float4(-0.07654623, -0.117430426, 0.13684341, -0.31342217)), dot((max(src10, 0)), float4(0.22923063, 0.12406777, 0.009664087, -0.6103131)), dot((max(src10, 0)), float4(0.17463821, -0.011399492, 0.2022659, -0.13605757))) + (result);
	result = float4(dot((max(src11, 0)), float4(0.03406955, -0.029321073, 0.11464085, -0.5609916)), dot((max(src11, 0)), float4(-0.39819366, 0.46619493, -0.10931452, 0.31826234)), dot((max(src11, 0)), float4(0.61176, 0.36700186, -0.09154022, -0.011012659)), dot((max(src11, 0)), float4(-0.46809456, 0.02288561, 0.07334147, -0.46719545))) + (result);
	result = float4(dot((max(src12, 0)), float4(-0.056855045, -0.06816116, 0.09954046, 0.3825241)), dot((max(src12, 0)), float4(0.27037027, -0.22986612, -0.05374176, -0.1609887)), dot((max(src12, 0)), float4(-0.09269696, 0.08693167, 0.0071916827, 0.055204768)), dot((max(src12, 0)), float4(-0.563572, -0.16246101, -0.1788692, 0.10213068))) + (result);
	result = float4(dot((max(src20, 0)), float4(0.0646626, -0.23337309, -0.13473304, -0.04264752)), dot((max(src20, 0)), float4(0.102358796, 0.12633002, 0.053790465, -0.029740738)), dot((max(src20, 0)), float4(-0.45055822, -0.19299199, -0.10061193, -0.07865285)), dot((max(src20, 0)), float4(0.20557903, -0.15085731, -0.13393497, 0.20883279))) + (result);
	result = float4(dot((max(src21, 0)), float4(0.010471527, 0.23226471, 0.013839963, 0.33772305)), dot((max(src21, 0)), float4(-0.033218473, -0.059343327, 0.15930325, 0.40261495)), dot((max(src21, 0)), float4(-0.46157447, -0.1439596, 0.043742355, -0.08351293)), dot((max(src21, 0)), float4(0.004866583, 0.13619648, 0.17467323, 0.18129359))) + (result);
	result = float4(dot((max(src22, 0)), float4(-0.12493434, -0.037142616, 0.0071619414, 0.14917047)), dot((max(src22, 0)), float4(-0.1875134, 0.1667002, 0.0034872112, -0.16310586)), dot((max(src22, 0)), float4(-0.074943796, 0.16665547, 0.120318964, 0.07231737)), dot((max(src22, 0)), float4(-0.0031701606, -0.011248127, -0.09625579, 0.30447328))) + (result);
	result = float4(dot((max(-src00, 0)), float4(0.093798615, 0.118534856, -0.34137097, 0.16220862)), dot((max(-src00, 0)), float4(0.17074613, 0.027508778, 0.32000312, 0.108993016)), dot((max(-src00, 0)), float4(-0.08780678, -0.2778478, -0.22027159, 0.14070526)), dot((max(-src00, 0)), float4(-0.012520207, -0.19509242, 0.337515, 0.12784284))) + (result);
	result = float4(dot((max(-src01, 0)), float4(-0.14325632, 0.11821083, -0.06766648, 0.1318925)), dot((max(-src01, 0)), float4(-0.1467453, -0.012266484, 0.58165014, -0.04346277)), dot((max(-src01, 0)), float4(-0.27502358, -0.2100548, -0.2512279, 0.15454485)), dot((max(-src01, 0)), float4(0.09370837, 0.4707502, -0.33783755, 0.044500057))) + (result);
	result = float4(dot((max(-src02, 0)), float4(-0.05683207, -0.50763863, 0.022709515, 0.01404485)), dot((max(-src02, 0)), float4(0.0051946463, 0.007308442, 0.294523, 0.031282708)), dot((max(-src02, 0)), float4(-0.108000524, 0.8542404, -0.3822472, -0.26756814)), dot((max(-src02, 0)), float4(0.10133204, 0.28387356, 0.66166407, -0.123147786))) + (result);
	result = float4(dot((max(-src10, 0)), float4(-0.36455178, -0.15802494, 0.130428, 0.15804817)), dot((max(-src10, 0)), float4(0.3470555, -0.0019141496, 0.03954273, 0.12551713)), dot((max(-src10, 0)), float4(-0.045303088, -0.25939587, -0.17985536, 0.28371975)), dot((max(-src10, 0)), float4(-0.03170764, -0.23875342, 0.105145946, -0.085748516))) + (result);
	result = float4(dot((max(-src11, 0)), float4(0.0060625463, -0.09584515, 0.12942013, 0.10499644)), dot((max(-src11, 0)), float4(0.2443924, -0.012805372, 0.41785547, -0.20566013)), dot((max(-src11, 0)), float4(-0.017692259, -0.13942227, 0.046071563, -0.031321276)), dot((max(-src11, 0)), float4(-0.20214005, 0.16143198, 0.7030026, 0.27830327))) + (result);
	result = float4(dot((max(-src12, 0)), float4(-0.081274964, 0.012910989, -0.22015952, -0.31645304)), dot((max(-src12, 0)), float4(-0.14562319, 0.024201397, -0.44160756, 0.15469243)), dot((max(-src12, 0)), float4(0.27200526, 0.04816258, -0.056035373, 0.053187452)), dot((max(-src12, 0)), float4(-0.20491314, 0.21297328, 0.33824417, -0.20989445))) + (result);
	result = float4(dot((max(-src20, 0)), float4(-0.046550367, 0.23520172, -0.07058717, -0.055425353)), dot((max(-src20, 0)), float4(0.033185404, -0.05909214, -0.11759937, -0.12506317)), dot((max(-src20, 0)), float4(0.33337244, 0.0861368, -0.18594047, 0.15729053)), dot((max(-src20, 0)), float4(0.12853645, 0.10706329, 0.080006264, -0.0915004))) + (result);
	result = float4(dot((max(-src21, 0)), float4(0.042516407, -0.0655417, 0.12855926, -0.2446715)), dot((max(-src21, 0)), float4(0.14844789, -0.057256397, 0.014219275, -0.4008074)), dot((max(-src21, 0)), float4(0.16533111, 0.076713726, 0.051761385, 0.19603717)), dot((max(-src21, 0)), float4(0.13502933, -0.23448966, 0.053433083, -0.1796951))) + (result);
	result = float4(dot((max(-src22, 0)), float4(0.14777803, 0.19210646, -0.18074386, -0.3837698)), dot((max(-src22, 0)), float4(0.15524907, -0.2144364, -0.2163903, -0.0022661497)), dot((max(-src22, 0)), float4(0.043158617, -0.47020787, 0.0030754965, -0.37276733)), dot((max(-src22, 0)), float4(-0.06996876, -0.4207906, 0.36799973, -0.28934997))) + (result);
	Out2 = result;
}

void Anime4K_PS3(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out3 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float4 src00, src01, src02, src03, src10, src11, src12, src13, src20, src21, src22, src23, src30, src31, src32, src33;
	float2 tpos_0_0 = (float2(pix) + float2(0, 0)) * rcp;
	float4 g0_0_x = tex2Dgather(SampT2, tpos_0_0, 0);
	float4 g0_0_y = tex2Dgather(SampT2, tpos_0_0, 1);
	float4 g0_0_z = tex2Dgather(SampT2, tpos_0_0, 2);
	float4 g0_0_w = tex2Dgather(SampT2, tpos_0_0, 3);
	src00 = float4(g0_0_x.w, g0_0_y.w, g0_0_z.w, g0_0_w.w);
	src01 = float4(g0_0_x.x, g0_0_y.x, g0_0_z.x, g0_0_w.x);
	src10 = float4(g0_0_x.z, g0_0_y.z, g0_0_z.z, g0_0_w.z);
	src11 = float4(g0_0_x.y, g0_0_y.y, g0_0_z.y, g0_0_w.y);
	float2 tpos_0_2 = (float2(pix) + float2(0, 2)) * rcp;
	float4 g0_2_x = tex2Dgather(SampT2, tpos_0_2, 0);
	float4 g0_2_y = tex2Dgather(SampT2, tpos_0_2, 1);
	float4 g0_2_z = tex2Dgather(SampT2, tpos_0_2, 2);
	float4 g0_2_w = tex2Dgather(SampT2, tpos_0_2, 3);
	src02 = float4(g0_2_x.w, g0_2_y.w, g0_2_z.w, g0_2_w.w);
	src03 = float4(g0_2_x.x, g0_2_y.x, g0_2_z.x, g0_2_w.x);
	src12 = float4(g0_2_x.z, g0_2_y.z, g0_2_z.z, g0_2_w.z);
	src13 = float4(g0_2_x.y, g0_2_y.y, g0_2_z.y, g0_2_w.y);
	float2 tpos_2_0 = (float2(pix) + float2(2, 0)) * rcp;
	float4 g2_0_x = tex2Dgather(SampT2, tpos_2_0, 0);
	float4 g2_0_y = tex2Dgather(SampT2, tpos_2_0, 1);
	float4 g2_0_z = tex2Dgather(SampT2, tpos_2_0, 2);
	float4 g2_0_w = tex2Dgather(SampT2, tpos_2_0, 3);
	src20 = float4(g2_0_x.w, g2_0_y.w, g2_0_z.w, g2_0_w.w);
	src21 = float4(g2_0_x.x, g2_0_y.x, g2_0_z.x, g2_0_w.x);
	src30 = float4(g2_0_x.z, g2_0_y.z, g2_0_z.z, g2_0_w.z);
	src31 = float4(g2_0_x.y, g2_0_y.y, g2_0_z.y, g2_0_w.y);
	float2 tpos_2_2 = (float2(pix) + float2(2, 2)) * rcp;
	float4 g2_2_x = tex2Dgather(SampT2, tpos_2_2, 0);
	float4 g2_2_y = tex2Dgather(SampT2, tpos_2_2, 1);
	float4 g2_2_z = tex2Dgather(SampT2, tpos_2_2, 2);
	float4 g2_2_w = tex2Dgather(SampT2, tpos_2_2, 3);
	src22 = float4(g2_2_x.w, g2_2_y.w, g2_2_z.w, g2_2_w.w);
	src23 = float4(g2_2_x.x, g2_2_y.x, g2_2_z.x, g2_2_w.x);
	src32 = float4(g2_2_x.z, g2_2_y.z, g2_2_z.z, g2_2_w.z);
	src33 = float4(g2_2_x.y, g2_2_y.y, g2_2_z.y, g2_2_w.y);
	float4 result = float4( -0.008952847, -0.0058945753, -0.08097229, 0.020968592 );
	result = float4(dot((max(src00, 0)), float4(0.31543177, 0.003622504, -0.052964583, 0.13107763)), dot((max(src00, 0)), float4(0.23095237, 0.17948842, -0.15551159, 0.11369179)), dot((max(src00, 0)), float4(-0.06692611, -0.14627707, 0.05644786, -0.09452995)), dot((max(src00, 0)), float4(-0.5867763, 0.1745016, -0.012665164, -0.11973403))) + (result);
	result = float4(dot((max(src01, 0)), float4(-0.2694661, -0.25511482, -0.022617863, -0.013346653)), dot((max(src01, 0)), float4(-0.115382135, -0.13922207, 0.20333402, -0.099095374)), dot((max(src01, 0)), float4(0.3073268, 0.36758214, -0.11125889, -0.25100616)), dot((max(src01, 0)), float4(-0.067228466, -0.18821828, 0.3552245, 0.35521755))) + (result);
	result = float4(dot((max(src02, 0)), float4(0.011012409, -0.23184675, -0.16461405, -0.19033363)), dot((max(src02, 0)), float4(-0.13675085, 0.18012202, 0.038177088, 0.07469178)), dot((max(src02, 0)), float4(0.25642, 0.57654136, 0.1234096, -0.017948546)), dot((max(src02, 0)), float4(-0.34851208, 0.103173524, 0.013202029, 0.15287702))) + (result);
	result = float4(dot((max(src10, 0)), float4(-0.05340533, -0.12181174, -0.11519453, 0.022218632)), dot((max(src10, 0)), float4(0.23797482, -0.23363493, 0.13842066, 0.031238724)), dot((max(src10, 0)), float4(0.20351392, -0.20696607, -0.10687832, 0.2685182)), dot((max(src10, 0)), float4(-0.05333351, 0.109941036, 0.29040006, 0.15300068))) + (result);
	result = float4(dot((max(src11, 0)), float4(0.22985318, -0.11690287, -0.06335474, -0.16776285)), dot((max(src11, 0)), float4(-0.3103802, -0.1947488, -0.007870727, -0.006570437)), dot((max(src11, 0)), float4(-0.22916415, 0.118020535, 0.076106325, -0.29589584)), dot((max(src11, 0)), float4(0.25238806, 0.07814263, 0.094677486, 0.41413507))) + (result);
	result = float4(dot((max(src12, 0)), float4(0.43607962, -0.091190875, 0.12356344, -0.23490307)), dot((max(src12, 0)), float4(-0.36456433, 0.13035081, -0.008616177, 0.3013123)), dot((max(src12, 0)), float4(-0.123776875, 0.28627968, 0.09599816, 0.14153156)), dot((max(src12, 0)), float4(-0.16634953, 0.27249968, -0.006144557, 0.21837278))) + (result);
	result = float4(dot((max(src20, 0)), float4(0.060364585, -0.089910224, 0.036934495, 0.13489649)), dot((max(src20, 0)), float4(0.37860224, -0.06817697, -0.07826616, 0.06237663)), dot((max(src20, 0)), float4(0.039182413, -0.2684275, 0.06559976, 0.126376)), dot((max(src20, 0)), float4(-0.22805426, -0.12528503, -0.08253646, 0.21194184))) + (result);
	result = float4(dot((max(src21, 0)), float4(-0.12534817, -0.006957577, 0.23081483, -0.2904096)), dot((max(src21, 0)), float4(0.21225189, -0.025105853, 0.1802756, -0.25292823)), dot((max(src21, 0)), float4(-0.27818045, 0.12100924, -0.18995638, -0.21834068)), dot((max(src21, 0)), float4(-0.3070443, -0.06916452, 0.16603014, 0.13719653))) + (result);
	result = float4(dot((max(src22, 0)), float4(0.017209655, 0.10467716, 0.2100472, -0.06983842)), dot((max(src22, 0)), float4(0.10757137, -0.2184891, -0.25768545, -0.103854865)), dot((max(src22, 0)), float4(0.21414296, 0.100061476, -0.22329919, -0.051384352)), dot((max(src22, 0)), float4(-0.30885983, -0.1527528, -0.29153427, 0.14629121))) + (result);
	result = float4(dot((max(-src00, 0)), float4(0.0059623295, 0.09783085, -0.033508282, 0.10504043)), dot((max(-src00, 0)), float4(-0.26060802, -0.15865178, 0.17480391, -0.06105686)), dot((max(-src00, 0)), float4(0.32115817, 0.1473021, -0.091310136, 0.013493489)), dot((max(-src00, 0)), float4(0.021025505, -0.24977303, 0.09870876, -0.11278855))) + (result);
	result = float4(dot((max(-src01, 0)), float4(0.14875248, 0.101288855, -0.037392337, -0.059375558)), dot((max(-src01, 0)), float4(-0.14859414, -0.1113682, 0.08539691, 0.027663672)), dot((max(-src01, 0)), float4(0.19377062, -0.48944646, 0.1751306, 0.051804014)), dot((max(-src01, 0)), float4(-0.17456068, 0.1018565, -0.15428723, -0.049813222))) + (result);
	result = float4(dot((max(-src02, 0)), float4(0.118846565, -0.11662527, -0.051991668, 0.057021596)), dot((max(-src02, 0)), float4(-0.19869871, -0.43818352, 0.21008292, 0.09460527)), dot((max(-src02, 0)), float4(-0.037388258, -0.093285345, 0.10792365, 0.0016551288)), dot((max(-src02, 0)), float4(0.08456728, 0.038507205, 0.2020924, -0.0015957063))) + (result);
	result = float4(dot((max(-src10, 0)), float4(0.11062174, -0.050545212, 0.028986752, 0.034687653)), dot((max(-src10, 0)), float4(-0.2639232, 0.30989558, 0.037429404, -0.09599135)), dot((max(-src10, 0)), float4(-0.060295466, 0.30906132, 0.20855664, -0.06250494)), dot((max(-src10, 0)), float4(-0.3217331, 0.030323273, -0.19848943, -0.13215867))) + (result);
	result = float4(dot((max(-src11, 0)), float4(-0.010391146, 0.0075931503, -0.15452717, 0.0067911847)), dot((max(-src11, 0)), float4(0.07657845, 0.42632654, -0.14613411, 0.057501152)), dot((max(-src11, 0)), float4(0.44491258, 0.47022533, -0.45231065, 0.09876979)), dot((max(-src11, 0)), float4(0.0435906, 0.34737435, 0.12094409, 0.044946447))) + (result);
	result = float4(dot((max(-src12, 0)), float4(-0.15607435, -0.15282455, -0.055801593, 0.12300962)), dot((max(-src12, 0)), float4(0.2293058, 0.26437718, -0.016778728, -0.13235827)), dot((max(-src12, 0)), float4(-0.09520331, -0.1685477, -0.34478986, -0.13987203)), dot((max(-src12, 0)), float4(0.012836732, -0.13211122, -0.23228309, -0.16550972))) + (result);
	result = float4(dot((max(-src20, 0)), float4(0.13161735, 0.1514885, 0.090661936, -0.32651708)), dot((max(-src20, 0)), float4(-0.09039346, 0.20977421, 0.15288061, 0.18825398)), dot((max(-src20, 0)), float4(-0.033475474, 0.031431954, -0.03316583, -0.15777239)), dot((max(-src20, 0)), float4(-0.23686698, -0.0049226107, 0.09646573, 0.17572704))) + (result);
	result = float4(dot((max(-src21, 0)), float4(0.112157226, -0.14686783, -0.31530112, 0.18053482)), dot((max(-src21, 0)), float4(-0.08712878, 0.28682423, -0.2700583, 0.16653341)), dot((max(-src21, 0)), float4(0.23453182, -0.086443506, -0.06028952, 0.25215197)), dot((max(-src21, 0)), float4(0.1043877, 0.059457052, -0.070416875, 0.061915852))) + (result);
	result = float4(dot((max(-src22, 0)), float4(-0.20122242, -0.35436687, 0.10425242, 0.01630275)), dot((max(-src22, 0)), float4(0.076313145, 0.3762327, -0.17087407, 0.24247427)), dot((max(-src22, 0)), float4(-0.0988483, -0.07809558, 0.030301496, -0.006474477)), dot((max(-src22, 0)), float4(0.094337784, 0.3055848, -0.13911743, 0.03842641))) + (result);
	Out3 = result;
}

void Anime4K_PS4(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out4 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float4 src00, src01, src02, src03, src10, src11, src12, src13, src20, src21, src22, src23, src30, src31, src32, src33;
	float2 tpos_0_0 = (float2(pix) + float2(0, 0)) * rcp;
	float4 g0_0_x = tex2Dgather(SampT3, tpos_0_0, 0);
	float4 g0_0_y = tex2Dgather(SampT3, tpos_0_0, 1);
	float4 g0_0_z = tex2Dgather(SampT3, tpos_0_0, 2);
	float4 g0_0_w = tex2Dgather(SampT3, tpos_0_0, 3);
	src00 = float4(g0_0_x.w, g0_0_y.w, g0_0_z.w, g0_0_w.w);
	src01 = float4(g0_0_x.x, g0_0_y.x, g0_0_z.x, g0_0_w.x);
	src10 = float4(g0_0_x.z, g0_0_y.z, g0_0_z.z, g0_0_w.z);
	src11 = float4(g0_0_x.y, g0_0_y.y, g0_0_z.y, g0_0_w.y);
	float2 tpos_0_2 = (float2(pix) + float2(0, 2)) * rcp;
	float4 g0_2_x = tex2Dgather(SampT3, tpos_0_2, 0);
	float4 g0_2_y = tex2Dgather(SampT3, tpos_0_2, 1);
	float4 g0_2_z = tex2Dgather(SampT3, tpos_0_2, 2);
	float4 g0_2_w = tex2Dgather(SampT3, tpos_0_2, 3);
	src02 = float4(g0_2_x.w, g0_2_y.w, g0_2_z.w, g0_2_w.w);
	src03 = float4(g0_2_x.x, g0_2_y.x, g0_2_z.x, g0_2_w.x);
	src12 = float4(g0_2_x.z, g0_2_y.z, g0_2_z.z, g0_2_w.z);
	src13 = float4(g0_2_x.y, g0_2_y.y, g0_2_z.y, g0_2_w.y);
	float2 tpos_2_0 = (float2(pix) + float2(2, 0)) * rcp;
	float4 g2_0_x = tex2Dgather(SampT3, tpos_2_0, 0);
	float4 g2_0_y = tex2Dgather(SampT3, tpos_2_0, 1);
	float4 g2_0_z = tex2Dgather(SampT3, tpos_2_0, 2);
	float4 g2_0_w = tex2Dgather(SampT3, tpos_2_0, 3);
	src20 = float4(g2_0_x.w, g2_0_y.w, g2_0_z.w, g2_0_w.w);
	src21 = float4(g2_0_x.x, g2_0_y.x, g2_0_z.x, g2_0_w.x);
	src30 = float4(g2_0_x.z, g2_0_y.z, g2_0_z.z, g2_0_w.z);
	src31 = float4(g2_0_x.y, g2_0_y.y, g2_0_z.y, g2_0_w.y);
	float2 tpos_2_2 = (float2(pix) + float2(2, 2)) * rcp;
	float4 g2_2_x = tex2Dgather(SampT3, tpos_2_2, 0);
	float4 g2_2_y = tex2Dgather(SampT3, tpos_2_2, 1);
	float4 g2_2_z = tex2Dgather(SampT3, tpos_2_2, 2);
	float4 g2_2_w = tex2Dgather(SampT3, tpos_2_2, 3);
	src22 = float4(g2_2_x.w, g2_2_y.w, g2_2_z.w, g2_2_w.w);
	src23 = float4(g2_2_x.x, g2_2_y.x, g2_2_z.x, g2_2_w.x);
	src32 = float4(g2_2_x.z, g2_2_y.z, g2_2_z.z, g2_2_w.z);
	src33 = float4(g2_2_x.y, g2_2_y.y, g2_2_z.y, g2_2_w.y);
	float4 result = float4( -0.059377354, -0.02055341, 0.07234869, -0.015452986 );
	result = float4(dot((max(src00, 0)), float4(-0.2237721, 0.015353088, -0.07456269, -0.14183366)), dot((max(src00, 0)), float4(-0.0064096362, 0.23983319, 0.093151815, 0.06401045)), dot((max(src00, 0)), float4(-0.31808427, 0.14967978, -0.14331086, -0.22044073)), dot((max(src00, 0)), float4(0.73477733, -0.34920225, -0.24586205, 0.29932275))) + (result);
	result = float4(dot((max(src01, 0)), float4(-0.07968509, 0.4095855, 0.2981273, -0.065247655)), dot((max(src01, 0)), float4(-0.3349146, -0.17120704, 0.2212369, -0.15255849)), dot((max(src01, 0)), float4(0.16529128, 0.17425705, 0.10392389, 0.13094437)), dot((max(src01, 0)), float4(0.08443499, 0.15298946, -0.28775454, 0.18685219))) + (result);
	result = float4(dot((max(src02, 0)), float4(0.015706737, -0.15876788, -0.023320962, -0.1888095)), dot((max(src02, 0)), float4(-0.17755036, -0.38466996, -0.3145249, -0.046370104)), dot((max(src02, 0)), float4(0.2622526, -0.33700845, -0.21223734, 0.09000896)), dot((max(src02, 0)), float4(0.112057306, -0.031711742, -0.1314596, -0.0046378844))) + (result);
	result = float4(dot((max(src10, 0)), float4(-0.31127506, -0.029851055, 0.18019931, -0.013932474)), dot((max(src10, 0)), float4(0.31304324, 0.05801377, 0.14415511, -0.046454947)), dot((max(src10, 0)), float4(-0.03965752, 0.00040150844, -0.09845236, -0.3403935)), dot((max(src10, 0)), float4(0.03649018, -0.04422069, 0.21895434, -0.006705289))) + (result);
	result = float4(dot((max(src11, 0)), float4(-0.34878647, 0.20644619, 0.24449423, -0.26914698)), dot((max(src11, 0)), float4(-0.5129283, 0.08732273, 0.44103387, -0.21309987)), dot((max(src11, 0)), float4(0.060250953, -0.24118888, 0.22455928, 0.08386486)), dot((max(src11, 0)), float4(-0.16354133, 0.24455065, 0.25738943, 0.021484816))) + (result);
	result = float4(dot((max(src12, 0)), float4(-0.057454903, 0.03331408, 0.2432641, -0.19335061)), dot((max(src12, 0)), float4(-0.4121922, 0.05044008, 0.076906696, 0.09217451)), dot((max(src12, 0)), float4(0.022661546, 0.04324371, -0.20858039, 0.1968369)), dot((max(src12, 0)), float4(0.37178272, 0.20727943, 0.012439015, -0.19435833))) + (result);
	result = float4(dot((max(src20, 0)), float4(-0.16960496, -0.011531225, 0.0086012175, -0.29120612)), dot((max(src20, 0)), float4(0.24616167, -0.11312143, -0.3564491, 0.23756824)), dot((max(src20, 0)), float4(0.37977478, -0.18141079, -0.12639481, 0.18035695)), dot((max(src20, 0)), float4(0.14324574, -0.23843932, 0.009799298, -0.087133996))) + (result);
	result = float4(dot((max(src21, 0)), float4(-0.10081239, 0.008997759, -0.11627765, 0.05086147)), dot((max(src21, 0)), float4(0.29191494, 0.104756236, 0.023693223, 0.18498175)), dot((max(src21, 0)), float4(0.10434693, 0.039641086, -0.30801758, 0.15595439)), dot((max(src21, 0)), float4(0.08970636, 0.02323888, -0.120208986, -0.09877306))) + (result);
	result = float4(dot((max(src22, 0)), float4(0.101321675, -0.04073937, 0.01927733, -0.054297395)), dot((max(src22, 0)), float4(-0.2929976, 0.030110704, 0.15335669, -0.077522054)), dot((max(src22, 0)), float4(0.38810417, -0.18147062, -0.15384074, 0.07918369)), dot((max(src22, 0)), float4(0.5605376, -0.09833952, -0.110595055, -0.068480626))) + (result);
	result = float4(dot((max(-src00, 0)), float4(0.23263514, -0.020222448, 0.12529704, 0.18350503)), dot((max(-src00, 0)), float4(-0.11719232, -0.17790157, 0.25548857, -0.29593533)), dot((max(-src00, 0)), float4(0.2903209, -0.15600762, -0.04585447, 0.0868933)), dot((max(-src00, 0)), float4(-0.007503795, -0.08741775, -0.10255033, 0.027004737))) + (result);
	result = float4(dot((max(-src01, 0)), float4(-0.14958654, -0.17057803, 0.05967142, -0.08596779)), dot((max(-src01, 0)), float4(-0.006238835, 0.12524141, -0.07790818, 0.07875358)), dot((max(-src01, 0)), float4(-0.2928948, 0.13978264, -0.5893818, -0.03316667)), dot((max(-src01, 0)), float4(0.1988557, -0.019280292, -0.022845713, -0.4369282))) + (result);
	result = float4(dot((max(-src02, 0)), float4(0.19195688, 0.090833396, -0.05017118, 0.53920543)), dot((max(-src02, 0)), float4(-0.060883682, 0.003422883, 0.022862168, -0.10252776)), dot((max(-src02, 0)), float4(-0.25897828, 0.109534174, -0.270113, -0.091807485)), dot((max(-src02, 0)), float4(0.07063324, 0.031180874, -0.057831235, 0.004294343))) + (result);
	result = float4(dot((max(-src10, 0)), float4(-0.18494242, 0.15568028, -0.15292497, 0.001643022)), dot((max(-src10, 0)), float4(-0.119284816, -0.2854859, 0.21895619, -0.026176987)), dot((max(-src10, 0)), float4(0.3821897, -0.22441281, -0.095677756, 0.048463076)), dot((max(-src10, 0)), float4(0.07777979, -0.049155876, 0.15210424, -0.4824009))) + (result);
	result = float4(dot((max(-src11, 0)), float4(0.007215129, -0.17180431, -0.08294297, 0.4092668)), dot((max(-src11, 0)), float4(0.17074333, -0.15163863, -0.24580221, 0.06288688)), dot((max(-src11, 0)), float4(0.053930074, -0.0012122132, -0.46552867, -0.1602188)), dot((max(-src11, 0)), float4(-0.027014816, -0.18934256, -0.27923223, -0.0030876845))) + (result);
	result = float4(dot((max(-src12, 0)), float4(0.111870885, -0.05104131, 0.05493792, 0.49054706)), dot((max(-src12, 0)), float4(0.03317145, 0.13979794, -0.14975783, 0.18288186)), dot((max(-src12, 0)), float4(0.14155298, 0.018966835, -0.10293237, -0.26925826)), dot((max(-src12, 0)), float4(0.20328505, -0.07238511, -0.21985306, 0.35845932))) + (result);
	result = float4(dot((max(-src20, 0)), float4(0.3747799, -0.17421168, -0.20580359, 0.28350568)), dot((max(-src20, 0)), float4(-0.096748486, -0.018461818, 0.56189656, -0.21486014)), dot((max(-src20, 0)), float4(-0.17139742, 0.09747162, 0.17151354, -0.44330928)), dot((max(-src20, 0)), float4(0.25289854, 0.01660535, -0.26347768, -0.008981037))) + (result);
	result = float4(dot((max(-src21, 0)), float4(0.10169985, -0.09468786, 0.10630112, 0.21764882)), dot((max(-src21, 0)), float4(-0.18244018, -0.024218475, 0.3677178, 0.0789158)), dot((max(-src21, 0)), float4(0.04760736, 0.103733875, -0.104170956, -0.22041337)), dot((max(-src21, 0)), float4(0.41017643, -0.22540338, 0.057317447, 0.15065216))) + (result);
	result = float4(dot((max(-src22, 0)), float4(0.11633995, 0.058413275, 0.13760869, -0.087339684)), dot((max(-src22, 0)), float4(-0.008195114, 0.055995367, 0.040319785, 0.1412073)), dot((max(-src22, 0)), float4(-0.14501533, 0.09362145, 0.038895044, -0.17166458)), dot((max(-src22, 0)), float4(0.07168025, -0.13827963, 0.2675253, -0.2312994))) + (result);
	Out4 = result;
}

void Anime4K_PS5(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out5 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float4 src00, src01, src02, src03, src10, src11, src12, src13, src20, src21, src22, src23, src30, src31, src32, src33;
	float2 tpos_0_0 = (float2(pix) + float2(0, 0)) * rcp;
	float4 g0_0_x = tex2Dgather(SampT4, tpos_0_0, 0);
	float4 g0_0_y = tex2Dgather(SampT4, tpos_0_0, 1);
	float4 g0_0_z = tex2Dgather(SampT4, tpos_0_0, 2);
	float4 g0_0_w = tex2Dgather(SampT4, tpos_0_0, 3);
	src00 = float4(g0_0_x.w, g0_0_y.w, g0_0_z.w, g0_0_w.w);
	src01 = float4(g0_0_x.x, g0_0_y.x, g0_0_z.x, g0_0_w.x);
	src10 = float4(g0_0_x.z, g0_0_y.z, g0_0_z.z, g0_0_w.z);
	src11 = float4(g0_0_x.y, g0_0_y.y, g0_0_z.y, g0_0_w.y);
	float2 tpos_0_2 = (float2(pix) + float2(0, 2)) * rcp;
	float4 g0_2_x = tex2Dgather(SampT4, tpos_0_2, 0);
	float4 g0_2_y = tex2Dgather(SampT4, tpos_0_2, 1);
	float4 g0_2_z = tex2Dgather(SampT4, tpos_0_2, 2);
	float4 g0_2_w = tex2Dgather(SampT4, tpos_0_2, 3);
	src02 = float4(g0_2_x.w, g0_2_y.w, g0_2_z.w, g0_2_w.w);
	src03 = float4(g0_2_x.x, g0_2_y.x, g0_2_z.x, g0_2_w.x);
	src12 = float4(g0_2_x.z, g0_2_y.z, g0_2_z.z, g0_2_w.z);
	src13 = float4(g0_2_x.y, g0_2_y.y, g0_2_z.y, g0_2_w.y);
	float2 tpos_2_0 = (float2(pix) + float2(2, 0)) * rcp;
	float4 g2_0_x = tex2Dgather(SampT4, tpos_2_0, 0);
	float4 g2_0_y = tex2Dgather(SampT4, tpos_2_0, 1);
	float4 g2_0_z = tex2Dgather(SampT4, tpos_2_0, 2);
	float4 g2_0_w = tex2Dgather(SampT4, tpos_2_0, 3);
	src20 = float4(g2_0_x.w, g2_0_y.w, g2_0_z.w, g2_0_w.w);
	src21 = float4(g2_0_x.x, g2_0_y.x, g2_0_z.x, g2_0_w.x);
	src30 = float4(g2_0_x.z, g2_0_y.z, g2_0_z.z, g2_0_w.z);
	src31 = float4(g2_0_x.y, g2_0_y.y, g2_0_z.y, g2_0_w.y);
	float2 tpos_2_2 = (float2(pix) + float2(2, 2)) * rcp;
	float4 g2_2_x = tex2Dgather(SampT4, tpos_2_2, 0);
	float4 g2_2_y = tex2Dgather(SampT4, tpos_2_2, 1);
	float4 g2_2_z = tex2Dgather(SampT4, tpos_2_2, 2);
	float4 g2_2_w = tex2Dgather(SampT4, tpos_2_2, 3);
	src22 = float4(g2_2_x.w, g2_2_y.w, g2_2_z.w, g2_2_w.w);
	src23 = float4(g2_2_x.x, g2_2_y.x, g2_2_z.x, g2_2_w.x);
	src32 = float4(g2_2_x.z, g2_2_y.z, g2_2_z.z, g2_2_w.z);
	src33 = float4(g2_2_x.y, g2_2_y.y, g2_2_z.y, g2_2_w.y);
	float4 result = float4( -0.048888464, -0.0561434, 0.030690912, -0.030496685 );
	result = float4(dot((max(src00, 0)), float4(-0.29012984, -0.050289866, 0.060307387, -0.07999419)), dot((max(src00, 0)), float4(-0.13150147, 0.14845313, -0.04160452, 0.11818284)), dot((max(src00, 0)), float4(0.31015614, -0.09608898, 0.035932682, -0.27512288)), dot((max(src00, 0)), float4(0.05992291, 0.27913308, -0.08137563, 0.21948813))) + (result);
	result = float4(dot((max(src01, 0)), float4(0.12916058, 0.053470243, -0.01689101, -0.20692012)), dot((max(src01, 0)), float4(-0.21759962, 0.1412425, -0.2623835, -0.1677863)), dot((max(src01, 0)), float4(-0.33868533, 0.043395396, 0.010809152, -0.23313859)), dot((max(src01, 0)), float4(0.021636661, -0.26751056, 0.062962815, -0.17402615))) + (result);
	result = float4(dot((max(src02, 0)), float4(-0.08204112, -0.056692924, 0.14137582, 0.15734316)), dot((max(src02, 0)), float4(-0.23672083, -0.02708657, 0.15404348, 0.16562423)), dot((max(src02, 0)), float4(-0.0064437394, 0.12536962, -0.105753876, -0.010160829)), dot((max(src02, 0)), float4(-0.13200696, 0.004428919, 0.047957454, -0.06602983))) + (result);
	result = float4(dot((max(src10, 0)), float4(0.025653997, -0.36005193, 0.4663994, -0.35774228)), dot((max(src10, 0)), float4(-0.10877775, 0.1816357, 0.0065186517, -0.041366056)), dot((max(src10, 0)), float4(-0.31258908, -0.34537643, 0.08109033, -0.37852773)), dot((max(src10, 0)), float4(0.18841636, -0.0741087, 0.2976773, 0.050565656))) + (result);
	result = float4(dot((max(src11, 0)), float4(0.04392313, -0.1651274, -0.1153939, -0.06868256)), dot((max(src11, 0)), float4(0.11316681, -0.5656209, 0.16829851, -0.56935954)), dot((max(src11, 0)), float4(-0.14421389, -0.124100484, 0.2025612, -0.12227961)), dot((max(src11, 0)), float4(0.17985669, 0.42774054, 0.054007456, 0.17688861))) + (result);
	result = float4(dot((max(src12, 0)), float4(0.34041, -0.2732667, 0.2609023, 0.049288407)), dot((max(src12, 0)), float4(0.499, -0.049950935, 0.016438454, -0.31126305)), dot((max(src12, 0)), float4(0.15234196, 0.03550811, -0.29874632, 0.029235512)), dot((max(src12, 0)), float4(0.21353458, -0.21051687, 0.37994128, -0.012256015))) + (result);
	result = float4(dot((max(src20, 0)), float4(-0.0046853204, -0.08137621, -0.066420384, -0.06260773)), dot((max(src20, 0)), float4(0.15391374, 0.35905558, 0.029600656, 0.04634221)), dot((max(src20, 0)), float4(-0.040689662, 0.23733845, -0.31421044, -0.10948491)), dot((max(src20, 0)), float4(0.20186873, 0.21794793, -0.050773863, -0.045498934))) + (result);
	result = float4(dot((max(src21, 0)), float4(-0.082953, 0.275064, -0.4382666, 0.5695728)), dot((max(src21, 0)), float4(-0.025837064, 0.07793617, -0.2932182, 0.20719238)), dot((max(src21, 0)), float4(-0.09928303, 0.22240888, -0.27243167, 0.5575927)), dot((max(src21, 0)), float4(-0.14300232, 0.06637834, -0.14221182, 0.40816882))) + (result);
	result = float4(dot((max(src22, 0)), float4(-0.18510929, 0.016387, -0.28987274, 0.29543474)), dot((max(src22, 0)), float4(-0.15052167, 0.20310035, -0.11942605, -0.042830903)), dot((max(src22, 0)), float4(0.25277212, 0.2903229, 0.013498961, -0.018111207)), dot((max(src22, 0)), float4(0.06804461, -0.0615877, 0.3184152, -0.13263674))) + (result);
	result = float4(dot((max(-src00, 0)), float4(0.25749087, -0.094091184, -0.062903, -0.073379934)), dot((max(-src00, 0)), float4(0.0053866603, -0.07419633, -0.0204224, 0.052201986)), dot((max(-src00, 0)), float4(-0.09391162, 0.0013858611, -0.12113313, 0.35864577)), dot((max(-src00, 0)), float4(-0.06129529, 0.012000353, 0.017942557, 0.023564404))) + (result);
	result = float4(dot((max(-src01, 0)), float4(0.100115694, -0.12470779, -0.15159339, 0.19735703)), dot((max(-src01, 0)), float4(0.19451359, 0.0027281935, 0.18457152, 0.07326743)), dot((max(-src01, 0)), float4(0.23252094, -0.17488572, 0.057712987, -0.28563106)), dot((max(-src01, 0)), float4(0.19506809, -0.018721964, -0.08191495, 0.01642815))) + (result);
	result = float4(dot((max(-src02, 0)), float4(0.068062514, 0.28725025, -0.16676305, 0.084470876)), dot((max(-src02, 0)), float4(0.28356665, -0.13045293, -0.2555945, 0.06460686)), dot((max(-src02, 0)), float4(0.07377898, -0.17525704, -0.10078422, 0.13824362)), dot((max(-src02, 0)), float4(0.42776972, -0.05885591, -0.053032875, -0.05231353))) + (result);
	result = float4(dot((max(-src10, 0)), float4(0.22637829, 0.038017053, -0.3821112, 0.22416145)), dot((max(-src10, 0)), float4(-0.028969254, -0.008854481, 0.1108527, -0.031492114)), dot((max(-src10, 0)), float4(0.1968254, -0.2031639, -0.11029933, -0.19144306)), dot((max(-src10, 0)), float4(-0.13331996, 0.09237089, -0.24542028, -0.0996271))) + (result);
	result = float4(dot((max(-src11, 0)), float4(0.10776744, -0.06642015, 0.12506576, 0.01706349)), dot((max(-src11, 0)), float4(0.16363445, 0.5616549, -0.15329036, 0.1813702)), dot((max(-src11, 0)), float4(0.14656505, -0.008412252, 0.037538245, 0.035651788)), dot((max(-src11, 0)), float4(-0.3737814, -0.37266847, -0.10810259, -0.012786579))) + (result);
	result = float4(dot((max(-src12, 0)), float4(-0.4023338, 0.26107362, -0.39958602, 0.36178818)), dot((max(-src12, 0)), float4(-0.2098614, 0.041306913, -0.21229339, 0.20934913)), dot((max(-src12, 0)), float4(-0.18285121, -0.036515504, -0.021053292, 0.1500852)), dot((max(-src12, 0)), float4(-0.02727653, -0.045217298, -0.13427502, 0.2634554))) + (result);
	result = float4(dot((max(-src20, 0)), float4(0.07794611, 0.094220124, -0.08068449, 0.23963861)), dot((max(-src20, 0)), float4(-0.25937587, 0.21588847, -0.31366697, 0.13715535)), dot((max(-src20, 0)), float4(-0.06822529, -0.0455218, 0.07799637, 0.010329345)), dot((max(-src20, 0)), float4(-0.056336135, -0.10968329, 0.24252681, 0.09094301))) + (result);
	result = float4(dot((max(-src21, 0)), float4(-0.20975718, -0.07153068, 0.37204072, 0.2571982)), dot((max(-src21, 0)), float4(-0.12550138, 0.3249998, 0.17018336, -0.27258632)), dot((max(-src21, 0)), float4(0.14453574, -0.056577377, 0.3752895, -0.25971004)), dot((max(-src21, 0)), float4(-0.0020878632, 0.18166828, 0.32178587, -0.40536007))) + (result);
	result = float4(dot((max(-src22, 0)), float4(-0.3243907, 0.14906861, 0.12964857, 0.05807971)), dot((max(-src22, 0)), float4(-0.06300621, 0.061537784, 0.09979093, -0.056371246)), dot((max(-src22, 0)), float4(-0.09398436, -0.055284478, -0.1810159, 0.08072554)), dot((max(-src22, 0)), float4(-0.19549188, 0.11281728, -0.4104283, 0.18479007))) + (result);
	Out5 = result;
}

void Anime4K_PS6(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out6 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float4 src00, src01, src02, src03, src10, src11, src12, src13, src20, src21, src22, src23, src30, src31, src32, src33;
	float2 tpos_0_0 = (float2(pix) + float2(0, 0)) * rcp;
	float4 g0_0_x = tex2Dgather(SampT5, tpos_0_0, 0);
	float4 g0_0_y = tex2Dgather(SampT5, tpos_0_0, 1);
	float4 g0_0_z = tex2Dgather(SampT5, tpos_0_0, 2);
	float4 g0_0_w = tex2Dgather(SampT5, tpos_0_0, 3);
	src00 = float4(g0_0_x.w, g0_0_y.w, g0_0_z.w, g0_0_w.w);
	src01 = float4(g0_0_x.x, g0_0_y.x, g0_0_z.x, g0_0_w.x);
	src10 = float4(g0_0_x.z, g0_0_y.z, g0_0_z.z, g0_0_w.z);
	src11 = float4(g0_0_x.y, g0_0_y.y, g0_0_z.y, g0_0_w.y);
	float2 tpos_0_2 = (float2(pix) + float2(0, 2)) * rcp;
	float4 g0_2_x = tex2Dgather(SampT5, tpos_0_2, 0);
	float4 g0_2_y = tex2Dgather(SampT5, tpos_0_2, 1);
	float4 g0_2_z = tex2Dgather(SampT5, tpos_0_2, 2);
	float4 g0_2_w = tex2Dgather(SampT5, tpos_0_2, 3);
	src02 = float4(g0_2_x.w, g0_2_y.w, g0_2_z.w, g0_2_w.w);
	src03 = float4(g0_2_x.x, g0_2_y.x, g0_2_z.x, g0_2_w.x);
	src12 = float4(g0_2_x.z, g0_2_y.z, g0_2_z.z, g0_2_w.z);
	src13 = float4(g0_2_x.y, g0_2_y.y, g0_2_z.y, g0_2_w.y);
	float2 tpos_2_0 = (float2(pix) + float2(2, 0)) * rcp;
	float4 g2_0_x = tex2Dgather(SampT5, tpos_2_0, 0);
	float4 g2_0_y = tex2Dgather(SampT5, tpos_2_0, 1);
	float4 g2_0_z = tex2Dgather(SampT5, tpos_2_0, 2);
	float4 g2_0_w = tex2Dgather(SampT5, tpos_2_0, 3);
	src20 = float4(g2_0_x.w, g2_0_y.w, g2_0_z.w, g2_0_w.w);
	src21 = float4(g2_0_x.x, g2_0_y.x, g2_0_z.x, g2_0_w.x);
	src30 = float4(g2_0_x.z, g2_0_y.z, g2_0_z.z, g2_0_w.z);
	src31 = float4(g2_0_x.y, g2_0_y.y, g2_0_z.y, g2_0_w.y);
	float2 tpos_2_2 = (float2(pix) + float2(2, 2)) * rcp;
	float4 g2_2_x = tex2Dgather(SampT5, tpos_2_2, 0);
	float4 g2_2_y = tex2Dgather(SampT5, tpos_2_2, 1);
	float4 g2_2_z = tex2Dgather(SampT5, tpos_2_2, 2);
	float4 g2_2_w = tex2Dgather(SampT5, tpos_2_2, 3);
	src22 = float4(g2_2_x.w, g2_2_y.w, g2_2_z.w, g2_2_w.w);
	src23 = float4(g2_2_x.x, g2_2_y.x, g2_2_z.x, g2_2_w.x);
	src32 = float4(g2_2_x.z, g2_2_y.z, g2_2_z.z, g2_2_w.z);
	src33 = float4(g2_2_x.y, g2_2_y.y, g2_2_z.y, g2_2_w.y);
	float4 result = float4( 0.011169491, 0.032399546, 0.138099, 0.023857072 );
	result = float4(dot((max(src00, 0)), float4(0.15332128, 0.17021236, 0.51826185, 0.1990321)), dot((max(src00, 0)), float4(0.027258258, -0.51046044, -0.34817994, -0.049979225)), dot((max(src00, 0)), float4(0.14900503, -0.15287271, 0.004513167, 0.11391989)), dot((max(src00, 0)), float4(-0.15982795, -0.058167327, 0.05395769, -0.16062729))) + (result);
	result = float4(dot((max(src01, 0)), float4(0.033682905, 0.2585768, -0.1146207, 0.25497693)), dot((max(src01, 0)), float4(0.019728886, -0.2124572, -0.2396625, 0.11692859)), dot((max(src01, 0)), float4(0.19931756, -0.014632459, 0.08960277, -0.14207517)), dot((max(src01, 0)), float4(0.17381927, 0.39779893, 0.38345298, 0.12667973))) + (result);
	result = float4(dot((max(src02, 0)), float4(-0.14911255, 0.24204038, -0.0021356856, 0.045177583)), dot((max(src02, 0)), float4(0.08910706, -0.03607149, 0.00885878, 0.11120606)), dot((max(src02, 0)), float4(0.16136818, -0.4571109, 0.22297303, -0.009971904)), dot((max(src02, 0)), float4(0.03914566, 0.10802461, 0.2367231, -0.059262395))) + (result);
	result = float4(dot((max(src10, 0)), float4(0.24565999, -0.10923052, 0.3544573, 0.18760219)), dot((max(src10, 0)), float4(-0.2261384, 0.039027315, -0.5468578, -0.19082001)), dot((max(src10, 0)), float4(0.47373205, -0.42707404, -0.27599156, 0.030565469)), dot((max(src10, 0)), float4(0.024613412, -0.3783373, -0.09455918, 0.20589156))) + (result);
	result = float4(dot((max(src11, 0)), float4(0.1973198, 0.1819595, -0.042632047, -0.19563004)), dot((max(src11, 0)), float4(-0.03433863, -0.14460869, -0.11842967, 0.027425969)), dot((max(src11, 0)), float4(0.059960485, 0.1286175, -0.11224446, 0.24056377)), dot((max(src11, 0)), float4(0.045642868, 0.2067575, -0.18764776, 0.5949649))) + (result);
	result = float4(dot((max(src12, 0)), float4(0.055027682, 0.4588985, -0.001210133, -0.049561135)), dot((max(src12, 0)), float4(0.16331595, 0.03642909, -0.057651415, 0.27509886)), dot((max(src12, 0)), float4(-0.2608588, 0.22187738, -0.061199043, 0.13778673)), dot((max(src12, 0)), float4(0.12545955, 0.45190734, 0.11935476, -0.124914035))) + (result);
	result = float4(dot((max(src20, 0)), float4(-0.02257459, 0.05982374, -0.10155528, 0.3295707)), dot((max(src20, 0)), float4(0.27705106, -0.2824302, 0.16182268, -0.50616395)), dot((max(src20, 0)), float4(0.044165276, 0.3171142, -0.09183147, -0.036964044)), dot((max(src20, 0)), float4(-0.26521233, 0.08430561, -0.19447176, 0.23166709))) + (result);
	result = float4(dot((max(src21, 0)), float4(-0.0232342, -0.108305976, -0.26488534, -0.33094683)), dot((max(src21, 0)), float4(0.07299799, 0.15024792, 0.19481428, 0.24155116)), dot((max(src21, 0)), float4(-0.18038079, -0.19531927, 0.10737945, -0.09850332)), dot((max(src21, 0)), float4(-0.13672702, 0.0870979, -0.14573483, 0.2797003))) + (result);
	result = float4(dot((max(src22, 0)), float4(-0.24089853, 0.36212957, -0.07795971, -0.25893036)), dot((max(src22, 0)), float4(0.19506595, -0.44844806, -0.0033861927, 0.23793478)), dot((max(src22, 0)), float4(0.4799156, 0.23864488, -0.11216164, -0.15769425)), dot((max(src22, 0)), float4(-0.058313113, 0.15477742, 0.033454563, -0.00033481256))) + (result);
	result = float4(dot((max(-src00, 0)), float4(0.05772507, -0.024399966, 0.00036956606, 0.026651502)), dot((max(-src00, 0)), float4(-0.1640253, 0.14966168, -0.24236615, 0.39019194)), dot((max(-src00, 0)), float4(-0.13499664, -0.090857334, -0.053542696, -0.2742246)), dot((max(-src00, 0)), float4(-0.20460358, -0.039677754, -0.0049544116, -0.061242323))) + (result);
	result = float4(dot((max(-src01, 0)), float4(-0.016323274, -0.00016685206, 0.1324275, -0.02770517)), dot((max(-src01, 0)), float4(-0.036179908, -0.29573023, -0.18442132, 0.28452995)), dot((max(-src01, 0)), float4(0.029965919, 0.17996423, -0.24618152, 0.39804098)), dot((max(-src01, 0)), float4(0.11151491, -0.20145437, 0.061780427, -0.1174389))) + (result);
	result = float4(dot((max(-src02, 0)), float4(-0.025068847, -0.09866204, -0.13319959, -0.05062645)), dot((max(-src02, 0)), float4(-0.053328387, 0.057677213, -0.14411181, -0.036771543)), dot((max(-src02, 0)), float4(-0.27053785, 0.01850112, -0.26355243, 0.13294417)), dot((max(-src02, 0)), float4(0.26866457, -0.18014707, -0.022209354, -0.18458557))) + (result);
	result = float4(dot((max(-src10, 0)), float4(-0.046194963, 0.11031123, -0.5279925, 0.31593755)), dot((max(-src10, 0)), float4(0.038230438, -0.16504908, 0.12686682, 0.027328093)), dot((max(-src10, 0)), float4(-0.08993043, -0.09517036, -0.05726125, 0.001839602)), dot((max(-src10, 0)), float4(-0.07236354, -0.16459833, 0.055361677, 0.30581662))) + (result);
	result = float4(dot((max(-src11, 0)), float4(0.08608678, -0.1268983, 0.018839337, -0.0872339)), dot((max(-src11, 0)), float4(0.03168437, 0.13395861, -0.049821075, 0.47096667)), dot((max(-src11, 0)), float4(0.007713377, -0.069848835, -0.21461345, 0.022512507)), dot((max(-src11, 0)), float4(-0.26140293, -0.24080403, -0.14168301, 0.14860632))) + (result);
	result = float4(dot((max(-src12, 0)), float4(0.06293673, 0.18227446, -0.012190269, -0.3853647)), dot((max(-src12, 0)), float4(0.22462969, -0.2956555, 0.241983, 0.1081711)), dot((max(-src12, 0)), float4(0.045494985, 0.08010543, -0.046537094, -0.16926058)), dot((max(-src12, 0)), float4(0.021673543, -0.01919729, -0.40094566, 0.16138376))) + (result);
	result = float4(dot((max(-src20, 0)), float4(-0.14854589, 0.099971965, 0.054358527, -0.16914125)), dot((max(-src20, 0)), float4(-0.17625804, 0.13901573, -0.10351705, 0.12729423)), dot((max(-src20, 0)), float4(-0.10849075, 0.29464146, -0.0062914286, -0.18377453)), dot((max(-src20, 0)), float4(0.221543, 0.020068526, 0.24127026, -0.6452375))) + (result);
	result = float4(dot((max(-src21, 0)), float4(0.12603393, -0.13619255, 0.19077192, -0.015576321)), dot((max(-src21, 0)), float4(-0.10986093, -0.09349073, 0.052500796, 0.08254907)), dot((max(-src21, 0)), float4(0.2314103, 0.20594226, 0.07185645, -0.5501743)), dot((max(-src21, 0)), float4(0.16915044, -0.34507084, 0.029082738, -0.38495848))) + (result);
	result = float4(dot((max(-src22, 0)), float4(0.09300796, 0.06321122, 0.09697148, 0.18379296)), dot((max(-src22, 0)), float4(-0.079218306, 0.16234867, 0.23457524, 0.17770062)), dot((max(-src22, 0)), float4(0.46825135, 0.042932414, 0.19417483, -0.050235)), dot((max(-src22, 0)), float4(-0.08735625, -0.013057422, -0.16804664, -0.059676602))) + (result);
	Out6 = result;
}

void Anime4K_PS7(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out7 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 pos = (float2(pix) + 0.5) * rcp;
	float4 a = tex2Dlod(SampT6, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b = tex2Dlod(SampT6, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c = tex2Dlod(SampT6, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d = tex2Dlod(SampT6, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e = tex2Dlod(SampT6, float4(pos, 0, 0));
	float4 f = tex2Dlod(SampT6, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g = tex2Dlod(SampT6, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h = tex2Dlod(SampT6, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i = tex2Dlod(SampT6, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 src1 = tex2Dlod(SampT1, float4(pos, 0, 0));
	float4 src2 = tex2Dlod(SampT2, float4(pos, 0, 0));
	float4 src3 = tex2Dlod(SampT3, float4(pos, 0, 0));
	float4 src4 = tex2Dlod(SampT4, float4(pos, 0, 0));
	float4 src5 = tex2Dlod(SampT5, float4(pos, 0, 0));
	float4 src6 = tex2Dlod(SampT6, float4(pos, 0, 0));
	float3 origin = tex2Dlod(SampInput, float4(pos, 0, 0)).rgb;
	float4 src7 = float4( 0.013687534, -0.08185164, -0.04755438, 0.290178 );
	src7 = float4(dot((max(a, 0)), float4(-0.22753362, -0.18788953, 0.054559365, 0.14884405)), dot((max(a, 0)), float4(-0.08612073, -0.056579117, 0.15031597, -0.0694291)), dot((max(a, 0)), float4(0.33140692, -0.12905197, -0.13430363, 0.26149413)), dot((max(a, 0)), float4(0.08699529, -0.06694621, 0.021646025, 0.11270503))) + (src7);
	src7 = float4(dot((max(b, 0)), float4(0.17876762, 0.1317187, 0.28760737, -0.16811855)), dot((max(b, 0)), float4(-0.09637848, -0.036162686, -0.12505141, -0.16340709)), dot((max(b, 0)), float4(0.11285323, 0.17958368, 0.12760694, 0.13278298)), dot((max(b, 0)), float4(0.2004893, -0.069625, 0.047717955, -0.08403954))) + (src7);
	src7 = float4(dot((max(c, 0)), float4(-0.21917523, 0.03001489, -0.013841082, -0.22184245)), dot((max(c, 0)), float4(0.079711854, -0.014772918, 0.17034237, -0.59067357)), dot((max(c, 0)), float4(-0.28642535, -0.3487396, 0.10810282, 0.44113398)), dot((max(c, 0)), float4(0.2822416, 0.10597145, -0.08089695, 0.13045649))) + (src7);
	src7 = float4(dot((max(d, 0)), float4(-0.29906932, -0.13953634, 0.10563715, -0.37824214)), dot((max(d, 0)), float4(0.013923749, 0.08003455, 0.31033117, -0.14506383)), dot((max(d, 0)), float4(0.2031124, -0.10164494, -0.075903505, 0.11866701)), dot((max(d, 0)), float4(-0.11846688, -0.21218559, 0.047310907, -0.21384487))) + (src7);
	src7 = float4(dot((max(e, 0)), float4(-0.1353849, 0.27244982, 0.18514316, -0.057732623)), dot((max(e, 0)), float4(0.19258606, 0.1665306, -0.17840464, 0.42166704)), dot((max(e, 0)), float4(0.063908584, -0.29357895, 0.20986097, -0.23182064)), dot((max(e, 0)), float4(-0.2043788, -0.22441709, 0.14351055, -0.4957248))) + (src7);
	src7 = float4(dot((max(f, 0)), float4(-0.34830126, -0.12290918, 0.23047262, 0.3066665)), dot((max(f, 0)), float4(0.109066755, 0.04291651, 0.09398974, -0.54077)), dot((max(f, 0)), float4(-0.28285867, -0.047484186, 0.022467108, 0.057771873)), dot((max(f, 0)), float4(-0.048280068, -0.03702595, 0.08271034, 0.23194093))) + (src7);
	src7 = float4(dot((max(g, 0)), float4(-0.17731948, -0.16433562, -0.14827462, 0.16989979)), dot((max(g, 0)), float4(-0.3175927, -0.01833653, 0.18544114, -0.20985202)), dot((max(g, 0)), float4(0.1452728, -0.22345604, -0.15544125, 0.16391534)), dot((max(g, 0)), float4(0.09396786, -0.04161193, -0.06179007, -0.09447268))) + (src7);
	src7 = float4(dot((max(h, 0)), float4(-0.053878862, 0.31647214, -0.21446131, 0.12109098)), dot((max(h, 0)), float4(-0.21034616, 0.0126534775, 0.067189045, 0.22009392)), dot((max(h, 0)), float4(0.023831524, -0.19130844, 0.09117449, -0.3924665)), dot((max(h, 0)), float4(0.19772215, -0.049282108, -0.25548774, -0.13340388))) + (src7);
	src7 = float4(dot((max(i, 0)), float4(-0.16096684, -0.00183498, 0.043269135, 0.11555763)), dot((max(i, 0)), float4(-0.18495405, -0.044303037, 0.06924481, -0.20292862)), dot((max(i, 0)), float4(0.10410178, -0.062745355, -0.21367405, 0.5799557)), dot((max(i, 0)), float4(0.0015673033, -0.090802394, -0.14619029, 0.14739846))) + (src7);
	src7 = float4(dot((max(-a, 0)), float4(-0.21030277, 0.12995781, 0.15550353, -0.07694621)), dot((max(-a, 0)), float4(-0.09578802, 0.40431052, -0.04402301, -0.053523075)), dot((max(-a, 0)), float4(0.013482288, -0.3347856, 0.4603779, -0.19607326)), dot((max(-a, 0)), float4(-0.21484336, -0.18183486, 0.14874357, -0.10850742))) + (src7);
	src7 = float4(dot((max(-b, 0)), float4(-0.2347211, 0.17231455, -0.233575, 0.022935199)), dot((max(-b, 0)), float4(0.2697403, 0.24999185, 0.52950364, 0.19369157)), dot((max(-b, 0)), float4(-0.0634794, -0.5208536, 0.0038063182, 0.14586553)), dot((max(-b, 0)), float4(-0.17925987, -0.10491828, -0.1380038, 0.1938704))) + (src7);
	src7 = float4(dot((max(-c, 0)), float4(-0.10245223, 0.5597771, 0.1704679, -0.056995615)), dot((max(-c, 0)), float4(0.34150192, 0.114510864, -0.23335956, 0.24153493)), dot((max(-c, 0)), float4(0.25862157, -0.122526556, -0.16771887, -0.08082429)), dot((max(-c, 0)), float4(-0.20165509, -0.04010975, -0.03783455, -0.24210933))) + (src7);
	src7 = float4(dot((max(-d, 0)), float4(-0.103466526, 0.103505425, -0.09180311, 0.07528779)), dot((max(-d, 0)), float4(0.15278348, 0.15862796, -0.12505089, -0.09636086)), dot((max(-d, 0)), float4(-0.30526164, 0.14696524, 0.28052542, -0.10369617)), dot((max(-d, 0)), float4(-0.080755696, -0.008358076, -0.13551563, 0.23656134))) + (src7);
	src7 = float4(dot((max(-e, 0)), float4(-0.25752836, 0.023509016, 0.088015385, 0.18096298)), dot((max(-e, 0)), float4(0.099439755, 0.23106368, 0.26995596, -0.100688554)), dot((max(-e, 0)), float4(-0.30716348, 0.05277125, 0.1390645, 0.5492049)), dot((max(-e, 0)), float4(0.035077725, 0.34910464, -0.40671825, 0.2482101))) + (src7);
	src7 = float4(dot((max(-f, 0)), float4(0.41411775, 0.27137747, -0.03166121, -0.36956537)), dot((max(-f, 0)), float4(-0.107200556, 0.06313619, -0.3415683, 0.179129)), dot((max(-f, 0)), float4(-0.13813478, -0.08522967, -0.52242, -0.09742935)), dot((max(-f, 0)), float4(0.13768874, 0.03218302, -0.1741813, -0.11696616))) + (src7);
	src7 = float4(dot((max(-g, 0)), float4(-0.07975504, 0.14309953, 0.34612748, 0.18522519)), dot((max(-g, 0)), float4(0.17964838, 0.29473078, -0.3387473, -0.21297298)), dot((max(-g, 0)), float4(0.37122533, 0.0926391, 0.0077308523, 0.11493978)), dot((max(-g, 0)), float4(0.16064765, -0.22333665, -0.07239449, 0.16117814))) + (src7);
	src7 = float4(dot((max(-h, 0)), float4(-0.17402779, 0.18713303, -0.20102951, -0.13732676)), dot((max(-h, 0)), float4(0.10023144, 0.08736295, -0.010721135, -0.40258047)), dot((max(-h, 0)), float4(0.11712206, 0.013007052, -0.2562522, 0.25824392)), dot((max(-h, 0)), float4(0.031971734, -0.06943139, 0.34877458, 0.15720639))) + (src7);
	src7 = float4(dot((max(-i, 0)), float4(0.044494305, 0.38839245, -0.56266373, -0.18491416)), dot((max(-i, 0)), float4(0.3296108, 0.40015858, 0.251378, -0.046887)), dot((max(-i, 0)), float4(0.0017603852, -0.13395199, 0.5005789, 0.067797676)), dot((max(-i, 0)), float4(0.09362289, -0.044521853, -0.13106057, -0.14694957))) + (src7);
	float3 result = float3( -0.010478934, -0.008364784, -0.010246552 );
	result = float3(dot((max(src1, 0)), float4(-0.08837163, 0.021405501, 0.05328863, -0.12216048)), dot((max(src1, 0)), float4(-0.065234736, 0.013663729, 0.03580334, 0.022547891)), dot((max(src1, 0)), float4(-0.034704313, 0.019249594, 0.046457592, 0.016400825))) + (result);
	result = float3(dot((max(-src1, 0)), float4(0.061996464, -0.005013109, 0.016481603, 0.020035887)), dot((max(-src1, 0)), float4(0.05631466, -0.0044589997, 0.13721058, -0.07250003)), dot((max(-src1, 0)), float4(0.06808407, -0.032367796, 0.14924648, -0.08034037))) + (result);
	result = float3(dot((max(src2, 0)), float4(0.24078514, -0.009353794, -0.14071098, -0.1489842)), dot((max(src2, 0)), float4(0.081361525, -0.051077116, 0.01035966, -0.06711817)), dot((max(src2, 0)), float4(0.053420708, -0.058007747, 0.005308949, -0.05552926))) + (result);
	result = float3(dot((max(-src2, 0)), float4(-0.13002375, 0.17767483, 0.12804912, 0.17044514)), dot((max(-src2, 0)), float4(0.012733757, 0.20204604, 0.07381453, 0.07301451)), dot((max(-src2, 0)), float4(0.017821986, 0.1751779, 0.05655911, 0.06523978))) + (result);
	result = float3(dot((max(src3, 0)), float4(-0.1170986, -0.16645707, -0.04143118, -0.084318705)), dot((max(src3, 0)), float4(-0.05130371, -0.121526904, 0.026693767, -0.064990036)), dot((max(src3, 0)), float4(-0.027939914, -0.09471366, 0.034615446, -0.054324172))) + (result);
	result = float3(dot((max(-src3, 0)), float4(0.12094524, 0.062216382, 0.072797105, 0.120719045)), dot((max(-src3, 0)), float4(0.09518409, 0.053228356, 0.026258165, 0.073281154)), dot((max(-src3, 0)), float4(0.07387219, 0.031372335, 0.009804673, 0.056623302))) + (result);
	result = float3(dot((max(src4, 0)), float4(-0.11141495, -0.0651895, -0.032746475, -0.024655705)), dot((max(src4, 0)), float4(-0.11566289, -0.06820691, -0.008849683, -0.048778858)), dot((max(src4, 0)), float4(-0.10398725, -0.054204144, -0.007610222, -0.041144755))) + (result);
	result = float3(dot((max(-src4, 0)), float4(0.058090195, 0.044788487, 0.04892866, -0.011864114)), dot((max(-src4, 0)), float4(0.07538767, 0.04212742, 0.015416752, -0.0074752793)), dot((max(-src4, 0)), float4(0.059722915, 0.027502589, 0.008312418, -0.0060824654))) + (result);
	result = float3(dot((max(src5, 0)), float4(0.043446552, -0.06379154, 0.016307736, 0.041445345)), dot((max(src5, 0)), float4(0.061971307, -0.053758245, 0.03423424, 0.03843772)), dot((max(src5, 0)), float4(0.05758086, -0.047204215, 0.030179083, 0.033059113))) + (result);
	result = float3(dot((max(-src5, 0)), float4(-0.003803544, 0.102071285, -0.074306004, -0.030704215)), dot((max(-src5, 0)), float4(0.0008906116, 0.11485224, -0.08803551, -0.021514274)), dot((max(-src5, 0)), float4(-0.00059585314, 0.10007254, -0.07972321, -0.009049376))) + (result);
	result = float3(dot((max(src6, 0)), float4(0.0066058086, -0.03916473, -0.03153446, 0.113516055)), dot((max(src6, 0)), float4(0.0011408008, -0.042929266, -0.039413508, 0.12577052)), dot((max(src6, 0)), float4(0.0016199006, -0.04018418, -0.034767237, 0.113335624))) + (result);
	result = float3(dot((max(-src6, 0)), float4(0.02655948, 0.048471425, 0.12092813, -0.0023508538)), dot((max(-src6, 0)), float4(0.041905303, 0.049788587, 0.13564217, 0.0012828974)), dot((max(-src6, 0)), float4(0.03861737, 0.050447535, 0.12613249, 0.0028730957))) + (result);
	result = float3(dot((max(src7, 0)), float4(0.0084758485, -0.056123603, -0.081793964, -0.04402356)), dot((max(src7, 0)), float4(0.008800083, -0.06610845, -0.101638645, -0.04177539)), dot((max(src7, 0)), float4(0.008206044, -0.060320783, -0.096699014, -0.03829645))) + (result);
	result = float3(dot((max(-src7, 0)), float4(0.10676299, -0.05880252, 0.019221924, -0.07512528)), dot((max(-src7, 0)), float4(0.118409514, -0.06488367, 0.017602798, -0.080483615)), dot((max(-src7, 0)), float4(0.10618478, -0.06432695, 0.017413978, -0.066218294))) + (result);
	Out7 = float4(result + origin, 1.0);
}

technique Anime4K_Restore_M
{
	pass P1
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS1;
		RenderTarget0 = Anime4K_T1;
	}
	pass P2
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS2;
		RenderTarget0 = Anime4K_T2;
	}
	pass P3
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS3;
		RenderTarget0 = Anime4K_T3;
	}
	pass P4
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS4;
		RenderTarget0 = Anime4K_T4;
	}
	pass P5
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS5;
		RenderTarget0 = Anime4K_T5;
	}
	pass P6
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS6;
		RenderTarget0 = Anime4K_T6;
	}
	pass P7
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS7;
	}
}
