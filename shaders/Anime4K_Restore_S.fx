// Anime4K Restore CNN (S) ported to ReShade FX.
// Source: Magpie Anime4K_Restore_S.hlsl <- bloc97/Anime4K glsl/Restore.
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
	float4 result = float4( -0.011108127, -0.07481861, 0.07640154, 0.4964964 );
	result = float4(dot((src00), float3(-0.19288683, -0.26682988, 0.038494494)), dot((src00), float3(-0.21397883, -0.06144587, -0.16651472)), dot((src00), float3(0.111997396, -0.03601853, 0.147657)), dot((src00), float3(-0.04791413, -0.16693151, -0.083003886))) + (result);
	result = float4(dot((src01), float3(-0.14286195, -0.33392772, -0.15155545)), dot((src01), float3(0.08746566, -0.18703035, -0.0010025925)), dot((src01), float3(-0.40107322, -0.21326795, -0.1554875)), dot((src01), float3(0.12390977, 0.04780781, -0.10676251))) + (result);
	result = float4(dot((src02), float3(0.28095165, 0.025937587, 0.076416336)), dot((src02), float3(0.022872915, -0.055012174, 0.06656033)), dot((src02), float3(-0.21342312, -0.33779636, -0.1557806)), dot((src02), float3(-0.29982176, 0.0015666655, 0.1078894))) + (result);
	result = float4(dot((src10), float3(-0.31584853, -0.50103146, -0.32097813)), dot((src10), float3(0.07527119, -0.07217874, -0.051580857)), dot((src10), float3(0.30713862, 0.512807, -0.022466356)), dot((src10), float3(-0.34014285, -0.09597398, 0.01148551))) + (result);
	result = float4(dot((src11), float3(-0.026032459, -0.27421117, 0.07819544)), dot((src11), float3(-0.04193211, 1.0906446, 0.06003738)), dot((src11), float3(0.37703893, -0.049654085, 0.1405805)), dot((src11), float3(-0.031916667, -0.19814016, -0.0064135445))) + (result);
	result = float4(dot((src12), float3(0.041450135, 0.53344345, 0.2325609)), dot((src12), float3(0.11319654, 0.30857387, -0.027797326)), dot((src12), float3(-0.23237701, -0.057264958, -0.04544767)), dot((src12), float3(0.08443178, -0.1575803, -0.18720597))) + (result);
	result = float4(dot((src20), float3(0.2531829, 0.20126024, 0.29951036)), dot((src20), float3(-0.074966915, -0.5380133, 0.17123336)), dot((src20), float3(-0.27800754, -0.15082566, -0.01681872)), dot((src20), float3(-0.3146097, -0.19021043, -0.12574998))) + (result);
	result = float4(dot((src21), float3(0.25203633, 0.40712556, -0.057267334)), dot((src21), float3(0.19882993, 0.084902965, -0.030388135)), dot((src21), float3(0.14906439, 0.42969635, 8.8084314e-05)), dot((src21), float3(0.13593598, 0.2961132, 0.0210724))) + (result);
	result = float4(dot((src22), float3(-0.13459359, 0.2033463, -0.18479438)), dot((src22), float3(-0.12199573, -0.09388599, -0.066625565)), dot((src22), float3(0.12591946, -0.094370656, 0.08279283)), dot((src22), float3(0.24736497, 0.1071285, 0.20130983))) + (result);
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
	float4 result = float4( -0.16371979, -0.024620198, -0.035754893, 0.04176776 );
	result = float4(dot((max(src00, 0)), float4(-0.056432575, 0.16885762, -0.08011296, 0.026012989)), dot((max(src00, 0)), float4(0.0028165397, -0.062179096, 0.02947316, -0.09823925)), dot((max(src00, 0)), float4(-0.026325442, -0.2332292, 0.014771492, 0.036625937)), dot((max(src00, 0)), float4(-0.14802271, 0.17513658, -0.17946689, -0.06924322))) + (result);
	result = float4(dot((max(src01, 0)), float4(-0.13571467, -0.07188695, -0.12294444, 0.10969853)), dot((max(src01, 0)), float4(0.09831142, -0.20161287, -0.1404628, 0.17640765)), dot((max(src01, 0)), float4(0.12911566, 0.3858435, -0.022659872, 0.39796907)), dot((max(src01, 0)), float4(0.06305893, -0.21069056, 0.23008968, 0.20413099))) + (result);
	result = float4(dot((max(src02, 0)), float4(-0.0061665224, 0.061626043, 0.2238265, -0.122404456)), dot((max(src02, 0)), float4(0.055102807, 0.16898955, 0.19429931, -0.00026717107)), dot((max(src02, 0)), float4(-0.0059629944, -0.21215646, 0.09874656, -0.28203064)), dot((max(src02, 0)), float4(-0.021429887, 0.16510476, 0.06828208, -0.29979932))) + (result);
	result = float4(dot((max(src10, 0)), float4(-0.22735378, -0.09841722, -0.044078812, 0.08353025)), dot((max(src10, 0)), float4(0.14538136, -0.0661309, 0.1298332, 0.083519086)), dot((max(src10, 0)), float4(0.11549746, 0.348576, 0.04793373, 0.10766399)), dot((max(src10, 0)), float4(0.194148, -0.017375294, -0.30687734, 0.31796935))) + (result);
	result = float4(dot((max(src11, 0)), float4(0.048365135, -0.26443407, 0.08140953, 0.07732627)), dot((max(src11, 0)), float4(-0.17566709, -0.010216014, -0.09664591, 0.10188082)), dot((max(src11, 0)), float4(-0.33212858, 0.1573303, 0.076109104, -0.28266954)), dot((max(src11, 0)), float4(-0.052667376, 0.05725314, -0.026773714, -0.16230233))) + (result);
	result = float4(dot((max(src12, 0)), float4(0.29931107, 0.12576093, -0.025801308, -0.11025257)), dot((max(src12, 0)), float4(0.117944, 0.17082554, -0.10797019, 0.12798019)), dot((max(src12, 0)), float4(-0.10414009, -0.15803693, 0.0721032, 0.081827976)), dot((max(src12, 0)), float4(0.12795551, 0.13430743, 0.2825884, -0.050441865))) + (result);
	result = float4(dot((max(src20, 0)), float4(-0.11827391, -0.023839617, 0.09411734, 0.1470966)), dot((max(src20, 0)), float4(0.08306765, -0.019507334, 0.38415068, -0.0684779)), dot((max(src20, 0)), float4(-0.3430314, 0.23176382, -0.25845516, -0.07071314)), dot((max(src20, 0)), float4(0.07898041, -0.40992323, -0.29984522, -0.026773235))) + (result);
	result = float4(dot((max(src21, 0)), float4(0.19091596, -0.015838385, 0.2642396, -0.14696182)), dot((max(src21, 0)), float4(0.082110435, -0.046316292, 0.31824252, 0.052168854)), dot((max(src21, 0)), float4(-0.5266589, 0.023171103, -0.041754793, 0.039857205)), dot((max(src21, 0)), float4(-0.1744098, -0.03731331, -0.09525519, -0.027555354))) + (result);
	result = float4(dot((max(src22, 0)), float4(0.15207373, 0.06089903, 0.016356342, -0.0013459618)), dot((max(src22, 0)), float4(0.09845733, 0.17902578, -0.06277531, 0.15725887)), dot((max(src22, 0)), float4(0.0142631065, -0.42391995, -0.12173141, 0.019310836)), dot((max(src22, 0)), float4(0.096375965, 0.22475442, -0.18635495, 0.20293565))) + (result);
	result = float4(dot((max(-src00, 0)), float4(-0.18395247, -0.0419004, 0.1709272, -0.030382963)), dot((max(-src00, 0)), float4(0.30672902, -0.2169228, 0.51062274, 0.3357568)), dot((max(-src00, 0)), float4(0.09034339, -0.14052129, 0.13758625, -0.26491287)), dot((max(-src00, 0)), float4(0.1821889, 0.11006559, -0.2242552, 0.02501938))) + (result);
	result = float4(dot((max(-src01, 0)), float4(0.040511727, 0.25354835, 0.2732347, 0.034099877)), dot((max(-src01, 0)), float4(0.12523083, 0.3404216, 0.4468553, -0.00954992)), dot((max(-src01, 0)), float4(-0.27318433, -0.2632471, 0.084667034, -0.32751867)), dot((max(-src01, 0)), float4(0.08388512, -0.17784123, -0.1856242, -0.062207516))) + (result);
	result = float4(dot((max(-src02, 0)), float4(0.17564747, -0.2762563, 0.095402054, 0.009799127)), dot((max(-src02, 0)), float4(0.11645554, -0.1413764, 0.0715738, 0.04059529)), dot((max(-src02, 0)), float4(-0.16362113, 0.23264363, -0.19346157, 0.19688335)), dot((max(-src02, 0)), float4(0.105654195, -0.14000498, -0.028285999, 0.1282381))) + (result);
	result = float4(dot((max(-src10, 0)), float4(0.23575781, 0.36890212, -0.30916876, -0.06263589)), dot((max(-src10, 0)), float4(-0.11446148, -0.85968876, -0.10445518, -0.2160114)), dot((max(-src10, 0)), float4(-0.20504695, -0.18545328, -0.3046253, -0.16383372)), dot((max(-src10, 0)), float4(0.035568226, 0.33796397, 0.33271998, -0.31173357))) + (result);
	result = float4(dot((max(-src11, 0)), float4(0.20469664, 0.39843914, -0.21809858, -0.14411364)), dot((max(-src11, 0)), float4(0.4039374, -0.15490077, 0.23496576, -0.2515329)), dot((max(-src11, 0)), float4(-0.070057206, -0.24476516, -0.051794037, 0.124655396)), dot((max(-src11, 0)), float4(0.030353077, 0.38238233, 0.033664484, -0.05818785))) + (result);
	result = float4(dot((max(-src12, 0)), float4(-0.09065731, -0.41504318, 0.29752317, -0.15873958)), dot((max(-src12, 0)), float4(-0.16787091, -0.048163068, 0.2926866, -0.121961035)), dot((max(-src12, 0)), float4(0.013269188, 0.31760025, 0.14408836, 0.11797893)), dot((max(-src12, 0)), float4(0.23687351, -0.33648986, -0.33382463, 0.09000567))) + (result);
	result = float4(dot((max(-src20, 0)), float4(0.13356976, 0.03417223, -0.50132495, -0.17595838)), dot((max(-src20, 0)), float4(0.013763947, 0.7031121, -0.419648, 0.1633008)), dot((max(-src20, 0)), float4(0.012169505, 0.65146804, 0.2940041, -0.018587278)), dot((max(-src20, 0)), float4(-0.109594524, 0.5250268, 0.83051753, 0.079596795))) + (result);
	result = float4(dot((max(-src21, 0)), float4(0.07570128, -0.054611947, -0.4981031, 0.25189674)), dot((max(-src21, 0)), float4(-0.1581438, 0.17469402, -0.37507218, -0.025896115)), dot((max(-src21, 0)), float4(0.03904949, -0.44252598, -0.18466389, 0.034307647)), dot((max(-src21, 0)), float4(0.14890033, 0.036181703, 0.2645845, -0.020462232))) + (result);
	result = float4(dot((max(-src22, 0)), float4(-0.11645865, 0.062284566, 0.18208642, -0.037232924)), dot((max(-src22, 0)), float4(0.02296537, -0.22526766, 0.3954284, -0.10185309)), dot((max(-src22, 0)), float4(0.040909223, 0.09241534, 0.2884468, -0.17956531)), dot((max(-src22, 0)), float4(0.015069485, -0.32623053, -0.25137675, 0.018966453))) + (result);
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
	float4 result = float4( -0.0036821906, -0.050239526, -0.01355402, 0.00048220603 );
	result = float4(dot((max(src00, 0)), float4(0.01921286, -0.25313398, 0.5837018, 0.060783498)), dot((max(src00, 0)), float4(-0.26684764, 0.12264074, -0.042300556, 0.05540401)), dot((max(src00, 0)), float4(-0.12663573, 0.58750325, -0.20435576, 0.2205112)), dot((max(src00, 0)), float4(0.31641877, -0.14084283, -0.009954825, -0.06578902))) + (result);
	result = float4(dot((max(src01, 0)), float4(-0.21930243, 0.011201461, 0.47990513, -0.07620939)), dot((max(src01, 0)), float4(-0.03774968, -0.271034, 0.2982416, -0.07148229)), dot((max(src01, 0)), float4(0.22615197, 0.00573116, -0.1087603, 0.03691984)), dot((max(src01, 0)), float4(0.18338196, -0.12248194, -0.050099242, -0.16796488))) + (result);
	result = float4(dot((max(src02, 0)), float4(-0.14962853, 0.052237745, 0.08119985, -0.13206963)), dot((max(src02, 0)), float4(-0.053769328, -0.26160842, 0.075785555, -0.08759176)), dot((max(src02, 0)), float4(0.02387081, -0.08603077, -0.33437458, -0.03288923)), dot((max(src02, 0)), float4(0.22002189, 0.012542448, -0.43373227, -0.09799959))) + (result);
	result = float4(dot((max(src10, 0)), float4(-0.1305593, 0.013692483, 0.42217395, -0.15702641)), dot((max(src10, 0)), float4(-0.5974288, 0.06646377, -0.11289523, -0.19922857)), dot((max(src10, 0)), float4(0.06058367, 0.16469325, -0.06165009, -0.0035429662)), dot((max(src10, 0)), float4(0.08406488, 0.08990975, 0.48556912, -0.0022089656))) + (result);
	result = float4(dot((max(src11, 0)), float4(-0.1964807, -0.07063389, -0.7684516, -0.16653742)), dot((max(src11, 0)), float4(0.038099788, 0.11604167, -0.1037487, 0.0028585843)), dot((max(src11, 0)), float4(0.21587034, -0.24558097, -0.09380674, -0.33774406)), dot((max(src11, 0)), float4(0.039734077, -0.08900199, 0.33144563, -0.0528696))) + (result);
	result = float4(dot((max(src12, 0)), float4(-0.27298656, 0.1025106, 0.0095010325, 0.21006055)), dot((max(src12, 0)), float4(-0.05665099, -0.22055034, 0.13118382, -0.06189587)), dot((max(src12, 0)), float4(0.09661685, -0.21218458, -0.42582452, -0.15285942)), dot((max(src12, 0)), float4(0.19780266, -0.040628925, -0.22197723, -0.09526762))) + (result);
	result = float4(dot((max(src20, 0)), float4(-0.14494462, 0.35096622, 0.29413632, 0.047262143)), dot((max(src20, 0)), float4(-0.046788953, 0.16682479, 0.28212717, -0.11892685)), dot((max(src20, 0)), float4(0.065877035, 0.028363144, -0.025364442, -0.008032766)), dot((max(src20, 0)), float4(0.09911713, 0.36037162, -0.3406269, 0.29743317))) + (result);
	result = float4(dot((max(src21, 0)), float4(-0.15191558, -0.012661432, 0.24491951, 0.18063772)), dot((max(src21, 0)), float4(-0.36980554, 0.15737776, -0.15575431, 0.4455559)), dot((max(src21, 0)), float4(0.14555687, -0.115250416, -0.27802598, -0.09693302)), dot((max(src21, 0)), float4(0.0043930537, 0.10324491, 0.21959937, 0.33382267))) + (result);
	result = float4(dot((max(src22, 0)), float4(0.2717801, -0.40111846, 0.44306824, 0.060776163)), dot((max(src22, 0)), float4(0.13452889, 0.1154301, -0.02831414, 0.30347148)), dot((max(src22, 0)), float4(0.14105384, -0.0076733204, -0.2153124, -0.0036976219)), dot((max(src22, 0)), float4(0.16324317, -0.09697362, -0.12075326, -0.12070682))) + (result);
	result = float4(dot((max(-src00, 0)), float4(-0.39780128, 0.07520163, -0.1593877, -0.13917233)), dot((max(-src00, 0)), float4(-0.29875937, 0.021689568, 0.017156163, 0.30957314)), dot((max(-src00, 0)), float4(-0.12952097, -0.23121156, -0.06038025, 0.243109)), dot((max(-src00, 0)), float4(0.080333896, -0.038140096, 0.009244022, -0.104947075))) + (result);
	result = float4(dot((max(-src01, 0)), float4(-0.07965157, -0.08768168, 0.14453568, 0.11722939)), dot((max(-src01, 0)), float4(0.06776501, -0.03689969, -0.17648841, -0.34161824)), dot((max(-src01, 0)), float4(-0.13288979, 0.12034646, -0.3378289, 0.08424494)), dot((max(-src01, 0)), float4(0.005851189, 0.22441491, -0.018329712, -0.01400687))) + (result);
	result = float4(dot((max(-src02, 0)), float4(0.08153887, -0.07385973, 0.26345527, -0.30336383)), dot((max(-src02, 0)), float4(0.07222914, 0.18440577, 0.15280858, -0.22978698)), dot((max(-src02, 0)), float4(-0.14663404, 0.35890242, -0.007446105, 0.11612946)), dot((max(-src02, 0)), float4(-0.038526025, 0.17084727, -0.024403179, -0.23614909))) + (result);
	result = float4(dot((max(-src10, 0)), float4(-0.07447396, -0.30787337, 0.048989657, 0.06495196)), dot((max(-src10, 0)), float4(0.09023449, 0.15087669, -0.13075387, 0.269715)), dot((max(-src10, 0)), float4(-0.13798, 0.14418626, -0.13458036, 0.3674355)), dot((max(-src10, 0)), float4(-0.086943336, -0.03371195, -0.059836224, 0.38956037))) + (result);
	result = float4(dot((max(-src11, 0)), float4(0.34981915, -0.20149232, 0.25976858, 0.19380626)), dot((max(-src11, 0)), float4(-0.048779126, -0.82969636, 0.4370118, -0.080370255)), dot((max(-src11, 0)), float4(0.31717536, -0.10167862, -0.04724865, 0.09578106)), dot((max(-src11, 0)), float4(0.38080826, 0.6382858, -0.10014156, -0.035166856))) + (result);
	result = float4(dot((max(-src12, 0)), float4(-0.026443917, -0.26652107, 0.38249823, -0.13344015)), dot((max(-src12, 0)), float4(0.4132611, -0.2996705, 0.21486135, -0.32088286)), dot((max(-src12, 0)), float4(0.01822534, 0.30905882, 0.025314959, -0.2833883)), dot((max(-src12, 0)), float4(0.12742202, 0.07989903, -0.14717339, -0.30973712))) + (result);
	result = float4(dot((max(-src20, 0)), float4(0.021517841, -0.38583103, 0.04676486, -0.18823163)), dot((max(-src20, 0)), float4(0.006556378, -0.0027515136, -0.11954886, -0.16542958)), dot((max(-src20, 0)), float4(0.2025686, -0.06556736, -0.051612873, 0.04245155)), dot((max(-src20, 0)), float4(-0.12044382, -0.097090125, 0.07831412, 0.6437998))) + (result);
	result = float4(dot((max(-src21, 0)), float4(-0.39475346, 0.21935691, 0.09188909, -0.34167948)), dot((max(-src21, 0)), float4(-0.2936861, 0.2101108, -0.020147726, 0.07523185)), dot((max(-src21, 0)), float4(0.26768062, -0.15455097, 0.103328265, -0.17669058)), dot((max(-src21, 0)), float4(-0.28151843, 0.19548604, -0.12574542, 0.62446547))) + (result);
	result = float4(dot((max(-src22, 0)), float4(-0.37661025, 0.14079669, -0.21235192, -0.13297133)), dot((max(-src22, 0)), float4(-0.29630858, -0.2170294, -0.07860726, 0.33012658)), dot((max(-src22, 0)), float4(0.05451026, -0.038716137, -0.005749412, -0.27434957)), dot((max(-src22, 0)), float4(0.1611643, 0.13514164, 0.025625167, -0.18416783))) + (result);
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
	float3 result = float3( -0.0052927984, -0.0060193934, -0.0048643993 );
	result = float3(dot((max(a, 0)), float4(0.15873, -0.017379675, 0.009670625, 0.025388412)), dot((max(a, 0)), float4(0.17989138, -0.017363746, 0.0070157526, 0.027231036)), dot((max(a, 0)), float4(0.14648493, -0.019855022, 0.0075994316, 0.024052646))) + (result);
	result = float3(dot((max(b, 0)), float4(0.048195973, -0.115950756, 0.032125086, 0.01223746)), dot((max(b, 0)), float4(0.041760173, -0.12887983, 0.03397254, 0.020822672)), dot((max(b, 0)), float4(0.037366055, -0.12535639, 0.032950625, 0.0161561))) + (result);
	result = float3(dot((max(c, 0)), float4(0.0890567, 0.016081346, -0.011775135, 0.072103254)), dot((max(c, 0)), float4(0.094453335, 0.017434116, -0.010094134, 0.07940666)), dot((max(c, 0)), float4(0.09014035, 0.020783134, -0.018522855, 0.065876864))) + (result);
	result = float3(dot((max(d, 0)), float4(-0.04841196, 0.10912542, -0.013013885, 0.037505716)), dot((max(d, 0)), float4(-0.06963968, 0.11813441, -0.01562045, 0.04352026)), dot((max(d, 0)), float4(-0.056574684, 0.10643838, -0.013802797, 0.04645123))) + (result);
	result = float3(dot((max(e, 0)), float4(-0.3472869, 0.23654196, -0.045226905, -0.10267792)), dot((max(e, 0)), float4(-0.36243078, 0.2305048, -0.041799217, -0.1123385)), dot((max(e, 0)), float4(-0.33530185, 0.22150646, -0.042511635, -0.10845448))) + (result);
	result = float3(dot((max(f, 0)), float4(0.011987401, -0.15911353, 0.15675929, -0.09240023)), dot((max(f, 0)), float4(0.012285043, -0.17523928, 0.16531634, -0.09513292)), dot((max(f, 0)), float4(0.007813165, -0.1535267, 0.15948962, -0.084187366))) + (result);
	result = float3(dot((max(g, 0)), float4(0.069052905, -0.012180326, -0.044663202, -0.008540197)), dot((max(g, 0)), float4(0.07278333, -0.018794727, -0.04362803, -0.011201734)), dot((max(g, 0)), float4(0.0756627, -0.031050753, -0.038904265, -0.01556625))) + (result);
	result = float3(dot((max(h, 0)), float4(-0.08261173, 0.043515377, -0.06262993, 0.026696987)), dot((max(h, 0)), float4(-0.09042543, 0.045066774, -0.07469342, 0.028740842)), dot((max(h, 0)), float4(-0.07589266, 0.04037769, -0.058593787, 0.037405368))) + (result);
	result = float3(dot((max(i, 0)), float4(0.07975598, -0.07844719, 0.05668995, -0.020040333)), dot((max(i, 0)), float4(0.09597654, -0.07880916, 0.050163813, -0.019867316)), dot((max(i, 0)), float4(0.08997132, -0.06835411, 0.053357534, -0.01907621))) + (result);
	result = float3(dot((max(-a, 0)), float4(-0.017078733, -0.0033478448, -0.06354017, -0.010787706)), dot((max(-a, 0)), float4(-0.017393313, -0.0027439648, -0.062058125, -0.0062706997)), dot((max(-a, 0)), float4(-0.008266595, -0.0042334674, -0.04652064, -0.007573461))) + (result);
	result = float3(dot((max(-b, 0)), float4(-0.019895451, 0.026231976, -0.061950512, -0.018804235)), dot((max(-b, 0)), float4(-0.016341688, 0.023955572, -0.05481285, -0.016235247)), dot((max(-b, 0)), float4(-0.008712399, 0.0216376, -0.05261985, -0.0131616965))) + (result);
	result = float3(dot((max(-c, 0)), float4(-0.055628926, -0.0256364, -0.017604912, -0.0870202)), dot((max(-c, 0)), float4(-0.063315354, -0.028660972, -0.020851422, -0.0832279)), dot((max(-c, 0)), float4(-0.057192408, -0.02937357, -0.016070362, -0.07525406))) + (result);
	result = float3(dot((max(-d, 0)), float4(0.062738225, -0.06068257, 0.024919355, -0.07866227)), dot((max(-d, 0)), float4(0.07106593, -0.06983662, 0.03227179, -0.098967604)), dot((max(-d, 0)), float4(0.061644047, -0.066070385, 0.028569462, -0.092128105))) + (result);
	result = float3(dot((max(-e, 0)), float4(0.040397774, -0.09112752, 0.10833967, 0.27189335)), dot((max(-e, 0)), float4(0.047241107, -0.10057507, 0.101835825, 0.27433604)), dot((max(-e, 0)), float4(0.03962998, -0.09301817, 0.10027467, 0.26781923))) + (result);
	result = float3(dot((max(-f, 0)), float4(-0.044211388, 0.113148406, -0.17081551, 0.09636739)), dot((max(-f, 0)), float4(-0.042373534, 0.12423258, -0.18562958, 0.10763415)), dot((max(-f, 0)), float4(-0.03658007, 0.107804194, -0.17475435, 0.093332425))) + (result);
	result = float3(dot((max(-g, 0)), float4(-0.03798545, 0.018775463, 0.0055677597, -0.10728597)), dot((max(-g, 0)), float4(-0.047811143, 0.026812987, 0.0039081173, -0.12618187)), dot((max(-g, 0)), float4(-0.050768293, 0.03452908, -0.0017878668, -0.109045394))) + (result);
	result = float3(dot((max(-h, 0)), float4(0.06359783, -0.009819327, 0.025055679, -0.047140837)), dot((max(-h, 0)), float4(0.064184755, -0.006616115, 0.024787048, -0.061695747)), dot((max(-h, 0)), float4(0.04934199, -0.007431496, 0.017360551, -0.06440822))) + (result);
	result = float3(dot((max(-i, 0)), float4(0.060199022, 0.026998974, 0.17968474, 0.0075838566)), dot((max(-i, 0)), float4(0.06482763, 0.028776823, 0.19337215, 0.010503482)), dot((max(-i, 0)), float4(0.059514645, 0.024897143, 0.16760105, 0.011993149))) + (result);
	result += tex2Dlod(SampInput, float4(pos, 0, 0)).rgb;
	Out4 = float4(result, 1.0);
}

technique Anime4K_Restore_S
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
