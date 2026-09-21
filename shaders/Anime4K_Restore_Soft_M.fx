// Anime4K Restore CNN (Soft_M) ported to ReShade FX.
// Source: Magpie Anime4K_Restore_Soft_M.hlsl <- bloc97/Anime4K glsl/Restore.
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
	float4 result = float4( -0.07697861, 0.41154122, 0.042374082, -0.087270625 );
	result = float4(dot((src00), float3(-0.073079124, -0.25251916, 0.06326891)), dot((src00), float3(0.11507942, -0.08662003, 0.01635252)), dot((src00), float3(0.028201895, 0.38814726, 0.06423356)), dot((src00), float3(-0.021776304, 0.4146095, 0.13488062))) + (result);
	result = float4(dot((src01), float3(-0.059791833, -0.17314838, -0.11094062)), dot((src01), float3(-0.03105604, 0.067622855, 0.007625051)), dot((src01), float3(0.041643705, -0.032012507, 0.094762206)), dot((src01), float3(0.35197195, 0.09691628, -0.05824145))) + (result);
	result = float4(dot((src02), float3(-0.120281175, -0.41698205, -0.10906026)), dot((src02), float3(0.027440755, -0.05966847, -0.015854035)), dot((src02), float3(-0.026316144, -0.28400028, -0.028724853)), dot((src02), float3(-0.025291128, -0.06946398, -0.06626416))) + (result);
	result = float4(dot((src10), float3(0.068752654, 0.2749825, -0.062151223)), dot((src10), float3(-0.12652585, 0.015504972, 0.07457783)), dot((src10), float3(0.38200122, 0.21765926, 0.13588274)), dot((src10), float3(0.17978846, 0.2246602, -0.037328478))) + (result);
	result = float4(dot((src11), float3(0.3718559, 0.24768798, 0.212067)), dot((src11), float3(0.025637252, 0.09984098, -0.08328392)), dot((src11), float3(-0.4048626, -0.5663632, -0.5277322)), dot((src11), float3(-0.41484925, -0.6659978, -0.016879432))) + (result);
	result = float4(dot((src12), float3(-0.11072714, -0.13345073, -0.09893075)), dot((src12), float3(-0.010321538, 0.004847663, 0.031325124)), dot((src12), float3(0.11265787, 0.3744461, 0.2883957)), dot((src12), float3(0.0055236337, -0.4038564, -0.04268903))) + (result);
	result = float4(dot((src20), float3(0.10444391, -0.10860678, 0.076250754)), dot((src20), float3(-0.60588187, 0.15701362, -0.10799697)), dot((src20), float3(0.02543334, 0.29235297, 0.08841044)), dot((src20), float3(0.10911738, 0.045803998, 0.08145623))) + (result);
	result = float4(dot((src21), float3(-0.04246739, 0.5289142, -0.126204)), dot((src21), float3(-0.1225759, -0.011892906, 0.08239301)), dot((src21), float3(0.11280305, -0.0800465, -0.0092391195)), dot((src21), float3(-0.12079673, 0.05915611, -0.07672885))) + (result);
	result = float4(dot((src22), float3(-0.11922264, -0.12543046, 0.11672854)), dot((src22), float3(0.14036109, -0.08662423, -0.006516173)), dot((src22), float3(-0.09491126, -0.041537095, -0.023524825)), dot((src22), float3(0.05112697, 0.048038274, 0.030505095))) + (result);
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
	float4 result = float4( -0.08458621, -0.023144595, -0.057707336, -0.081382714 );
	result = float4(dot((max(src00, 0)), float4(-0.09419103, 0.03595256, 0.08852021, -0.19536541)), dot((max(src00, 0)), float4(-0.1178418, -0.05417468, -0.12534834, 0.21548285)), dot((max(src00, 0)), float4(0.09523275, -0.029167585, 0.0604663, 0.040379744)), dot((max(src00, 0)), float4(0.24648252, -0.012279932, 0.050634373, -0.28046605))) + (result);
	result = float4(dot((max(src01, 0)), float4(-0.13783203, -0.029844455, 0.12017991, 0.08440897)), dot((max(src01, 0)), float4(0.17191975, -0.17657366, -0.087307535, 0.09969244)), dot((max(src01, 0)), float4(0.06956328, 0.03439078, 0.11815637, -0.06220224)), dot((max(src01, 0)), float4(0.005270252, 0.048861686, 0.31309614, 0.2633136))) + (result);
	result = float4(dot((max(src02, 0)), float4(0.098606475, -0.08988821, 0.21017794, -0.08751144)), dot((max(src02, 0)), float4(-0.05856224, 0.18520717, 0.038311377, -0.0081623215)), dot((max(src02, 0)), float4(-0.01163882, 0.011407763, -0.018910313, 0.29060364)), dot((max(src02, 0)), float4(-0.020945825, 0.20973705, 0.053878684, 0.14363094))) + (result);
	result = float4(dot((max(src10, 0)), float4(0.13354321, -0.045502663, 0.16157807, -0.0053555835)), dot((max(src10, 0)), float4(-0.38046083, 0.0053245644, 0.2086147, -0.19587666)), dot((max(src10, 0)), float4(0.14157647, -0.10817685, 0.07632662, -0.46687222)), dot((max(src10, 0)), float4(0.10190452, -0.048371315, 0.24636099, 0.002362032))) + (result);
	result = float4(dot((max(src11, 0)), float4(0.28275147, 0.18727398, -0.092296466, -0.27637103)), dot((max(src11, 0)), float4(-0.1468291, 0.3833064, -0.25686404, 0.12317917)), dot((max(src11, 0)), float4(0.24075283, 0.08667899, -0.116076745, -0.0341737)), dot((max(src11, 0)), float4(-0.35119128, 0.15021381, 0.2231862, -0.40077657))) + (result);
	result = float4(dot((max(src12, 0)), float4(-0.007041629, -0.06088577, 0.07200418, 0.21025613)), dot((max(src12, 0)), float4(0.18089123, -0.30784377, -0.0076884073, -0.2573419)), dot((max(src12, 0)), float4(-0.21195571, 0.0048495876, 0.02632822, -0.06994815)), dot((max(src12, 0)), float4(-0.12346183, 0.06013008, -0.0011575016, 0.32497165))) + (result);
	result = float4(dot((max(src20, 0)), float4(0.0016823286, -0.0057915323, -0.15560333, 0.0048869387)), dot((max(src20, 0)), float4(-0.014366541, -0.0030526456, -0.053708192, 0.027514834)), dot((max(src20, 0)), float4(-0.5049525, -0.028976317, -0.055678204, 0.017380254)), dot((max(src20, 0)), float4(0.048534572, -0.16376147, -0.13087665, -0.06743363))) + (result);
	result = float4(dot((max(src21, 0)), float4(0.044514824, 0.114894986, 0.03552732, 0.15751484)), dot((max(src21, 0)), float4(-0.1754644, 0.061640915, 0.2835473, 0.41759813)), dot((max(src21, 0)), float4(-0.26664957, -0.13305616, 0.13800526, -0.19406971)), dot((max(src21, 0)), float4(0.1486667, 0.06450565, 0.005875215, 0.071032055))) + (result);
	result = float4(dot((max(src22, 0)), float4(-0.18419577, 0.15775396, 0.064170234, 0.2421206)), dot((max(src22, 0)), float4(-0.05527526, -0.01188916, -0.017833546, 0.15719843)), dot((max(src22, 0)), float4(0.017057603, 0.09368113, 0.12100514, 0.23718071)), dot((max(src22, 0)), float4(-0.1146602, 0.05765405, -0.06250493, 0.023142194))) + (result);
	result = float4(dot((max(-src00, 0)), float4(0.079226464, 0.14683898, -0.13223173, 0.163642)), dot((max(-src00, 0)), float4(0.07877355, 0.028739132, 0.21732429, -0.07062695)), dot((max(-src00, 0)), float4(-0.022315226, -0.24479519, -0.1546993, 0.03805918)), dot((max(-src00, 0)), float4(-0.13507473, -0.280197, 0.045442928, 0.060860883))) + (result);
	result = float4(dot((max(-src01, 0)), float4(0.095216066, 0.3064775, -0.005434017, 0.05558232)), dot((max(-src01, 0)), float4(-0.16650215, -0.034196265, 0.26308087, -0.014217521)), dot((max(-src01, 0)), float4(-0.34863555, -0.25773287, 0.009404902, 0.03667355)), dot((max(-src01, 0)), float4(-0.025274571, 0.19570488, -0.24736062, -0.15134114))) + (result);
	result = float4(dot((max(-src02, 0)), float4(-0.074846864, -0.36042807, 0.105860665, 0.14132085)), dot((max(-src02, 0)), float4(0.010901994, -0.011231913, -0.11587906, 0.021570992)), dot((max(-src02, 0)), float4(0.035149742, 1.4317516, -0.11065066, -0.3618735)), dot((max(-src02, 0)), float4(0.12106729, 0.6400351, 0.19126756, -0.081163004))) + (result);
	result = float4(dot((max(-src10, 0)), float4(-0.06937371, -0.09472515, -0.15207845, 0.14311226)), dot((max(-src10, 0)), float4(0.3815214, -0.027198657, -0.15054241, 0.07640166)), dot((max(-src10, 0)), float4(0.026842717, -0.16502109, -0.25099036, 0.47051275)), dot((max(-src10, 0)), float4(-0.04051589, 0.114273794, -0.10871029, 0.0447809))) + (result);
	result = float4(dot((max(-src11, 0)), float4(-0.25960425, -0.29595324, 0.26789796, 0.019582301)), dot((max(-src11, 0)), float4(0.11150338, -0.0149574205, 0.41416678, -0.118703716)), dot((max(-src11, 0)), float4(-0.042022616, 0.09806478, 0.05145585, 0.13974573)), dot((max(-src11, 0)), float4(-0.006633396, 0.03635802, 0.61168057, 0.04498941))) + (result);
	result = float4(dot((max(-src12, 0)), float4(-0.04119621, -0.06258357, 0.004379942, -0.2476702)), dot((max(-src12, 0)), float4(-0.15503803, 0.2574262, 0.097908296, 0.13828708)), dot((max(-src12, 0)), float4(0.33170196, -0.07890287, 0.009286624, 0.05071857)), dot((max(-src12, 0)), float4(-0.1158483, -0.6929032, 0.27194506, -0.43693772))) + (result);
	result = float4(dot((max(-src20, 0)), float4(-0.010842703, 0.018797455, 0.09975456, -0.04871634)), dot((max(-src20, 0)), float4(0.13108006, 0.0614624, 0.04676902, -0.089208096)), dot((max(-src20, 0)), float4(0.30126816, 0.11102966, -0.044540443, 0.027455999)), dot((max(-src20, 0)), float4(0.20221521, 0.019204421, 0.118877, 0.029557817))) + (result);
	result = float4(dot((max(-src21, 0)), float4(-0.10421777, 0.0034963787, 0.06574797, -0.3374016)), dot((max(-src21, 0)), float4(0.3135469, -0.20342828, -0.14168271, -0.4360316)), dot((max(-src21, 0)), float4(0.14557797, 0.08332032, -0.08754358, 0.15854433)), dot((max(-src21, 0)), float4(0.0497297, -0.09004643, 0.30385306, -0.24081887))) + (result);
	result = float4(dot((max(-src22, 0)), float4(0.1407836, 0.012281648, 0.042200714, -0.34656256)), dot((max(-src22, 0)), float4(0.09678823, -0.24124922, -0.21701157, -0.034729004)), dot((max(-src22, 0)), float4(-0.02240152, -0.46433777, -0.016618999, -0.29246503)), dot((max(-src22, 0)), float4(-0.013985894, -0.25915003, 0.13135725, -0.13514486))) + (result);
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
	float4 result = float4( 0.0061747693, -0.029145364, -0.026801255, 0.027419873 );
	result = float4(dot((max(src00, 0)), float4(0.27743992, 0.006292013, -0.03186617, 0.130609)), dot((max(src00, 0)), float4(0.04277345, 0.19800001, -0.060173523, -0.068515256)), dot((max(src00, 0)), float4(0.019331178, -0.0025032016, 0.08878855, -0.03571823)), dot((max(src00, 0)), float4(-0.7335445, 0.16098699, -0.10669283, -0.13751523))) + (result);
	result = float4(dot((max(src01, 0)), float4(-0.2430821, -0.18989052, -0.13517766, -0.045706213)), dot((max(src01, 0)), float4(-0.08233978, -0.041925047, 0.032255337, -0.12841983)), dot((max(src01, 0)), float4(0.082374334, 0.40021122, -0.0746507, -0.27830583)), dot((max(src01, 0)), float4(0.04843392, -0.317836, 0.22114721, 0.05763077))) + (result);
	result = float4(dot((max(src02, 0)), float4(-0.08436965, -0.17429228, -0.07667423, 0.085659124)), dot((max(src02, 0)), float4(-0.04967552, -0.10166739, 0.04985163, -0.078792974)), dot((max(src02, 0)), float4(-0.16798134, 0.35864773, 0.13391761, 0.06481059)), dot((max(src02, 0)), float4(-0.1539139, 0.12873615, -0.054322604, 0.058667548))) + (result);
	result = float4(dot((max(src10, 0)), float4(-0.17568155, 0.005879628, -0.14527243, 0.055053137)), dot((max(src10, 0)), float4(0.56705236, -0.2502103, 0.16983634, 0.10699275)), dot((max(src10, 0)), float4(0.056562193, -0.19619654, 0.049245857, 0.0016993808)), dot((max(src10, 0)), float4(-0.020951264, 0.019490348, 0.18316677, 0.20105995))) + (result);
	result = float4(dot((max(src11, 0)), float4(0.36284775, -0.15698905, 0.04317283, -0.1782944)), dot((max(src11, 0)), float4(-0.05856962, -0.28837132, 0.024557106, 0.43094924)), dot((max(src11, 0)), float4(-0.42545465, -0.028697362, -0.052158598, -0.11738149)), dot((max(src11, 0)), float4(0.31931567, -0.024917847, 0.38654143, 0.21554618))) + (result);
	result = float4(dot((max(src12, 0)), float4(0.22645079, -0.05167819, 0.08027872, -0.24527508)), dot((max(src12, 0)), float4(-0.20319854, -0.12845007, -0.0628224, 0.23632833)), dot((max(src12, 0)), float4(0.20733371, 0.5543688, -0.06593836, -0.043366548)), dot((max(src12, 0)), float4(-0.18697177, 0.2453291, -0.05795855, 0.14135826))) + (result);
	result = float4(dot((max(src20, 0)), float4(0.08384414, -0.07641805, 0.093737304, -0.07255943)), dot((max(src20, 0)), float4(0.20807321, -0.10919174, -0.17856954, -0.02331535)), dot((max(src20, 0)), float4(0.030559694, -0.19799095, 0.035103753, 0.2059249)), dot((max(src20, 0)), float4(-0.13640808, -0.12955745, -0.044699315, 0.3058302))) + (result);
	result = float4(dot((max(src21, 0)), float4(0.022345139, -0.0014384583, 0.07038578, -0.34799108)), dot((max(src21, 0)), float4(0.16286038, 0.089546144, -0.030679917, -0.0405689)), dot((max(src21, 0)), float4(-0.27228013, -0.08296848, 0.031246305, -0.19182852)), dot((max(src21, 0)), float4(-0.41105714, -0.0050463285, 0.36761853, 0.015853593))) + (result);
	result = float4(dot((max(src22, 0)), float4(0.1021783, 0.042015605, 0.15276712, -0.04858846)), dot((max(src22, 0)), float4(-0.11396049, -0.14808236, -0.07807765, 0.066066965)), dot((max(src22, 0)), float4(-0.08733628, 0.10072531, -0.10013386, 0.13598624)), dot((max(src22, 0)), float4(-0.017449526, -0.07403295, -0.26110634, 0.21687816))) + (result);
	result = float4(dot((max(-src00, 0)), float4(0.07041569, -0.06569677, -0.20729817, 0.09107114)), dot((max(-src00, 0)), float4(-0.17775945, -0.033233996, 0.1316505, -0.13078825)), dot((max(-src00, 0)), float4(0.15697548, 0.22596005, -0.058410037, -0.05639485)), dot((max(-src00, 0)), float4(-0.15425202, -0.026170855, 0.22166035, -0.02716142))) + (result);
	result = float4(dot((max(-src01, 0)), float4(0.057966787, 0.082777694, 0.102710955, 0.031709857)), dot((max(-src01, 0)), float4(-0.15311252, -0.08471956, 0.21808124, 0.13955092)), dot((max(-src01, 0)), float4(0.095924966, -0.39918202, 0.12083635, 0.12647778)), dot((max(-src01, 0)), float4(-0.055951685, 0.10599212, -0.38835892, 0.011549966))) + (result);
	result = float4(dot((max(-src02, 0)), float4(0.09810508, 0.036198203, -0.12622337, 0.047094557)), dot((max(-src02, 0)), float4(-0.119743295, -0.028710455, 0.14379597, -0.07987105)), dot((max(-src02, 0)), float4(0.06166254, -0.40789905, 0.039958883, -0.04905092)), dot((max(-src02, 0)), float4(0.13595435, -0.034894038, 0.19636424, -0.07875785))) + (result);
	result = float4(dot((max(-src10, 0)), float4(0.34118712, -0.01961924, 0.18604252, 0.11422739)), dot((max(-src10, 0)), float4(-0.2833933, 0.37131935, -0.0037280058, -0.16490164)), dot((max(-src10, 0)), float4(-0.045028314, 0.29099533, 0.1091072, -0.0022396361)), dot((max(-src10, 0)), float4(-0.40670308, -0.19843055, -0.40579233, -0.21486944))) + (result);
	result = float4(dot((max(-src11, 0)), float4(0.0010853866, 0.2549397, -0.43552014, -0.26955804)), dot((max(-src11, 0)), float4(0.2223109, 0.6442047, -0.1793875, -0.071371995)), dot((max(-src11, 0)), float4(0.2416471, 0.18411863, -0.58699155, 0.07599079)), dot((max(-src11, 0)), float4(-0.33326814, -0.19081281, -0.01900168, 0.27434483))) + (result);
	result = float4(dot((max(-src12, 0)), float4(-0.19644544, -0.16369823, -0.2040159, 0.17536888)), dot((max(-src12, 0)), float4(0.14383379, 0.009537702, 0.01522431, -0.012183123)), dot((max(-src12, 0)), float4(-0.2599538, -0.3690974, -0.11007749, -0.17366478)), dot((max(-src12, 0)), float4(0.001666124, -0.048157427, -0.07012568, -0.15090804))) + (result);
	result = float4(dot((max(-src20, 0)), float4(0.0855136, 0.15325847, -0.109522276, -0.16143093)), dot((max(-src20, 0)), float4(0.06863859, 0.22742507, 0.24135293, 0.1358853)), dot((max(-src20, 0)), float4(-0.17249937, 0.22535504, -0.17784368, -0.09399085)), dot((max(-src20, 0)), float4(-0.12850079, 0.24032994, 0.08172238, 0.012180792))) + (result);
	result = float4(dot((max(-src21, 0)), float4(-0.04346881, -0.10315795, -0.09032907, 0.17246644)), dot((max(-src21, 0)), float4(0.13367178, 0.5816371, -0.52505773, 0.011886279)), dot((max(-src21, 0)), float4(0.10387612, -0.090529, 0.10958755, 0.3566306)), dot((max(-src21, 0)), float4(0.04705543, -0.017955385, -0.26151448, 0.32170597))) + (result);
	result = float4(dot((max(-src22, 0)), float4(-0.27853554, -0.31982365, 0.10514691, 0.16719124)), dot((max(-src22, 0)), float4(0.1558035, 0.29085326, -0.24606484, 0.013080999)), dot((max(-src22, 0)), float4(0.070289604, -0.09494764, -0.02049181, -0.08577963)), dot((max(-src22, 0)), float4(0.17052644, 0.2270542, 0.126686, -0.07057233))) + (result);
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
	float4 result = float4( 0.022887055, 0.01521631, 0.17967467, -0.0131908795 );
	result = float4(dot((max(src00, 0)), float4(0.07447851, -0.065199964, -0.03523585, -0.116270036)), dot((max(src00, 0)), float4(-0.07888509, 0.24733023, -0.03547245, -0.065133184)), dot((max(src00, 0)), float4(-0.28236163, 0.099619575, -0.10619345, -0.30401528)), dot((max(src00, 0)), float4(0.2479792, -0.26430824, -0.25326422, 0.01563764))) + (result);
	result = float4(dot((max(src01, 0)), float4(-0.19106275, 0.24148639, 0.13287601, -0.13132331)), dot((max(src01, 0)), float4(-0.26104823, -0.10950928, 0.06975747, -0.16468687)), dot((max(src01, 0)), float4(-0.14457102, 0.062851585, 0.15848075, -0.029844414)), dot((max(src01, 0)), float4(-0.17298317, 0.042540826, -0.3854902, 0.27754608))) + (result);
	result = float4(dot((max(src02, 0)), float4(0.015378025, -0.074871175, -0.16522385, -0.2509982)), dot((max(src02, 0)), float4(-0.14203559, -0.26611313, -0.23424402, -0.0554576)), dot((max(src02, 0)), float4(0.08058816, -0.18830848, -0.12279703, 0.07286022)), dot((max(src02, 0)), float4(0.32896644, 0.091641426, -0.13343342, -0.028823337))) + (result);
	result = float4(dot((max(src10, 0)), float4(-0.13543738, -0.12827122, 0.12442749, -0.010479037)), dot((max(src10, 0)), float4(0.049395677, -0.012590744, 0.3497426, 0.07037434)), dot((max(src10, 0)), float4(-0.015148539, 0.012936948, -0.16126058, -0.15527055)), dot((max(src10, 0)), float4(0.13301241, 0.008271658, -0.2670464, 0.13205245))) + (result);
	result = float4(dot((max(src11, 0)), float4(-0.09535385, 0.14652656, 0.48615915, -0.40927815)), dot((max(src11, 0)), float4(-0.3931354, 0.38149378, 0.32634613, -0.05268087)), dot((max(src11, 0)), float4(0.24716614, -0.09607391, 0.146291, -0.04110691)), dot((max(src11, 0)), float4(-0.21284536, 0.06350967, 0.2566475, -0.0068722935))) + (result);
	result = float4(dot((max(src12, 0)), float4(0.089152284, 0.022529159, 0.1524636, -0.38435504)), dot((max(src12, 0)), float4(-0.01860622, -0.0071319416, 0.21627748, -0.08842507)), dot((max(src12, 0)), float4(0.016856732, -0.09786801, -0.07395979, -0.0058702417)), dot((max(src12, 0)), float4(0.31244752, -0.13005258, -0.087633945, -0.32936293))) + (result);
	result = float4(dot((max(src20, 0)), float4(0.0816838, 0.0014665248, -0.032501306, -0.23052917)), dot((max(src20, 0)), float4(0.0012210817, -0.0636269, -0.22908778, 0.26728114)), dot((max(src20, 0)), float4(0.28217188, 0.042035818, -0.2067977, 0.15353456)), dot((max(src20, 0)), float4(0.36141106, -0.056671552, -0.004497514, -0.17732324))) + (result);
	result = float4(dot((max(src21, 0)), float4(-0.17229734, -0.14819005, -0.12653661, -0.15346588)), dot((max(src21, 0)), float4(0.0818218, -0.085340135, -0.036583595, 0.20005536)), dot((max(src21, 0)), float4(-0.10076918, 0.050100215, -0.32319903, 0.23097478)), dot((max(src21, 0)), float4(0.030027041, 0.05683199, -0.15273796, -0.19834782))) + (result);
	result = float4(dot((max(src22, 0)), float4(0.055430107, -0.084407054, -0.014879812, -0.01091196)), dot((max(src22, 0)), float4(-0.2886931, 0.06254009, 0.112346604, -0.062669374)), dot((max(src22, 0)), float4(0.361814, -0.02332793, -0.20686437, 0.085567676)), dot((max(src22, 0)), float4(0.33160287, -0.018134018, -0.23408228, 0.23738655))) + (result);
	result = float4(dot((max(-src00, 0)), float4(0.080383554, -0.07559937, 0.2034805, 0.113631405)), dot((max(-src00, 0)), float4(-0.1172084, -0.25445858, 0.33716002, -0.0058444734)), dot((max(-src00, 0)), float4(0.19703126, 0.3450109, 0.15314537, 0.2890972)), dot((max(-src00, 0)), float4(0.27777427, -0.071967736, -0.22953224, 0.06557255))) + (result);
	result = float4(dot((max(-src01, 0)), float4(-0.17646056, -0.15238142, -0.011660059, -0.06558679)), dot((max(-src01, 0)), float4(-0.025448758, 0.1435677, -0.003515217, -0.032662887)), dot((max(-src01, 0)), float4(-0.14952567, 0.20273875, -0.17305166, -0.20914736)), dot((max(-src01, 0)), float4(0.017148364, 0.22255951, -0.13478355, -0.5397283))) + (result);
	result = float4(dot((max(-src02, 0)), float4(0.1679393, -0.06457877, 0.046539318, 0.22196163)), dot((max(-src02, 0)), float4(-0.109410115, -0.06607065, -0.020642165, -0.2187166)), dot((max(-src02, 0)), float4(-0.117427185, 0.0018200208, -0.14413542, -0.10759705)), dot((max(-src02, 0)), float4(0.14982319, -0.0118605625, -0.09530688, 0.013234591))) + (result);
	result = float4(dot((max(-src10, 0)), float4(-0.13220267, 0.16204996, 0.059764992, -0.06542371)), dot((max(-src10, 0)), float4(-0.12540027, -0.4023048, 0.048170995, -0.10791867)), dot((max(-src10, 0)), float4(0.26163217, -0.13485721, -0.25281772, -0.21286209)), dot((max(-src10, 0)), float4(0.12791659, -0.10187536, 0.2090587, -0.309109))) + (result);
	result = float4(dot((max(-src11, 0)), float4(0.16233061, -0.2670459, -0.2343609, 0.6009884)), dot((max(-src11, 0)), float4(0.120428756, -0.24195078, -0.22543164, 0.39171818)), dot((max(-src11, 0)), float4(-0.11460241, -0.20964348, -0.28909695, -0.1276308)), dot((max(-src11, 0)), float4(0.24531102, -0.12930301, -0.33560297, -0.020736236))) + (result);
	result = float4(dot((max(-src12, 0)), float4(0.40162864, -0.17351128, -0.025815086, 0.34386298)), dot((max(-src12, 0)), float4(0.045881115, -0.009387306, -0.10390133, 0.23177734)), dot((max(-src12, 0)), float4(0.032667033, 0.17341217, 0.012544771, -0.046727546)), dot((max(-src12, 0)), float4(0.31454235, 0.30810982, 0.036918722, 0.20098232))) + (result);
	result = float4(dot((max(-src20, 0)), float4(0.11541034, -0.13921295, 0.0035326157, 0.17358719)), dot((max(-src20, 0)), float4(-0.11647824, -0.25733355, 0.3782048, -0.2789715)), dot((max(-src20, 0)), float4(-0.12874861, -0.1112383, 0.055785846, -0.13400431)), dot((max(-src20, 0)), float4(0.004921287, -0.033295818, -0.1547331, 0.1583795))) + (result);
	result = float4(dot((max(-src21, 0)), float4(0.4130191, -0.11483455, 0.14681247, 0.088704996)), dot((max(-src21, 0)), float4(-0.33944547, -0.022601767, 0.34442267, -0.20943391)), dot((max(-src21, 0)), float4(-0.064674884, 0.1129301, 0.08721343, -0.2891408)), dot((max(-src21, 0)), float4(0.39617148, -0.09713594, -0.08309499, 0.1709401))) + (result);
	result = float4(dot((max(-src22, 0)), float4(0.19503653, 0.04479765, 0.23314747, -0.11194509)), dot((max(-src22, 0)), float4(0.17490312, -0.0334551, 0.21557438, 0.0736583)), dot((max(-src22, 0)), float4(-0.23491044, 0.0602648, 0.07273092, -0.17628083)), dot((max(-src22, 0)), float4(-0.028934423, 0.0019939998, 0.15467109, -0.3851578))) + (result);
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
	float4 result = float4( 0.049844168, 0.02670437, 0.050967637, -0.10779561 );
	result = float4(dot((max(src00, 0)), float4(-0.10233342, 0.14248851, 0.10996857, 0.07579955)), dot((max(src00, 0)), float4(-0.30233157, 0.08486557, -0.17286511, -0.16861476)), dot((max(src00, 0)), float4(0.24238978, 0.0028373515, 0.19819227, -0.210025)), dot((max(src00, 0)), float4(-0.007108631, 0.122387215, 0.07023527, 0.12760942))) + (result);
	result = float4(dot((max(src01, 0)), float4(0.091181986, -0.12210428, 0.049019493, -0.15278774)), dot((max(src01, 0)), float4(-0.41497424, 0.20617811, -0.18990634, -0.18331046)), dot((max(src01, 0)), float4(-0.27567792, -0.017644284, 0.11057753, -0.1837594)), dot((max(src01, 0)), float4(-0.09938067, -0.22552875, -0.043193225, 0.029758787))) + (result);
	result = float4(dot((max(src02, 0)), float4(-0.1757096, -0.1701244, 0.13464944, 0.08302458)), dot((max(src02, 0)), float4(-0.199691, -0.0459655, 0.37202564, 0.20696343)), dot((max(src02, 0)), float4(-0.034743477, 0.10508695, 0.14706515, -0.13935481)), dot((max(src02, 0)), float4(-0.15369363, -0.09795581, 0.23416734, 0.03092827))) + (result);
	result = float4(dot((max(src10, 0)), float4(-0.49887478, -0.15019977, 0.12314376, -0.26263535)), dot((max(src10, 0)), float4(0.24046332, 0.31086043, 0.11594825, -0.12739435)), dot((max(src10, 0)), float4(-0.029459715, -0.28297687, 0.17682782, -0.57744014)), dot((max(src10, 0)), float4(0.17374687, -0.22239804, 0.09753434, 0.087381124))) + (result);
	result = float4(dot((max(src11, 0)), float4(0.08101439, -0.44051018, -0.08817581, 0.17742544)), dot((max(src11, 0)), float4(-0.16185337, -0.70680356, -0.057614524, -0.49583626)), dot((max(src11, 0)), float4(0.112901986, -0.23015513, 0.15352182, -0.3844133)), dot((max(src11, 0)), float4(0.24439482, 0.63106006, -0.049620207, 0.18385352))) + (result);
	result = float4(dot((max(src12, 0)), float4(0.17149475, -0.11856372, 0.040755365, 0.056921627)), dot((max(src12, 0)), float4(0.31255633, -0.032373343, -0.027614031, -0.27068445)), dot((max(src12, 0)), float4(0.19286609, 0.06503625, -0.33330554, 0.047014963)), dot((max(src12, 0)), float4(0.21052869, -0.31664965, 0.40148625, 0.103712596))) + (result);
	result = float4(dot((max(src20, 0)), float4(-0.09326643, -0.10685094, -0.10971212, 0.015513338)), dot((max(src20, 0)), float4(0.13677256, 0.124757454, 0.01655797, -0.1917502)), dot((max(src20, 0)), float4(0.06390537, 0.14696303, -0.11052674, -0.26384255)), dot((max(src20, 0)), float4(0.08080093, 0.10871933, -0.17361104, -0.022672707))) + (result);
	result = float4(dot((max(src21, 0)), float4(0.032367155, 0.2627859, -0.4146471, 0.5724947)), dot((max(src21, 0)), float4(-0.087523445, 0.14933161, -0.2530298, 0.25498095)), dot((max(src21, 0)), float4(-0.06951093, 0.3114999, -0.43175155, 0.4838959)), dot((max(src21, 0)), float4(-0.08128242, -0.007791172, -0.06878434, 0.15076154))) + (result);
	result = float4(dot((max(src22, 0)), float4(-0.13427481, 0.15421022, -0.33318612, 0.17408857)), dot((max(src22, 0)), float4(-0.10134261, 0.20205952, -0.17467582, -0.099393494)), dot((max(src22, 0)), float4(0.087439895, 0.22928835, -0.04758165, -0.06389948)), dot((max(src22, 0)), float4(0.015921364, -0.07339068, 0.11858059, -0.06494366))) + (result);
	result = float4(dot((max(-src00, 0)), float4(0.15349221, -0.22561033, -0.024723593, -0.100530736)), dot((max(-src00, 0)), float4(0.08508258, -0.15088828, 0.06610271, 0.16394953)), dot((max(-src00, 0)), float4(-0.09294437, -0.020105945, -0.24423431, 0.16365045)), dot((max(-src00, 0)), float4(-0.03204993, 0.10041996, -0.050512858, -0.012055956))) + (result);
	result = float4(dot((max(-src01, 0)), float4(0.16342951, 0.052211206, -0.054481823, 0.093877845)), dot((max(-src01, 0)), float4(0.23113559, -0.17983536, 0.17506577, 0.05161232)), dot((max(-src01, 0)), float4(0.21289586, -0.008415342, -0.14162593, -0.25006327)), dot((max(-src01, 0)), float4(0.28391558, 0.08977486, -0.070448756, 0.007014646))) + (result);
	result = float4(dot((max(-src02, 0)), float4(0.104965575, 0.19958296, -0.0563495, 0.0067657093)), dot((max(-src02, 0)), float4(0.20048036, -0.05165447, -0.19757621, -0.17784451)), dot((max(-src02, 0)), float4(0.024134496, 0.076928124, 0.10801544, -0.03134409)), dot((max(-src02, 0)), float4(0.5442797, 0.030868227, -0.24202053, -0.06741009))) + (result);
	result = float4(dot((max(-src10, 0)), float4(0.33347723, 0.059872203, -0.21861015, 0.0911101)), dot((max(-src10, 0)), float4(-0.12338564, 0.028045453, -0.030451605, 0.054191053)), dot((max(-src10, 0)), float4(0.23495969, -0.06781438, -0.04267672, -0.08498816)), dot((max(-src10, 0)), float4(-0.23091966, 0.111325614, -0.0039260075, 0.04810343))) + (result);
	result = float4(dot((max(-src11, 0)), float4(-0.05028896, 0.19178568, 0.37980273, -0.00088428083)), dot((max(-src11, 0)), float4(0.21515386, 0.779363, 0.063021325, 0.29736623)), dot((max(-src11, 0)), float4(0.16005337, -0.12682606, 0.19370794, 0.24649377)), dot((max(-src11, 0)), float4(-0.32279232, -0.4378189, -0.05618088, -0.0021625878))) + (result);
	result = float4(dot((max(-src12, 0)), float4(-0.45007992, 0.070867635, -0.27786884, 0.21208113)), dot((max(-src12, 0)), float4(-0.16040307, 0.21317895, -0.33259448, 0.19740848)), dot((max(-src12, 0)), float4(-0.1714593, -0.070962, -0.022767346, 0.16877973)), dot((max(-src12, 0)), float4(-0.16251564, 0.17147541, -0.17967366, 0.09630738))) + (result);
	result = float4(dot((max(-src20, 0)), float4(0.09235827, -0.08311695, -0.03739786, 0.17408027)), dot((max(-src20, 0)), float4(-0.35231477, 0.054329164, -0.1678283, 0.07699043)), dot((max(-src20, 0)), float4(-0.093315996, 0.17788444, 0.12676615, 0.095501214)), dot((max(-src20, 0)), float4(-0.035850406, -0.020736141, 0.17182353, 0.0069830767))) + (result);
	result = float4(dot((max(-src21, 0)), float4(-0.16631392, -0.20530944, 0.2240653, -0.10026419)), dot((max(-src21, 0)), float4(-0.16925642, 0.19215193, 0.100644305, -0.14864013)), dot((max(-src21, 0)), float4(-0.17081848, -0.039511178, 0.2901835, -0.19926691)), dot((max(-src21, 0)), float4(0.017719474, -0.08296625, 0.32166973, -0.11607018))) + (result);
	result = float4(dot((max(-src22, 0)), float4(-0.13750182, -0.03903257, 0.27182797, -0.14405386)), dot((max(-src22, 0)), float4(0.07445518, -0.054933593, 0.07721309, 0.046106674)), dot((max(-src22, 0)), float4(-0.033964884, 0.06765632, -0.0334218, 0.16596143)), dot((max(-src22, 0)), float4(-0.085812084, 0.064338475, -0.19344835, 0.0879945))) + (result);
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
	float4 result = float4( -0.037546165, -0.015675364, 0.13989694, 0.027605768 );
	result = float4(dot((max(src00, 0)), float4(0.034357008, 0.26684088, 0.21509308, 0.16107765)), dot((max(src00, 0)), float4(0.00082413113, -0.31363875, -0.07118628, 0.17146803)), dot((max(src00, 0)), float4(-0.13382089, 0.073608615, 0.11287014, -0.13836654)), dot((max(src00, 0)), float4(-0.05066409, 0.20824149, -0.09817389, -0.05962866))) + (result);
	result = float4(dot((max(src01, 0)), float4(0.029981667, 0.041752994, -0.0033609737, 0.17181319)), dot((max(src01, 0)), float4(0.08738892, -0.20031185, -0.42522693, 0.13097888)), dot((max(src01, 0)), float4(0.17735903, 0.064203605, 0.058846988, -0.059532285)), dot((max(src01, 0)), float4(0.15817277, 0.48786053, 0.22180536, 0.062227458))) + (result);
	result = float4(dot((max(src02, 0)), float4(0.13188283, -0.12815465, -0.14369671, 0.14936846)), dot((max(src02, 0)), float4(0.07971828, 0.29860008, 0.12457525, 0.1284789)), dot((max(src02, 0)), float4(0.28278515, -0.2785862, 0.11982623, -0.0042489986)), dot((max(src02, 0)), float4(0.038570832, -0.07612298, -0.018675303, 0.042810377))) + (result);
	result = float4(dot((max(src10, 0)), float4(0.2892425, -0.16300741, -0.036296643, -0.03553075)), dot((max(src10, 0)), float4(-0.20834558, 0.15674856, -0.052267153, -0.20343691)), dot((max(src10, 0)), float4(0.07358541, -0.04297203, -0.22889943, -0.07413655)), dot((max(src10, 0)), float4(-0.11190968, -0.29218298, -0.21203549, -0.092966415))) + (result);
	result = float4(dot((max(src11, 0)), float4(0.2484468, 0.5047224, 0.023935676, -0.26183444)), dot((max(src11, 0)), float4(-0.23412868, -0.48216155, -0.040435325, 0.14510648)), dot((max(src11, 0)), float4(-0.070199326, -0.5792768, -0.1238493, 0.5365255)), dot((max(src11, 0)), float4(0.2061922, 0.610787, -0.09576053, 0.5499143))) + (result);
	result = float4(dot((max(src12, 0)), float4(-0.058255754, 0.26006857, -0.0396066, -0.19703479)), dot((max(src12, 0)), float4(0.08133753, -0.007619795, 0.2821596, 0.17809318)), dot((max(src12, 0)), float4(-0.18663554, 0.14585225, 0.31778112, 0.21089044)), dot((max(src12, 0)), float4(0.26190025, 0.073580734, -0.029853562, -0.106730856))) + (result);
	result = float4(dot((max(src20, 0)), float4(0.20549655, -0.19064854, -0.1456842, -0.083257)), dot((max(src20, 0)), float4(-0.05962688, 0.061387196, 0.18950678, -0.2937246)), dot((max(src20, 0)), float4(0.1432124, 0.1792527, -0.13990986, 0.032096215)), dot((max(src20, 0)), float4(0.013446325, 0.0010619498, -0.37644413, 0.14719158))) + (result);
	result = float4(dot((max(src21, 0)), float4(-0.26601696, 0.026037043, -0.030869482, -0.25404635)), dot((max(src21, 0)), float4(0.4242341, -0.0117916465, -0.045915652, 0.21859063)), dot((max(src21, 0)), float4(-0.073702715, -0.024286825, -0.040611852, 0.13869432)), dot((max(src21, 0)), float4(-0.3221337, 0.23183465, 0.11372697, 0.19651218))) + (result);
	result = float4(dot((max(src22, 0)), float4(-0.028276298, 0.11032058, 0.08758557, -0.029466914)), dot((max(src22, 0)), float4(-0.11217159, -0.09957206, -0.11042305, -0.041135952)), dot((max(src22, 0)), float4(0.27144867, 0.12570262, 0.025948172, -0.017091949)), dot((max(src22, 0)), float4(-0.010531775, 0.14724332, -0.010910802, 0.05501236))) + (result);
	result = float4(dot((max(-src00, 0)), float4(-0.12688768, -0.16320245, 0.2103894, -0.1763831)), dot((max(-src00, 0)), float4(-0.19051413, -0.1601866, -0.06212745, 0.13890013)), dot((max(-src00, 0)), float4(0.052141912, 0.16207355, -0.07042835, -0.12125462)), dot((max(-src00, 0)), float4(-0.13618521, -0.023218745, 0.0996637, -0.105104685))) + (result);
	result = float4(dot((max(-src01, 0)), float4(0.10485512, -0.17389494, 0.006298799, -0.08088888)), dot((max(-src01, 0)), float4(-0.49283037, -0.12835866, -0.0348454, 0.35675287)), dot((max(-src01, 0)), float4(-0.504295, 0.14188384, -0.0852419, 0.16014415)), dot((max(-src01, 0)), float4(0.009089699, -0.22946316, 0.17956656, -0.055372503))) + (result);
	result = float4(dot((max(-src02, 0)), float4(-0.17157564, -0.13708206, 0.08100986, 0.1040296)), dot((max(-src02, 0)), float4(0.1557075, 0.101721555, -0.23204406, -0.045591615)), dot((max(-src02, 0)), float4(-0.17681694, 0.17070566, -0.38926315, 0.15745829)), dot((max(-src02, 0)), float4(0.14834762, -0.22522852, -0.13165781, -0.10410621))) + (result);
	result = float4(dot((max(-src10, 0)), float4(-0.20517144, -0.016253468, -0.20261237, 0.52166605)), dot((max(-src10, 0)), float4(0.35896194, 0.035292216, -0.28905126, -0.0996688)), dot((max(-src10, 0)), float4(-0.0010962893, 0.06781499, 0.007414641, -0.23151648)), dot((max(-src10, 0)), float4(-0.18043008, 0.015984116, 0.008870292, 0.2811893))) + (result);
	result = float4(dot((max(-src11, 0)), float4(0.013482173, -0.00087873987, -0.1476981, -0.27173743)), dot((max(-src11, 0)), float4(-0.04891998, 0.11979091, 0.2634587, 0.7530214)), dot((max(-src11, 0)), float4(-0.06094191, 0.06457245, -0.058895197, 0.037599873)), dot((max(-src11, 0)), float4(-0.14416319, -0.2305623, -0.07394766, 0.22086331))) + (result);
	result = float4(dot((max(-src12, 0)), float4(-0.10357755, -0.019786308, 0.28971127, -0.15574701)), dot((max(-src12, 0)), float4(0.23899554, -0.085470654, 0.24527478, 0.10968643)), dot((max(-src12, 0)), float4(0.034912035, -0.03096524, -0.19110362, -0.13727877)), dot((max(-src12, 0)), float4(-0.14336212, 0.108783185, -0.49510127, 0.04502924))) + (result);
	result = float4(dot((max(-src20, 0)), float4(-0.10808282, -0.0062175165, 0.26899642, -0.13381268)), dot((max(-src20, 0)), float4(-0.079148844, 0.1303082, -0.16624425, 0.03408099)), dot((max(-src20, 0)), float4(-0.3244773, 0.012592612, -0.04438198, -0.2999706)), dot((max(-src20, 0)), float4(-0.2210664, -0.38039228, 0.42067865, -0.3817641))) + (result);
	result = float4(dot((max(-src21, 0)), float4(0.030872926, -0.19185568, 0.44865233, 0.2542566)), dot((max(-src21, 0)), float4(-0.26852018, -0.06341456, 0.21416639, -0.23348318)), dot((max(-src21, 0)), float4(-0.14650428, 0.12261606, 0.40359476, -0.43142912)), dot((max(-src21, 0)), float4(0.16869825, -0.26597574, 0.12814924, -0.35113996))) + (result);
	result = float4(dot((max(-src22, 0)), float4(-0.03364283, -0.10348537, 0.040704627, 0.063962296)), dot((max(-src22, 0)), float4(0.11002299, 0.13331696, -0.14875266, 0.18420577)), dot((max(-src22, 0)), float4(0.3311268, -0.0793144, -0.09259674, -0.085616685)), dot((max(-src22, 0)), float4(-0.14580412, -0.04116661, -0.062087066, -0.16555141))) + (result);
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
	float4 src7 = float4( -0.20554838, -0.10647836, -0.02824578, 0.08658529 );
	src7 = float4(dot((max(a, 0)), float4(-0.35835463, 0.02142098, 0.075116105, 0.12030758)), dot((max(a, 0)), float4(0.038305778, -0.072417736, -0.21191697, -0.17591658)), dot((max(a, 0)), float4(-0.10198824, -0.2577152, -0.1213158, 0.1726511)), dot((max(a, 0)), float4(-0.021951782, 0.054713376, -0.105036296, 0.17754573))) + (src7);
	src7 = float4(dot((max(b, 0)), float4(0.32325825, 0.20716824, 0.37509173, -0.092765376)), dot((max(b, 0)), float4(0.19869742, 0.09557955, -0.031341635, -0.13535516)), dot((max(b, 0)), float4(0.333873, 0.120742686, 0.10247365, 0.8333728)), dot((max(b, 0)), float4(0.39670366, -0.2271023, 0.031520665, 0.05886494))) + (src7);
	src7 = float4(dot((max(c, 0)), float4(-0.17573749, 0.21080776, 0.21946241, -0.49393657)), dot((max(c, 0)), float4(0.16768494, 0.31503728, 0.14559007, -0.5332298)), dot((max(c, 0)), float4(0.021141645, -0.26834, -0.09761235, 0.09806347)), dot((max(c, 0)), float4(0.19668253, 0.19103156, -0.23565038, 0.054431103))) + (src7);
	src7 = float4(dot((max(d, 0)), float4(-0.042109374, 0.007322007, 0.14174329, -0.24542394)), dot((max(d, 0)), float4(-0.05564321, 0.13193823, 0.3898842, -0.13020967)), dot((max(d, 0)), float4(0.27586877, -0.18262729, -0.10398105, -0.16491668)), dot((max(d, 0)), float4(0.010382545, 0.06399193, 0.01846146, -0.03544872))) + (src7);
	src7 = float4(dot((max(e, 0)), float4(-0.15291597, 0.17843612, 0.40330106, -0.19571523)), dot((max(e, 0)), float4(0.1566557, 0.15885495, -0.07991953, 0.3670614)), dot((max(e, 0)), float4(0.14745249, -0.691466, 0.2832403, -0.62296015)), dot((max(e, 0)), float4(-0.23258151, -0.41177312, 0.10656986, -0.5666968))) + (src7);
	src7 = float4(dot((max(f, 0)), float4(-0.17513512, -0.2227142, 0.2632246, 0.23755905)), dot((max(f, 0)), float4(0.011393021, -0.033094753, 0.09945105, -0.506999)), dot((max(f, 0)), float4(-0.44352317, 0.09624524, 0.042561427, 0.114180565)), dot((max(f, 0)), float4(-0.059153114, 0.051315393, -0.1234722, 0.27887583))) + (src7);
	src7 = float4(dot((max(g, 0)), float4(-0.459564, -0.14124362, -0.08515889, 0.31996533)), dot((max(g, 0)), float4(-0.120326266, -0.36653697, 0.18788262, -0.2668834)), dot((max(g, 0)), float4(0.17507194, -0.2856802, 0.23427077, 0.08469808)), dot((max(g, 0)), float4(0.06701153, -0.22955593, 0.021544341, -0.01347926))) + (src7);
	src7 = float4(dot((max(h, 0)), float4(-0.14092083, 0.33119613, -0.11994278, 0.13851176)), dot((max(h, 0)), float4(-0.31244513, -0.011959397, 0.116068155, -0.006655432)), dot((max(h, 0)), float4(-0.044023518, -0.1494438, -0.13032633, -0.39841232)), dot((max(h, 0)), float4(0.013948701, -0.111066826, -0.037004936, -0.079951204))) + (src7);
	src7 = float4(dot((max(i, 0)), float4(-0.08959123, -0.04361797, 0.044681285, 0.090825416)), dot((max(i, 0)), float4(0.18297827, -0.029816678, 0.04669291, -0.27414632)), dot((max(i, 0)), float4(-0.0763483, -0.19314721, -0.30017474, 0.36355078)), dot((max(i, 0)), float4(0.11364159, -0.03484794, -0.07453036, 0.15742934))) + (src7);
	src7 = float4(dot((max(-a, 0)), float4(0.18470702, 0.12490399, -0.026458051, -0.059242606)), dot((max(-a, 0)), float4(0.113800436, 0.1826781, -0.1693334, 0.039351143)), dot((max(-a, 0)), float4(-0.18546791, -0.01313173, 0.21958382, -0.061676584)), dot((max(-a, 0)), float4(0.044184085, -0.19048993, 0.030458853, -0.06904634))) + (src7);
	src7 = float4(dot((max(-b, 0)), float4(-0.114877924, 0.2409049, -0.22588749, -0.011380872)), dot((max(-b, 0)), float4(-0.03781683, 0.2965285, 0.48505852, -0.018334057)), dot((max(-b, 0)), float4(-0.19207929, -0.38395065, 0.09866521, -0.047188547)), dot((max(-b, 0)), float4(0.007679428, 0.11604976, -0.2585994, 0.3038583))) + (src7);
	src7 = float4(dot((max(-c, 0)), float4(-0.2783936, 0.39725313, 0.2355193, -0.1223885)), dot((max(-c, 0)), float4(-0.17609318, 0.082951784, -0.30003366, 0.40760317)), dot((max(-c, 0)), float4(0.4904369, -0.15595853, -0.27686292, 0.0013726618)), dot((max(-c, 0)), float4(-0.31848624, -0.007526218, 0.120900005, -0.24877374))) + (src7);
	src7 = float4(dot((max(-d, 0)), float4(0.1580051, 0.18895927, 0.2544444, 0.33157274)), dot((max(-d, 0)), float4(-0.044973504, 0.23527777, -0.05932328, -0.09072586)), dot((max(-d, 0)), float4(0.00053594523, -0.18095906, 0.13717431, -0.004386734)), dot((max(-d, 0)), float4(-0.057797022, -0.076961614, -0.024487074, -0.05180953))) + (src7);
	src7 = float4(dot((max(-e, 0)), float4(-0.21685815, 0.26001146, -0.06449239, -0.06683439)), dot((max(-e, 0)), float4(0.061656334, 0.046466008, 0.45951647, -0.47628635)), dot((max(-e, 0)), float4(-0.066127226, -0.047196623, -0.13132116, 0.42461708)), dot((max(-e, 0)), float4(0.24831405, 0.13538954, -0.7079741, 0.6475073))) + (src7);
	src7 = float4(dot((max(-f, 0)), float4(0.2590011, 0.37920526, 0.056119893, -0.35761952)), dot((max(-f, 0)), float4(-0.26020283, 0.29205114, 0.022032745, 0.07582935)), dot((max(-f, 0)), float4(0.0005333198, -0.20281325, -0.30095813, 0.12462687)), dot((max(-f, 0)), float4(0.01555692, -0.1455974, 0.48154855, 0.068093665))) + (src7);
	src7 = float4(dot((max(-g, 0)), float4(0.20434918, 0.037406113, 0.16626422, -0.10172441)), dot((max(-g, 0)), float4(0.26690874, 0.5059272, -0.23407575, -0.11645544)), dot((max(-g, 0)), float4(0.028224666, -0.0047208676, -0.072687164, 0.008715937)), dot((max(-g, 0)), float4(0.042565826, 0.0019095197, 0.00063299487, -0.012423992))) + (src7);
	src7 = float4(dot((max(-h, 0)), float4(0.08269191, 0.09546776, 0.06618616, -0.07191658)), dot((max(-h, 0)), float4(0.116322584, 0.3632936, -0.26862565, -0.20559746)), dot((max(-h, 0)), float4(-0.08155921, -0.08139031, 0.25058737, 0.21857823)), dot((max(-h, 0)), float4(-0.04790326, -0.10399187, 0.0410593, 0.12776822))) + (src7);
	src7 = float4(dot((max(-i, 0)), float4(0.54989135, 0.26107135, -0.19018838, -0.15189888)), dot((max(-i, 0)), float4(0.38051483, 0.2585036, 0.2730626, 0.023638237)), dot((max(-i, 0)), float4(0.015739547, -0.12345306, 0.42644337, 0.11272267)), dot((max(-i, 0)), float4(-0.0068143173, -0.13934542, 0.16693048, 0.039560657))) + (src7);
	float3 result = float3( -0.0039074384, -0.0085585555, -0.0132283475 );
	result = float3(dot((max(src1, 0)), float4(-0.030150581, 0.020940892, 0.111167125, 0.020043287)), dot((max(src1, 0)), float4(-0.002168429, 0.04591048, 0.05311203, 0.04785493)), dot((max(src1, 0)), float4(0.014918388, 0.049137186, 0.0625381, 0.040921766))) + (result);
	result = float3(dot((max(-src1, 0)), float4(0.04158565, 0.049123142, 0.09238876, -0.054776173)), dot((max(-src1, 0)), float4(-0.008488135, -0.055042226, 0.10387972, -0.098954335)), dot((max(-src1, 0)), float4(0.0020472286, -0.06489915, 0.09576964, -0.09018853))) + (result);
	result = float3(dot((max(src2, 0)), float4(0.2081418, -0.09937802, -0.13983749, -0.18937743)), dot((max(src2, 0)), float4(0.08273068, -0.13162258, 0.01309777, -0.07021057)), dot((max(src2, 0)), float4(0.040325668, -0.13989717, 0.0023888077, -0.047152344))) + (result);
	result = float3(dot((max(-src2, 0)), float4(-0.09646629, 0.22579835, 0.049726978, 0.16281025)), dot((max(-src2, 0)), float4(0.080605574, 0.24077554, 0.015292378, 0.048491795)), dot((max(-src2, 0)), float4(0.10463501, 0.22600271, -0.0047161994, 0.038338162))) + (result);
	result = float3(dot((max(src3, 0)), float4(-0.09772107, -0.1257736, -0.015900036, -0.11321135)), dot((max(src3, 0)), float4(-0.043998875, -0.13175423, 0.07074481, -0.12526917)), dot((max(src3, 0)), float4(-0.054745924, -0.10889618, 0.08210496, -0.105605066))) + (result);
	result = float3(dot((max(-src3, 0)), float4(0.14187162, 0.018954534, 0.04762765, 0.11133751)), dot((max(-src3, 0)), float4(0.14032297, 0.016011704, -0.044460997, 0.09464176)), dot((max(-src3, 0)), float4(0.13016908, 0.010169183, -0.06499567, 0.08865274))) + (result);
	result = float3(dot((max(src4, 0)), float4(-0.16567162, -0.02412003, -0.06161098, 0.030736001)), dot((max(src4, 0)), float4(-0.1744712, 0.0074480795, -0.046788957, 0.036460854)), dot((max(src4, 0)), float4(-0.1637222, 0.007903436, -0.03971239, 0.03660504))) + (result);
	result = float3(dot((max(-src4, 0)), float4(0.084027, 0.005087354, 0.10519243, -0.052826345)), dot((max(-src4, 0)), float4(0.10024112, -0.026047802, 0.08977278, -0.06602686)), dot((max(-src4, 0)), float4(0.08152756, -0.027264625, 0.077558964, -0.055083472))) + (result);
	result = float3(dot((max(src5, 0)), float4(0.007862721, -0.042322706, 0.030532641, 0.030569768)), dot((max(src5, 0)), float4(0.009936555, -0.061728776, 0.045623366, 0.011892851)), dot((max(src5, 0)), float4(0.012004831, -0.05359773, 0.04214089, 0.0074041556))) + (result);
	result = float3(dot((max(-src5, 0)), float4(0.03948997, 0.0526772, -0.062081397, -0.004076369)), dot((max(-src5, 0)), float4(0.043119986, 0.06820589, -0.06755701, 0.0061744447)), dot((max(-src5, 0)), float4(0.039943404, 0.058139592, -0.054816127, 0.016273081))) + (result);
	result = float3(dot((max(src6, 0)), float4(0.0071622543, -0.048541367, 0.0015553127, 0.114169896)), dot((max(src6, 0)), float4(0.004829105, -0.059043564, 0.009178359, 0.1349016)), dot((max(src6, 0)), float4(-0.002032197, -0.05662218, 0.009577062, 0.11432262))) + (result);
	result = float3(dot((max(-src6, 0)), float4(0.019324556, 0.016746879, 0.12068619, -0.013930715)), dot((max(-src6, 0)), float4(0.028323999, 0.01608199, 0.13617857, -0.014250072)), dot((max(-src6, 0)), float4(0.027396113, 0.026891617, 0.113496214, -0.00824306))) + (result);
	result = float3(dot((max(src7, 0)), float4(-0.0024534757, -0.019158727, -0.09608131, -0.011210447)), dot((max(src7, 0)), float4(-0.0064973077, -0.024820521, -0.11177871, -0.010875943)), dot((max(src7, 0)), float4(-0.007905654, -0.020509848, -0.10503465, -0.015295865))) + (result);
	result = float3(dot((max(-src7, 0)), float4(0.09681486, -0.08199983, 0.041304465, -0.09863276)), dot((max(-src7, 0)), float4(0.113604136, -0.09013433, 0.048315883, -0.117853515)), dot((max(-src7, 0)), float4(0.10416855, -0.08562243, 0.042945288, -0.09870226))) + (result);
	Out7 = float4(result + origin, 1.0);
}

technique Anime4K_Restore_Soft_M
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
