// Anime4K Restore CNN (Soft_S) ported to ReShade FX.
// Source: Magpie Anime4K_Restore_Soft_S.hlsl <- bloc97/Anime4K glsl/Restore.
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
	float4 result = float4( 0.0113532655, -0.06449327, 0.035503868, 0.5683031 );
	result = float4(dot((src00), float3(0.10922428, 0.053448875, 0.20947173)), dot((src00), float3(-0.16249932, -0.16528402, -0.10576949)), dot((src00), float3(0.15452726, 0.01697721, 0.19738325)), dot((src00), float3(-0.15669551, -0.049275912, -0.025417482))) + (result);
	result = float4(dot((src01), float3(-0.3285196, -0.40508887, -0.24131267)), dot((src01), float3(0.15909512, -0.0609677, 0.10453423)), dot((src01), float3(-0.5273671, -0.4188177, -0.36216277)), dot((src01), float3(0.23778777, 0.11137456, 0.053446792))) + (result);
	result = float4(dot((src02), float3(0.23072472, 0.11958912, 0.10933724)), dot((src02), float3(-0.082083695, -0.312698, 0.017880991)), dot((src02), float3(-0.0041477727, -0.15842685, -0.022167003)), dot((src02), float3(-0.09136237, -0.013882424, 0.014662608))) + (result);
	result = float4(dot((src10), float3(-0.2789985, -0.48472273, -0.27021924)), dot((src10), float3(0.054727737, -0.011525487, -0.044563178)), dot((src10), float3(0.22577816, 0.5354349, 0.008232271)), dot((src10), float3(-0.49625716, -0.08814955, -0.13480483))) + (result);
	result = float4(dot((src11), float3(-0.18203105, -0.4335171, 0.011992759)), dot((src11), float3(0.09277001, 1.2275106, 0.060106967)), dot((src11), float3(0.27071548, -0.07663438, 0.11002492)), dot((src11), float3(-0.17773713, -0.29020032, -0.046098012))) + (result);
	result = float4(dot((src12), float3(0.08363418, 0.38670546, 0.0846784)), dot((src12), float3(0.063420765, 0.13577081, -0.057097007)), dot((src12), float3(-0.10278259, 0.048631024, 0.06049236)), dot((src12), float3(0.09357691, -0.024960777, 0.042082917))) + (result);
	result = float4(dot((src20), float3(0.12315548, 0.06479095, 0.08360464)), dot((src20), float3(-0.056513585, -0.36984903, 0.12835538)), dot((src20), float3(-0.09826642, -0.12512982, -0.005067881)), dot((src20), float3(-0.17079762, 0.042867575, 0.02542005))) + (result);
	result = float4(dot((src21), float3(0.18997705, 0.39745626, 0.010576528)), dot((src21), float3(0.086363226, -0.0090341605, -0.089242525)), dot((src21), float3(-0.0007131526, 0.27864447, -0.025109483)), dot((src21), float3(0.19858918, 0.20052041, -0.030768145))) + (result);
	result = float4(dot((src22), float3(0.05427315, 0.29116166, 0.0059667625)), dot((src22), float3(-0.060894873, -0.16159569, 0.016041303)), dot((src22), float3(0.06548642, -0.13293959, 0.03831561)), dot((src22), float3(0.095537595, -0.112566955, 0.09869594))) + (result);
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
	float4 result = float4( -0.106538564, -0.065693766, -0.03790106, 0.04776706 );
	result = float4(dot((max(src00, 0)), float4(-0.027102098, 0.15404584, -0.111836195, -0.07060754)), dot((max(src00, 0)), float4(0.2640691, 0.1361459, -0.0051853824, -0.18889332)), dot((max(src00, 0)), float4(0.1169015, -0.38066056, -0.0996669, -0.10793357)), dot((max(src00, 0)), float4(0.030902913, 0.096569136, -0.23538585, -0.15154232))) + (result);
	result = float4(dot((max(src01, 0)), float4(0.1378689, -0.05993059, -0.12522404, -0.03342411)), dot((max(src01, 0)), float4(0.21024452, -0.28364083, -0.16091396, -0.08964405)), dot((max(src01, 0)), float4(0.010976513, 0.24486947, 0.15499291, 0.25111282)), dot((max(src01, 0)), float4(0.0179521, 0.21347582, 0.08353191, -0.07550899))) + (result);
	result = float4(dot((max(src02, 0)), float4(-0.06398718, -0.033050716, 0.18018652, -0.100035876)), dot((max(src02, 0)), float4(0.05763278, 0.03346528, 0.24586707, 0.043505374)), dot((max(src02, 0)), float4(0.021394925, -0.0846797, 0.050538495, 0.042692907)), dot((max(src02, 0)), float4(0.14780094, 0.0125302235, 0.09879243, -0.08768257))) + (result);
	result = float4(dot((max(src10, 0)), float4(-0.11572878, 0.10323911, 0.085762165, 0.09042493)), dot((max(src10, 0)), float4(0.0545887, -0.18938646, 0.14605838, -0.087587915)), dot((max(src10, 0)), float4(0.16437739, -0.17097469, -0.15568069, -0.041969277)), dot((max(src10, 0)), float4(0.2775331, -0.188723, -0.16947642, 0.27252352))) + (result);
	result = float4(dot((max(src11, 0)), float4(0.21475963, -0.20367791, 0.12542121, 0.28490388)), dot((max(src11, 0)), float4(-0.018211678, -0.23041399, 0.16807431, 0.40945014)), dot((max(src11, 0)), float4(-0.5711054, 0.16346097, 0.09862575, -0.22364445)), dot((max(src11, 0)), float4(-0.09235345, 0.007901888, 0.16968751, 0.14460565))) + (result);
	result = float4(dot((max(src12, 0)), float4(0.27512726, -0.10503195, -0.093752496, -0.19815882)), dot((max(src12, 0)), float4(0.14046481, 0.3080809, -0.07476867, -0.0584525)), dot((max(src12, 0)), float4(-0.17684339, 0.03681373, 0.19900662, 0.027984729)), dot((max(src12, 0)), float4(0.102218024, 0.2668656, 0.06028286, -0.02143819))) + (result);
	result = float4(dot((max(src20, 0)), float4(-0.16829525, 0.18918815, -0.11022971, 0.022882428)), dot((max(src20, 0)), float4(-0.06818115, -0.10731989, 0.19150843, 0.1774031)), dot((max(src20, 0)), float4(0.0006509334, -0.008126929, 0.05272113, 0.062597334)), dot((max(src20, 0)), float4(0.01163159, -0.47991323, -0.34417602, -0.09915319))) + (result);
	result = float4(dot((max(src21, 0)), float4(0.32131585, -0.008077225, 0.09904077, -0.10536104)), dot((max(src21, 0)), float4(0.05668815, 0.009148517, 0.46938205, -0.23662373)), dot((max(src21, 0)), float4(-0.34203658, 0.10953332, -0.5148919, 0.002147416)), dot((max(src21, 0)), float4(0.05542482, -0.050969962, -0.22275375, -0.14256701))) + (result);
	result = float4(dot((max(src22, 0)), float4(-0.19335353, -0.118641876, 0.026719248, 0.08645617)), dot((max(src22, 0)), float4(-0.103732094, 0.14529023, 0.042491894, 0.08365193)), dot((max(src22, 0)), float4(0.17156832, -0.18662338, 0.026437795, -0.039582565)), dot((max(src22, 0)), float4(0.0059756916, 0.0447326, 0.05601309, 0.16612953))) + (result);
	result = float4(dot((max(-src00, 0)), float4(-0.014315469, -0.08064868, -0.04278333, 0.079363555)), dot((max(-src00, 0)), float4(0.012588422, -0.28149533, 0.29369017, 0.30725953)), dot((max(-src00, 0)), float4(0.037587024, 0.27326405, 0.18653142, 0.0147137)), dot((max(-src00, 0)), float4(0.08707526, 0.21468583, 0.035729136, 0.08527481))) + (result);
	result = float4(dot((max(-src01, 0)), float4(0.06659263, 0.48697233, 0.3089118, 0.3315688)), dot((max(-src01, 0)), float4(0.03452449, 0.019602561, 0.4315903, 0.13135147)), dot((max(-src01, 0)), float4(-0.33752796, -0.32033685, -0.13524854, -0.26904663)), dot((max(-src01, 0)), float4(0.0066543026, -0.20538871, -0.10791581, 0.142365))) + (result);
	result = float4(dot((max(-src02, 0)), float4(0.13619833, -0.29257727, -0.043791633, -0.05746597)), dot((max(-src02, 0)), float4(0.045271892, -0.10563375, -0.0056891907, -0.19959894)), dot((max(-src02, 0)), float4(-0.029841429, 0.35345638, -0.078411415, -0.12797245)), dot((max(-src02, 0)), float4(0.010704955, -0.06734038, 0.075443126, 0.18837726))) + (result);
	result = float4(dot((max(-src10, 0)), float4(0.25673476, 0.300447, -0.26155484, -0.023218757)), dot((max(-src10, 0)), float4(0.120482095, -0.3008584, 0.06905137, 0.07977591)), dot((max(-src10, 0)), float4(-0.23827696, -0.13834439, 0.16247983, -0.11354706)), dot((max(-src10, 0)), float4(-0.13557845, 0.5459493, 0.039960653, -0.25831422))) + (result);
	result = float4(dot((max(-src11, 0)), float4(0.0842605, 0.55912817, -0.20756413, -0.3927334)), dot((max(-src11, 0)), float4(0.282916, 0.1743876, 0.27321506, -0.5439608)), dot((max(-src11, 0)), float4(0.14062001, -0.30324093, -0.26560605, 0.39293098)), dot((max(-src11, 0)), float4(0.06356874, 0.052068707, -0.27695876, -0.001130203))) + (result);
	result = float4(dot((max(-src12, 0)), float4(-0.021890296, 0.0018722567, 0.46008193, -0.010446991)), dot((max(-src12, 0)), float4(-0.12703396, -0.26552317, 0.5595346, -0.56102365)), dot((max(-src12, 0)), float4(0.06660714, 0.06978973, 0.081981994, -0.079274766)), dot((max(-src12, 0)), float4(-0.03164527, -0.24030049, -0.038414747, -0.01851302))) + (result);
	result = float4(dot((max(-src20, 0)), float4(0.052988984, -0.5706256, -0.02242781, -0.059571438)), dot((max(-src20, 0)), float4(0.030581746, -0.0034910638, -0.13256042, -0.040119104)), dot((max(-src20, 0)), float4(-0.06868741, 0.48361364, 0.08997955, -0.05029196)), dot((max(-src20, 0)), float4(0.21545182, 0.9020033, 0.21001706, -0.127414))) + (result);
	result = float4(dot((max(-src21, 0)), float4(-0.08275339, -0.041986465, -0.17412743, 0.23155633)), dot((max(-src21, 0)), float4(-0.05999088, 0.1028236, -0.38364175, 0.2655843)), dot((max(-src21, 0)), float4(0.11068767, -0.17218924, 0.17410514, 0.045085523)), dot((max(-src21, 0)), float4(0.014646892, 0.026559748, 0.13038695, 0.13005458))) + (result);
	result = float4(dot((max(-src22, 0)), float4(-0.013383197, 0.123987064, -0.036109775, -0.009368096)), dot((max(-src22, 0)), float4(-0.064526096, 0.0104690585, 0.13384768, -0.05666906)), dot((max(-src22, 0)), float4(0.049046878, 0.07065378, 0.29676288, -0.09132696)), dot((max(-src22, 0)), float4(0.015992291, -0.009824511, -0.39475223, -0.082638375))) + (result);
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
	float4 result = float4( -0.0063428865, 0.0057986965, -0.12526293, -0.059240736 );
	result = float4(dot((max(src00, 0)), float4(0.024004154, -0.16621786, 0.17002718, -0.17601459)), dot((max(src00, 0)), float4(-0.26474997, 0.2964122, -0.2679876, -0.1782376)), dot((max(src00, 0)), float4(-0.5256586, 0.6044247, -0.30162668, 0.104725115)), dot((max(src00, 0)), float4(0.051624652, -0.14335106, 0.1273794, -0.16351137))) + (result);
	result = float4(dot((max(src01, 0)), float4(-0.121676154, 0.004424971, 0.15204315, 0.33737272)), dot((max(src01, 0)), float4(0.047741555, -0.35099635, -0.1165704, -0.11880767)), dot((max(src01, 0)), float4(-0.06738679, -0.073440626, 0.11231046, 0.09637475)), dot((max(src01, 0)), float4(-0.056402843, 0.039784692, -0.27369732, -0.14709689))) + (result);
	result = float4(dot((max(src02, 0)), float4(-0.017987821, -0.05871703, 0.003271283, -0.1574738)), dot((max(src02, 0)), float4(-0.08798823, 0.27013004, -0.0029015478, 0.06750957)), dot((max(src02, 0)), float4(-0.062515825, 0.19397618, -0.07390092, -0.07661155)), dot((max(src02, 0)), float4(-0.046803873, -0.052147817, -0.09348337, 0.054327156))) + (result);
	result = float4(dot((max(src10, 0)), float4(-0.15215784, -0.19125701, 0.25565025, -0.008718429)), dot((max(src10, 0)), float4(-0.72508365, 0.021401431, -0.12872623, -0.05864064)), dot((max(src10, 0)), float4(-0.3202069, -0.051837035, 0.13169816, 0.028844763)), dot((max(src10, 0)), float4(0.20295432, -0.025939213, 0.27377388, 0.1144993))) + (result);
	result = float4(dot((max(src11, 0)), float4(-0.30012092, 0.082795605, -0.67764, -0.07398165)), dot((max(src11, 0)), float4(-0.1322455, -0.075334676, -0.38598236, -0.07213789)), dot((max(src11, 0)), float4(-0.11868545, -0.3752773, -0.21023573, -0.28427607)), dot((max(src11, 0)), float4(0.09857058, -0.02918163, 0.38274166, 0.1266569))) + (result);
	result = float4(dot((max(src12, 0)), float4(-0.37507388, 0.022066567, 0.017002959, -0.08231422)), dot((max(src12, 0)), float4(0.18809201, -0.27627763, -0.091398515, -0.14665812)), dot((max(src12, 0)), float4(-0.21982779, 0.12345216, -0.25207692, -0.07868529)), dot((max(src12, 0)), float4(0.27208912, -0.30041683, -0.29253414, -0.24562219))) + (result);
	result = float4(dot((max(src20, 0)), float4(0.08686712, 0.14957365, 0.27255878, 0.055278245)), dot((max(src20, 0)), float4(0.080837384, 0.21801959, 0.33320278, 0.085710146)), dot((max(src20, 0)), float4(0.20736577, -0.04870689, -0.08467146, 0.009097151)), dot((max(src20, 0)), float4(0.008233064, 0.42149112, 0.10381615, 0.29092705))) + (result);
	result = float4(dot((max(src21, 0)), float4(0.0012207404, 0.19330226, 0.44879642, 0.2631811)), dot((max(src21, 0)), float4(-0.023874281, 0.33711615, 0.1978837, 0.40786585)), dot((max(src21, 0)), float4(-0.027035477, -0.16495204, -0.20492741, -0.055340275)), dot((max(src21, 0)), float4(0.005157451, 0.549021, 0.28099406, 0.2575511))) + (result);
	result = float4(dot((max(src22, 0)), float4(0.29127392, -0.3183704, 0.010730576, -0.0037143505)), dot((max(src22, 0)), float4(-0.06287165, 0.42057636, 0.29091576, 0.1191774)), dot((max(src22, 0)), float4(0.12715077, -0.11483724, -0.046116166, -0.06084074)), dot((max(src22, 0)), float4(0.14784902, -0.3019506, -0.23528357, 0.011641706))) + (result);
	result = float4(dot((max(-src00, 0)), float4(-0.2579205, 0.21318026, -0.06979331, -0.10994228)), dot((max(-src00, 0)), float4(0.036545023, 0.21370813, -0.0690704, 0.109930746)), dot((max(-src00, 0)), float4(0.11691888, -0.14114271, 0.04618086, 0.103678934)), dot((max(-src00, 0)), float4(0.04996418, 0.031217605, 0.025164584, 0.12193115))) + (result);
	result = float4(dot((max(-src01, 0)), float4(-0.19843774, -0.15669724, 0.17143534, -0.27032652)), dot((max(-src01, 0)), float4(-0.11237926, 0.46283355, -0.19934891, -0.2702769)), dot((max(-src01, 0)), float4(0.007291354, 0.077065215, -0.25481275, 0.04816228)), dot((max(-src01, 0)), float4(0.16480611, 0.112273656, 0.034591813, -0.031614583))) + (result);
	result = float4(dot((max(-src02, 0)), float4(-0.16307239, -0.015648091, 0.19560932, -0.3116519)), dot((max(-src02, 0)), float4(-0.11295217, 0.11741865, -0.10553561, 0.13957061)), dot((max(-src02, 0)), float4(0.05861256, 0.113366075, -0.042583376, -0.0044852323)), dot((max(-src02, 0)), float4(0.14225823, 0.023935538, -0.048160724, -0.015472912))) + (result);
	result = float4(dot((max(-src10, 0)), float4(-0.15629178, -0.021733627, 0.10801276, -0.121420704)), dot((max(-src10, 0)), float4(0.06463271, 0.22236359, -0.021957984, 0.2520835)), dot((max(-src10, 0)), float4(-0.13176678, 0.019508492, -0.11272639, 0.043395765)), dot((max(-src10, 0)), float4(0.025518289, -0.11629477, -0.03615053, 0.1699031))) + (result);
	result = float4(dot((max(-src11, 0)), float4(0.2886654, -0.109903164, 0.3761606, 0.10832971)), dot((max(-src11, 0)), float4(0.21755892, -0.67295986, 0.23199768, -0.3530352)), dot((max(-src11, 0)), float4(0.21757497, 0.22886126, 0.05908783, 0.20234483)), dot((max(-src11, 0)), float4(0.08442575, -0.027185453, -0.1496158, -0.07615918))) + (result);
	result = float4(dot((max(-src12, 0)), float4(0.11043024, -0.15085667, 0.33805525, 0.004984607)), dot((max(-src12, 0)), float4(0.18943349, 0.020204183, 0.0066280114, 0.0429299)), dot((max(-src12, 0)), float4(0.42394367, -0.081609115, 0.0018284445, -0.14568979)), dot((max(-src12, 0)), float4(0.029350199, 0.07907012, 0.022983696, -0.29143327))) + (result);
	result = float4(dot((max(-src20, 0)), float4(-0.16376027, -0.13885716, -0.004799155, -0.22535577)), dot((max(-src20, 0)), float4(-0.20387048, -0.04380927, -0.25407305, -0.09583549)), dot((max(-src20, 0)), float4(0.06522074, -0.03535832, -0.039976966, 0.0334331)), dot((max(-src20, 0)), float4(0.17484841, -0.16978237, -0.011992087, 0.016292758))) + (result);
	result = float4(dot((max(-src21, 0)), float4(-0.38688713, -0.24170811, -0.08257971, -0.11932821)), dot((max(-src21, 0)), float4(-0.20232083, -0.074868314, -0.11902456, 0.024207884)), dot((max(-src21, 0)), float4(0.23887886, 0.03977399, 0.106009185, 0.10070917)), dot((max(-src21, 0)), float4(-0.10438324, -0.22810821, -0.078289054, 0.79348284))) + (result);
	result = float4(dot((max(-src22, 0)), float4(-0.4018743, 0.12964934, -0.102386944, -0.22499937)), dot((max(-src22, 0)), float4(0.050456528, -0.44461823, -0.13805065, 0.14680648)), dot((max(-src22, 0)), float4(0.035341598, 0.029031694, 0.0055692918, -0.3443954)), dot((max(-src22, 0)), float4(-0.03788609, 0.29604837, 0.14659804, -0.06994176))) + (result);
	Out3 = result;
}

void Anime4K_PS4(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out4 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 pos = (float2(pix) + 0.5) * rcp;
	float4 a = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d = tex2Dlod(SampT1, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e = tex2Dlod(SampT1, float4(pos, 0, 0));
	float4 f = tex2Dlod(SampT1, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g = tex2Dlod(SampT1, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h = tex2Dlod(SampT1, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i = tex2Dlod(SampT1, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float3 result = float3( -0.008303841, -0.008251826, -0.0069884053 );
	result = float3(dot((max(a, 0)), float4(0.08631539, -0.023760278, -0.012447854, -0.033292875)), dot((max(a, 0)), float4(0.09499331, -0.027293118, -0.008565141, -0.031266093)), dot((max(a, 0)), float4(0.065609254, -0.022839671, -0.012041815, -0.02874347))) + (result);
	result = float3(dot((max(b, 0)), float4(0.08709062, -0.09099671, 0.057814583, 0.12246188)), dot((max(b, 0)), float4(0.09760889, -0.102120616, 0.06999608, 0.1319784)), dot((max(b, 0)), float4(0.08988583, -0.098076016, 0.05961344, 0.12254915))) + (result);
	result = float3(dot((max(c, 0)), float4(0.07694916, -0.046808865, 0.01599848, 0.033142705)), dot((max(c, 0)), float4(0.0822054, -0.051509347, 0.014677793, 0.0426565)), dot((max(c, 0)), float4(0.07549296, -0.035890795, 0.0086143715, 0.035911378))) + (result);
	result = float3(dot((max(d, 0)), float4(-0.0008269902, 0.0006387551, 0.013909732, 0.027028518)), dot((max(d, 0)), float4(0.0009082343, 0.005079344, 0.011026747, 0.022164145)), dot((max(d, 0)), float4(0.014101725, -0.013034868, 0.012485332, 0.03183532))) + (result);
	result = float3(dot((max(e, 0)), float4(-0.33575395, 0.35850254, -0.12680013, -0.061541136)), dot((max(e, 0)), float4(-0.36700967, 0.37535715, -0.1256115, -0.059120018)), dot((max(e, 0)), float4(-0.34140685, 0.34613726, -0.112494245, -0.06552594))) + (result);
	result = float3(dot((max(f, 0)), float4(-0.047570463, -0.110970475, 0.041563414, -0.17999935)), dot((max(f, 0)), float4(-0.050335366, -0.12363716, 0.059771337, -0.19700716)), dot((max(f, 0)), float4(-0.04665491, -0.11072252, 0.045290247, -0.17459513))) + (result);
	result = float3(dot((max(g, 0)), float4(0.078488424, -0.0063715233, 0.031237155, -0.023146842)), dot((max(g, 0)), float4(0.07483357, 0.00035415235, 0.02512343, -0.026732154)), dot((max(g, 0)), float4(0.08347933, -0.010886946, 0.034399323, -0.027644241))) + (result);
	result = float3(dot((max(h, 0)), float4(-0.05906883, -0.003939601, -0.1662408, 0.051277652)), dot((max(h, 0)), float4(-0.06784104, -0.0011749315, -0.16871658, 0.04837499)), dot((max(h, 0)), float4(-0.04506148, -0.006256036, -0.16598499, 0.05120855))) + (result);
	result = float3(dot((max(i, 0)), float4(0.08158806, -0.05765347, 0.26747537, -0.010376844)), dot((max(i, 0)), float4(0.08674548, -0.06196418, 0.2668808, -0.01690028)), dot((max(i, 0)), float4(0.07437206, -0.057311118, 0.2389857, -0.008414153))) + (result);
	result = float3(dot((max(-a, 0)), float4(0.030539425, 0.006491679, -0.0058292216, 0.025942149)), dot((max(-a, 0)), float4(0.02415435, 0.014436586, -0.013982021, 0.015361476)), dot((max(-a, 0)), float4(0.039969034, 0.005435709, -0.011243379, 0.019134998))) + (result);
	result = float3(dot((max(-b, 0)), float4(-0.06322247, 0.028702464, -0.072553575, -0.1447189)), dot((max(-b, 0)), float4(-0.07146787, 0.039047733, -0.08046175, -0.1539398)), dot((max(-b, 0)), float4(-0.06673042, 0.039646607, -0.07027197, -0.1466465))) + (result);
	result = float3(dot((max(-c, 0)), float4(-0.046430312, 0.032971155, -0.017612953, -0.026717246)), dot((max(-c, 0)), float4(-0.054549117, 0.02980819, -0.015100736, -0.028401854)), dot((max(-c, 0)), float4(-0.048076343, 0.029172963, -0.01202649, -0.034548033))) + (result);
	result = float3(dot((max(-d, 0)), float4(-0.0020459262, 0.0054226154, -0.0021330053, -0.08636891)), dot((max(-d, 0)), float4(-0.0008748501, 0.008867029, -0.0036601655, -0.10203159)), dot((max(-d, 0)), float4(-0.012601956, 0.018921215, -0.0022091097, -0.09741449))) + (result);
	result = float3(dot((max(-e, 0)), float4(0.07306159, -0.1933229, 0.107496604, 0.30877885)), dot((max(-e, 0)), float4(0.08245483, -0.20326294, 0.11584994, 0.31297725)), dot((max(-e, 0)), float4(0.06548199, -0.19189309, 0.10907522, 0.30890995))) + (result);
	result = float3(dot((max(-f, 0)), float4(0.03192904, 0.074100636, -0.1136165, 0.14465587)), dot((max(-f, 0)), float4(0.035112645, 0.08349646, -0.12470947, 0.16328491)), dot((max(-f, 0)), float4(0.033732817, 0.06659352, -0.11192198, 0.13984151))) + (result);
	result = float3(dot((max(-g, 0)), float4(-0.05098033, 0.0045651463, -0.021199327, -0.031621892)), dot((max(-g, 0)), float4(-0.053096622, -0.007682458, -0.016210148, -0.046702545)), dot((max(-g, 0)), float4(-0.05533725, 0.0026934785, -0.030939564, -0.02647333))) + (result);
	result = float3(dot((max(-h, 0)), float4(0.055801813, 0.0241233, 0.08707151, -0.109053336)), dot((max(-h, 0)), float4(0.06430485, 0.013879883, 0.10031039, -0.11414017)), dot((max(-h, 0)), float4(0.05052402, 0.017344628, 0.095042154, -0.111838564))) + (result);
	result = float3(dot((max(-i, 0)), float4(0.030582374, 0.038665913, 0.09209076, -0.014655714)), dot((max(-i, 0)), float4(0.03604719, 0.036998056, 0.10010001, -0.0074866647)), dot((max(-i, 0)), float4(0.040417343, 0.030004544, 0.08389406, -0.012227013))) + (result);
	result += tex2Dlod(SampInput, float4(pos, 0, 0)).rgb;
	Out4 = float4(result, 1.0);
}

technique Anime4K_Restore_Soft_S
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
		RenderTarget0 = Anime4K_T1;
	}
	pass P4
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS4;
	}
}
