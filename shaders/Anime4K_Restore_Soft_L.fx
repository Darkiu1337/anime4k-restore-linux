// Anime4K Restore CNN (Soft_L) ported to ReShade FX.
// Source: Magpie Anime4K_Restore_Soft_L.hlsl <- bloc97/Anime4K glsl/Restore.
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

void Anime4K_VS(uint id : SV_VertexID, out float4 pos : SV_Position, out float2 uv : TEXCOORD0)
{
	uv = float2((id << 1) & 2, id & 2);
	pos = float4(uv * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}



void Anime4K_PS1a(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out1 : SV_Target0)
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
	float4 target1 = float4( -0.55533427, -0.05231614, -0.032685343, -0.027457517 );
	target1 = float4(dot((src00), float3(-0.2676983, 0.1850188, 0.026348969)), dot((src00), float3(-0.1694746, -0.4749505, -0.213702)), dot((src00), float3(0.7231928, 0.07632266, -0.16420218)), dot((src00), float3(-0.050193843, 0.17824799, -0.066780016))) + (target1);
	target1 = float4(dot((src01), float3(-0.09888135, -0.1368544, 0.19499005)), dot((src01), float3(-0.079641104, -0.07092336, 0.06811229)), dot((src01), float3(0.51160043, 0.18622977, -0.31991923)), dot((src01), float3(0.53629893, 0.6388427, 0.088302985))) + (target1);
	target1 = float4(dot((src02), float3(0.06487055, 0.1966732, -0.22231965)), dot((src02), float3(-0.1591197, 0.11229865, -0.008649182)), dot((src02), float3(-0.29304126, 0.089009434, 0.3317394)), dot((src02), float3(-0.428903, 0.23463708, 0.10976113))) + (target1);
	target1 = float4(dot((src10), float3(0.40386826, -0.28993917, -0.02661985)), dot((src10), float3(-0.09486362, -0.09050739, -0.24368657)), dot((src10), float3(-0.058931742, 0.28094417, 0.096867286)), dot((src10), float3(-0.1341693, 0.31630108, 0.05391612))) + (target1);
	target1 = float4(dot((src11), float3(0.05631564, 0.12679785, -0.22863568)), dot((src11), float3(0.34576723, 0.18991663, 0.20517963)), dot((src11), float3(-0.5587978, -0.24762277, 0.20418519)), dot((src11), float3(0.16213721, -0.33682153, 0.12087338))) + (target1);
	target1 = float4(dot((src12), float3(-0.17579688, -0.12778279, 0.2676877)), dot((src12), float3(0.18395603, -0.07003458, 0.255503)), dot((src12), float3(-0.014987654, -0.5353068, -0.29737592)), dot((src12), float3(0.30243605, -0.39372426, -0.30513638))) + (target1);
	target1 = float4(dot((src20), float3(0.799834, -0.1566225, 0.023661222)), dot((src20), float3(-0.023603538, -0.1937577, 0.16879195)), dot((src20), float3(0.19820727, -0.030266436, 0.046644643)), dot((src20), float3(-0.11204286, -0.10107911, 0.09485681))) + (target1);
	target1 = float4(dot((src21), float3(-0.014675849, 0.2067597, -0.09384791)), dot((src21), float3(-0.110290475, 0.20925248, 0.10593733)), dot((src21), float3(-0.28381273, -0.24068354, 0.0672362)), dot((src21), float3(-0.06814732, -0.5096708, -0.06924161))) + (target1);
	target1 = float4(dot((src22), float3(0.05908883, -0.091960385, -0.012630896)), dot((src22), float3(0.099426664, 0.3218613, -0.37540653)), dot((src22), float3(-0.20916614, 0.41635308, 0.018497325)), dot((src22), float3(-0.17044452, -0.36125022, -0.100674420))) + (target1);
	Out1 = target1;
}

void Anime4K_PS1b(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out2 : SV_Target0)
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
	float4 target2 = float4( 0.029685514, 0.066621915, 0.03600017, -0.03497038 );
	target2 = float4(dot((src00), float3(0.09844753, 0.1353029, -0.1097243)), dot((src00), float3(-0.19389127, 0.027786473, 0.021245124)), dot((src00), float3(0.029695928, 0.15621242, -0.016402386)), dot((src00), float3(0.3805915, 0.09383762, 0.09129394))) + (target2);
	target2 = float4(dot((src01), float3(0.3038283, -0.34829387, -0.260066)), dot((src01), float3(0.03778846, 0.20485392, 0.42611003)), dot((src01), float3(0.1898852, 0.60560244, 0.19227165)), dot((src01), float3(0.23949303, 0.4089768, 0.03948586))) + (target2);
	target2 = float4(dot((src02), float3(-0.033990905, -0.1001787, 0.0966166)), dot((src02), float3(0.17583308, 0.72851896, -0.016663829)), dot((src02), float3(-0.2235879, -0.056391567, -0.15151545)), dot((src02), float3(0.47376296, -0.056544185, -0.14227313))) + (target2);
	target2 = float4(dot((src10), float3(-0.16544957, 0.32491356, 0.27907088)), dot((src10), float3(0.05889452, -0.39113912, -0.22553465)), dot((src10), float3(-0.3277256, 0.16600312, 0.048548058)), dot((src10), float3(-0.42792717, -0.3097514, -0.08310438))) + (target2);
	target2 = float4(dot((src11), float3(0.03992136, -0.25868654, 0.020162001)), dot((src11), float3(0.17895368, -0.4869832, -0.41568524)), dot((src11), float3(0.16562924, 0.2591772, 0.4776641)), dot((src11), float3(-0.536188, -0.5191932, 0.019298514))) + (target2);
	target2 = float4(dot((src12), float3(0.14911795, -0.69194865, -0.21318413)), dot((src12), float3(-0.5984171, 0.033839397, 0.53743845)), dot((src12), float3(-0.18241958, 0.13408412, 0.080091774)), dot((src12), float3(0.5472136, 0.09503547, -0.1369053))) + (target2);
	target2 = float4(dot((src20), float3(-0.038978565, 0.227634, 0.17923234)), dot((src20), float3(0.40742934, -0.16101603, -0.13692904)), dot((src20), float3(0.20107205, -0.45037574, 0.10395048)), dot((src20), float3(-0.3550106, 0.23192371, 0.3124129))) + (target2);
	target2 = float4(dot((src21), float3(-0.059144646, 0.58086175, 0.24317528)), dot((src21), float3(-0.22531863, -0.32206532, 0.088735096)), dot((src21), float3(-0.024704054, -0.5130457, -0.44098017)), dot((src21), float3(-0.20749553, -0.14057957, -0.16980846))) + (target2);
	target2 = float4(dot((src22), float3(-0.30321437, 0.1465326, -0.23306467)), dot((src22), float3(0.17502202, 0.3852395, -0.28551704)), dot((src22), float3(0.1910563, -0.31210947, -0.2982589)), dot((src22), float3(-0.10118702, 0.18236226, 0.072740674))) + (target2);
	Out2 = target2;
}

void Anime4K_PS2a(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out3 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 pos = (float2(pix) + 0.5) * rcp;
	float4 a1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d1 = tex2Dlod(SampT1, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e1 = tex2Dlod(SampT1, float4(pos, 0, 0));
	float4 f1 = tex2Dlod(SampT1, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na1 = max(-a1, 0);
	float4 nb1 = max(-b1, 0);
	float4 nc1 = max(-c1, 0);
	float4 nd1 = max(-d1, 0);
	float4 ne1 = max(-e1, 0);
	float4 nf1 = max(-f1, 0);
	float4 ng1 = max(-g1, 0);
	float4 nh1 = max(-h1, 0);
	float4 ni1 = max(-i1, 0);
	a1 = max(a1, 0);
	b1 = max(b1, 0);
	c1 = max(c1, 0);
	d1 = max(d1, 0);
	e1 = max(e1, 0);
	f1 = max(f1, 0);
	g1 = max(g1, 0);
	h1 = max(h1, 0);
	i1 = max(i1, 0);
	float4 a2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d2 = tex2Dlod(SampT2, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e2 = tex2Dlod(SampT2, float4(pos, 0, 0));
	float4 f2 = tex2Dlod(SampT2, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na2 = max(-a2, 0);
	float4 nb2 = max(-b2, 0);
	float4 nc2 = max(-c2, 0);
	float4 nd2 = max(-d2, 0);
	float4 ne2 = max(-e2, 0);
	float4 nf2 = max(-f2, 0);
	float4 ng2 = max(-g2, 0);
	float4 nh2 = max(-h2, 0);
	float4 ni2 = max(-i2, 0);
	a2 = max(a2, 0);
	b2 = max(b2, 0);
	c2 = max(c2, 0);
	d2 = max(d2, 0);
	e2 = max(e2, 0);
	f2 = max(f2, 0);
	g2 = max(g2, 0);
	h2 = max(h2, 0);
	i2 = max(i2, 0);
	float4 target1 = float4( -0.045150407, -0.034128085, 0.10230384, 0.074793644 );
	target1 = float4(dot((a1), float4(0.20989326, 0.013517254, 0.01066957, -0.20921241)), dot((a1), float4(0.020975577, -0.03347422, 0.2569982, -0.3565134)), dot((a1), float4(-0.005522964, 0.40903455, -0.018764338, 0.1776639)), dot((a1), float4(-0.10013134, 0.013940953, -0.37931216, 0.081515394))) + (target1);
	target1 = float4(dot((b1), float4(-0.2555968, -0.21787676, -0.042842478, 0.062092766)), dot((b1), float4(-0.05024504, 0.0013136056, -0.10413157, -0.40029097)), dot((b1), float4(0.046776827, -0.13391882, -0.008385445, 0.31873867)), dot((b1), float4(0.38626888, 0.00022813173, -0.11843704, -0.19030346))) + (target1);
	target1 = float4(dot((c1), float4(-0.19435422, -0.0677575, -0.16890685, 0.0002810964)), dot((c1), float4(-0.56006145, -0.30498, 0.04575225, 0.0772843)), dot((c1), float4(0.050693467, 0.012069988, -0.08477036, 0.00017034424)), dot((c1), float4(-0.8857939, 0.026757652, -0.018015383, -0.228497))) + (target1);
	target1 = float4(dot((d1), float4(0.092564344, 0.1670116, -0.06338295, 0.045575716)), dot((d1), float4(0.061863884, -0.08312144, -0.09972319, 0.12836345)), dot((d1), float4(-0.13135873, -0.020718448, 0.18505506, -0.22356766)), dot((d1), float4(0.10290956, 0.06729496, -0.2622095, 0.28924033))) + (target1);
	target1 = float4(dot((e1), float4(0.23605964, -0.122640595, 0.07847812, 0.24583417)), dot((e1), float4(0.46831363, -0.29213053, 0.3094049, 0.3703223)), dot((e1), float4(0.21037713, 0.14194407, -0.050705243, 0.1121086)), dot((e1), float4(0.3901851, -0.3353137, -0.23498294, 0.20645288))) + (target1);
	target1 = float4(dot((f1), float4(-0.08616125, -0.20682202, -0.097444884, -0.12802023)), dot((f1), float4(-0.13809866, 0.01106275, -0.03766069, 0.1988174)), dot((f1), float4(0.27488732, -0.018731792, -0.12636039, 0.19551867)), dot((f1), float4(0.19573413, 0.048580807, 0.3133589, -0.2720954))) + (target1);
	target1 = float4(dot((g1), float4(0.03484159, 0.15579484, -0.35857964, 0.071555324)), dot((g1), float4(0.05830728, -0.07751753, 0.1043378, -0.24148308)), dot((g1), float4(0.028816089, -0.033748254, 0.5031367, -0.24156207)), dot((g1), float4(0.27173883, 0.22559631, 0.031042032, 0.104249395))) + (target1);
	target1 = float4(dot((h1), float4(0.04002337, 0.2917599, 0.069034904, -0.23043779)), dot((h1), float4(-0.17350379, 0.1801853, 0.19370675, 0.33832225)), dot((h1), float4(-0.1802324, 0.041955303, 0.097300164, -0.029885143)), dot((h1), float4(-0.23008482, 0.015545025, 0.11832116, -0.022836795))) + (target1);
	target1 = float4(dot((i1), float4(0.040476788, 0.28147677, -0.23415963, 0.06337683)), dot((i1), float4(0.3176767, -0.06513699, -0.067057185, -0.1774192)), dot((i1), float4(-0.2372066, -0.22784042, -0.013863767, 0.05082387)), dot((i1), float4(0.24106048, -0.46840426, 0.30710638, -0.02581459))) + (target1);
	target1 = float4(dot((a2), float4(-0.13767451, -0.22070843, 0.3302224, -0.049211837)), dot((a2), float4(0.26832962, 0.10799693, 0.10916339, 0.19487813)), dot((a2), float4(0.018361554, 0.09780551, -0.22705203, 0.051528033)), dot((a2), float4(0.2665501, 0.042999722, 0.040675506, 0.20227027))) + (target1);
	target1 = float4(dot((b2), float4(0.1279485, 0.09898892, -0.096799396, 0.12410443)), dot((b2), float4(0.14895418, 0.035774715, -0.12336552, 0.27200332)), dot((b2), float4(0.40570346, -0.28405192, -0.24413097, -0.18279982)), dot((b2), float4(-0.008809808, 0.26836014, 0.12693845, -0.032115027))) + (target1);
	target1 = float4(dot((c2), float4(0.14698029, 0.09503049, -0.004227005, -0.14852846)), dot((c2), float4(-0.31720948, -0.02618792, -0.2564904, -0.3513046)), dot((c2), float4(0.24974433, 0.15163966, -0.06648419, -0.1374295)), dot((c2), float4(0.14444488, 0.22923012, -0.07868524, -0.09808154))) + (target1);
	target1 = float4(dot((d2), float4(0.1275583, -0.25886494, 0.06420735, -0.2256255)), dot((d2), float4(0.1875862, -0.07434281, 0.0025367932, 0.26216295)), dot((d2), float4(-0.15939887, -0.018779758, 0.073679835, -0.052095387)), dot((d2), float4(-0.1029876, -0.008408217, 0.1369152, 0.04673847))) + (target1);
	target1 = float4(dot((e2), float4(0.1147465, 0.031286925, -0.00039004904, -0.042392768)), dot((e2), float4(0.14129257, -0.00013609273, 0.01673792, 0.23993582)), dot((e2), float4(-0.036377613, -0.248227, 0.056068443, -0.22915693)), dot((e2), float4(0.041968875, 0.10412182, -0.16470632, 0.36430097))) + (target1);
	target1 = float4(dot((f2), float4(0.23650797, 0.04389849, -0.10636852, 0.20775628)), dot((f2), float4(0.12200628, -0.11567954, -0.115114085, -0.1127031)), dot((f2), float4(0.057768486, -0.12633252, -0.0022040834, -0.060805347)), dot((f2), float4(0.23353462, -0.1884369, 0.041720822, -0.10988217))) + (target1);
	target1 = float4(dot((g2), float4(0.0401325, -0.12597936, 0.14655456, -0.043001004)), dot((g2), float4(-0.271267, -0.059235968, 0.07416407, 0.2124355)), dot((g2), float4(-0.3003843, 0.08256807, -0.03940599, 0.19165096)), dot((g2), float4(0.010670003, -0.22041298, -0.25057787, 0.077120975))) + (target1);
	target1 = float4(dot((h2), float4(0.01693656, -0.07157646, -0.113005005, 0.28891653)), dot((h2), float4(-0.057261657, -0.12266521, -0.15769142, 0.06013908)), dot((h2), float4(-0.13366276, 0.24651442, -0.017285366, 0.0038421913)), dot((h2), float4(-0.15589137, -0.079142615, 0.08821278, 0.106700204))) + (target1);
	target1 = float4(dot((i2), float4(0.16187043, 0.12749411, 0.03188715, 0.1051409)), dot((i2), float4(-0.059908718, -0.07558445, 0.056223337, 0.0011876151)), dot((i2), float4(-0.050456535, 0.05249467, 0.06117334, -0.07030176)), dot((i2), float4(-0.027998367, 0.02001542, 0.022764465, -0.015487096))) + (target1);
	target1 = float4(dot((na1), float4(0.047084607, 0.025441, -0.09186016, 0.3175809)), dot((na1), float4(0.06401777, -0.020858578, -0.16865493, 0.25483596)), dot((na1), float4(0.15585798, -0.07795479, 0.02187216, 0.046578035)), dot((na1), float4(0.16639893, -0.0045188745, 0.02241868, -0.09617824))) + (target1);
	target1 = float4(dot((nb1), float4(0.08622112, 0.26907462, -0.10869113, -0.1307433)), dot((nb1), float4(0.124111585, -0.15550381, 0.113909826, 0.044969033)), dot((nb1), float4(-0.15246506, 0.036907334, -0.118678264, -0.053201765)), dot((nb1), float4(-0.072898194, -0.16388376, 0.013610441, -0.058903012))) + (target1);
	target1 = float4(dot((nc1), float4(0.036120024, 0.016460553, 0.10511601, -0.046095166)), dot((nc1), float4(-0.011461657, 0.1781498, 0.12667589, -0.15012313)), dot((nc1), float4(-0.10083318, 0.15133101, 0.15001541, -0.009395591)), dot((nc1), float4(-0.334466, -0.0010224655, 0.14479756, 0.019260757))) + (target1);
	target1 = float4(dot((nd1), float4(0.04500625, -0.17360263, -0.11408359, -0.058175903)), dot((nd1), float4(-0.037348565, -0.18522957, 0.057783633, 0.0040344223)), dot((nd1), float4(-0.10475762, 0.014305901, -0.028000865, 0.11234911)), dot((nd1), float4(0.113254204, 0.07039716, -0.25506407, -0.07254186))) + (target1);
	target1 = float4(dot((ne1), float4(0.05607878, 0.1729392, -0.1374591, -0.30330884)), dot((ne1), float4(-0.07737156, -0.09273287, -0.09428349, -0.039166123)), dot((ne1), float4(0.01586671, 0.14671144, 0.28138107, -0.18316704)), dot((ne1), float4(-0.21907675, 0.21306099, 0.08421483, -0.27840406))) + (target1);
	target1 = float4(dot((nf1), float4(-0.15336679, 0.09895612, -0.101612955, 0.056127027)), dot((nf1), float4(-0.05767407, -0.0839073, 0.4119443, -0.04000313)), dot((nf1), float4(0.13347702, -0.16025528, 0.031125817, -0.042920932)), dot((nf1), float4(0.10092905, -0.087642424, -0.110090934, 0.08100733))) + (target1);
	target1 = float4(dot((ng1), float4(-0.113653034, -0.20110545, 0.18334186, -0.13593355)), dot((ng1), float4(-0.10163741, -0.006300695, 0.15882389, 0.11897087)), dot((ng1), float4(-0.058498476, -0.1328342, -0.120586954, 0.030404912)), dot((ng1), float4(-0.12347642, -0.0071486877, -0.04277906, -0.23374279))) + (target1);
	target1 = float4(dot((nh1), float4(0.044901595, 0.23985633, 0.017398749, 0.0074833618)), dot((nh1), float4(-0.00010039519, 0.0114784185, 0.3567445, -0.16702464)), dot((nh1), float4(-0.14989527, 0.056620862, 0.10223932, -0.033638544)), dot((nh1), float4(0.025639903, -0.0599113, -0.12609181, 0.062087793))) + (target1);
	target1 = float4(dot((ni1), float4(-0.0302778, 0.26467612, 0.03599952, 0.05582198)), dot((ni1), float4(-0.009963125, -0.19331805, 0.24224155, 0.0012778769)), dot((ni1), float4(0.29761076, -0.09930472, 0.3041322, 0.041249134)), dot((ni1), float4(0.08238972, 0.23798122, -0.054690234, -0.014496484))) + (target1);
	target1 = float4(dot((na2), float4(-0.033623356, 0.16657802, -0.40347067, 0.0444492)), dot((na2), float4(-0.18683043, -0.31149274, 0.046952717, -0.012346084)), dot((na2), float4(-0.48352727, -0.25840783, 0.15677738, -0.16768047)), dot((na2), float4(-0.09534184, -0.16902964, -0.14079048, -0.07540055))) + (target1);
	target1 = float4(dot((nb2), float4(0.2678487, -0.28154588, 0.12565655, 0.058234677)), dot((nb2), float4(0.113161474, -0.06956369, 0.5497286, 0.049816858)), dot((nb2), float4(-0.19962314, 0.08050926, -0.18335307, -0.021038791)), dot((nb2), float4(0.23060325, -0.25503877, -0.044097837, 0.14644346))) + (target1);
	target1 = float4(dot((nc2), float4(-0.008438418, 0.11905285, 0.041182615, 0.11789433)), dot((nc2), float4(0.080761805, 0.016726421, 0.2760306, 0.094213605)), dot((nc2), float4(0.06993718, -0.16668561, 0.18553418, 0.15487063)), dot((nc2), float4(0.08508105, 0.026911844, 0.25386074, 0.15375367))) + (target1);
	target1 = float4(dot((nd2), float4(-0.10329284, 0.4592297, 0.043646853, 0.44923568)), dot((nd2), float4(0.16198465, -0.12816279, 0.084326275, -0.01125437)), dot((nd2), float4(-0.0681889, 0.19529971, 0.0635968, -0.19251052)), dot((nd2), float4(-0.006294233, 0.109294996, -0.11471805, -0.08885202))) + (target1);
	target1 = float4(dot((ne2), float4(-0.108986676, -0.10438951, 0.17497768, 0.02700953)), dot((ne2), float4(0.40908077, -0.086357035, -0.08021166, -0.016387407)), dot((ne2), float4(-0.31152573, 0.13880713, 0.07815909, 0.0053377734)), dot((ne2), float4(-0.13468693, -0.288345, 0.17337689, 0.109923586))) + (target1);
	target1 = float4(dot((nf2), float4(0.13881513, -0.3383386, -0.035691183, -0.0035024916)), dot((nf2), float4(-0.21179448, 0.14453639, 0.21306588, -0.054061864)), dot((nf2), float4(-0.104762904, -0.28122503, -0.046144057, -0.03985455)), dot((nf2), float4(0.019093828, 0.19449967, 0.17898172, 0.3264588))) + (target1);
	target1 = float4(dot((ng2), float4(0.02336507, -0.042182084, -0.17958918, 0.19511287)), dot((ng2), float4(0.20597245, -0.26431814, 0.050698034, -0.20311548)), dot((ng2), float4(0.03627631, 0.122881256, 0.336547, -0.13249207)), dot((ng2), float4(0.04278966, 0.34909293, 0.21614759, -0.24043573))) + (target1);
	target1 = float4(dot((nh2), float4(-0.025547924, -0.044973124, 0.14618309, -0.27103037)), dot((nh2), float4(0.020525696, 0.13667387, 0.108213425, 0.12428249)), dot((nh2), float4(0.375233, -0.08506365, 0.15557359, -0.085362)), dot((nh2), float4(-0.02528368, 0.34317508, -0.05340479, -0.009073445))) + (target1);
	target1 = float4(dot((ni2), float4(-0.09518274, -0.20793489, -0.033398125, -0.11993404)), dot((ni2), float4(0.036228243, 0.19843313, -0.020169621, 0.12495525)), dot((ni2), float4(-0.2145168, 0.06701371, 0.057314273, -0.0151242195)), dot((ni2), float4(0.090918355, -0.11499378, 0.0027613493, 0.1896457))) + (target1);
	float4 target2 = float4( 0.0031252617, 0.028414045, -0.018389644, 0.011216021 );
	Out3 = target1;
}

void Anime4K_PS2b(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out4 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 pos = (float2(pix) + 0.5) * rcp;
	float4 a1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d1 = tex2Dlod(SampT1, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e1 = tex2Dlod(SampT1, float4(pos, 0, 0));
	float4 f1 = tex2Dlod(SampT1, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na1 = max(-a1, 0);
	float4 nb1 = max(-b1, 0);
	float4 nc1 = max(-c1, 0);
	float4 nd1 = max(-d1, 0);
	float4 ne1 = max(-e1, 0);
	float4 nf1 = max(-f1, 0);
	float4 ng1 = max(-g1, 0);
	float4 nh1 = max(-h1, 0);
	float4 ni1 = max(-i1, 0);
	a1 = max(a1, 0);
	b1 = max(b1, 0);
	c1 = max(c1, 0);
	d1 = max(d1, 0);
	e1 = max(e1, 0);
	f1 = max(f1, 0);
	g1 = max(g1, 0);
	h1 = max(h1, 0);
	i1 = max(i1, 0);
	float4 a2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d2 = tex2Dlod(SampT2, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e2 = tex2Dlod(SampT2, float4(pos, 0, 0));
	float4 f2 = tex2Dlod(SampT2, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na2 = max(-a2, 0);
	float4 nb2 = max(-b2, 0);
	float4 nc2 = max(-c2, 0);
	float4 nd2 = max(-d2, 0);
	float4 ne2 = max(-e2, 0);
	float4 nf2 = max(-f2, 0);
	float4 ng2 = max(-g2, 0);
	float4 nh2 = max(-h2, 0);
	float4 ni2 = max(-i2, 0);
	a2 = max(a2, 0);
	b2 = max(b2, 0);
	c2 = max(c2, 0);
	d2 = max(d2, 0);
	e2 = max(e2, 0);
	f2 = max(f2, 0);
	g2 = max(g2, 0);
	h2 = max(h2, 0);
	i2 = max(i2, 0);
	float4 target1 = float4( -0.045150407, -0.034128085, 0.10230384, 0.074793644 );
	float4 target2 = float4( 0.0031252617, 0.028414045, -0.018389644, 0.011216021 );
	target2 = float4(dot((a1), float4(0.10541986, 0.0712113, -0.07754299, -0.008200866)), dot((a1), float4(-0.27021417, -0.5818028, 0.009050975, 0.53291875)), dot((a1), float4(0.30589217, -0.09057832, -0.08283811, 0.22918138)), dot((a1), float4(-0.06793019, 0.009519015, -0.078837596, 0.09433025))) + (target2);
	target2 = float4(dot((b1), float4(0.35867104, 0.054377224, -0.052365527, -0.15472592)), dot((b1), float4(0.17056245, 0.30656826, -0.17660435, -0.011637987)), dot((b1), float4(0.28573632, -0.13864343, -0.14363506, 0.3057005)), dot((b1), float4(0.45787787, 0.13956884, -0.11313267, 0.40122506))) + (target2);
	target2 = float4(dot((c1), float4(-0.42738816, -0.14648326, 0.00401621, 0.04891574)), dot((c1), float4(-0.13046122, 0.056164477, -0.008206323, 0.08912198)), dot((c1), float4(-0.4223082, 0.09366789, -0.075975314, 0.32541895)), dot((c1), float4(0.32663476, -0.046335716, 0.046879925, 0.014354832))) + (target2);
	target2 = float4(dot((d1), float4(0.105501, -0.10643463, -0.1698376, -0.031917162)), dot((d1), float4(-0.06999185, 0.061667755, -0.05051473, 0.046488285)), dot((d1), float4(-0.023181506, 0.24508677, -0.29430416, 0.17973569)), dot((d1), float4(0.13587391, 0.33984032, -0.06635265, -0.025048103))) + (target2);
	target2 = float4(dot((e1), float4(-0.07685088, 0.17084605, -0.047398012, 0.2513805)), dot((e1), float4(-0.035609607, -0.19758354, 0.12004138, 0.13687916)), dot((e1), float4(0.07060013, -0.29233304, 0.1643941, 0.23235638)), dot((e1), float4(-0.19892506, -0.19821644, 0.043807004, 0.00979058))) + (target2);
	target2 = float4(dot((f1), float4(-0.2601253, -0.042538162, -0.03908205, -0.021913078)), dot((f1), float4(-0.0010056786, -0.012710203, 0.104053, -0.0035067864)), dot((f1), float4(-0.46147683, -0.034079336, -0.045735247, -0.10581172)), dot((f1), float4(-0.117661044, -0.08661733, -0.07916684, 0.1149))) + (target2);
	target2 = float4(dot((g1), float4(0.0421786, -0.084229656, 0.07743771, -0.1602913)), dot((g1), float4(0.0099540735, 0.04271779, -0.109369494, -0.10049883)), dot((g1), float4(-0.020447837, 0.036794372, -0.07608079, 0.033048846)), dot((g1), float4(-0.27269018, -0.18072419, 0.2973058, -0.3780618))) + (target2);
	target2 = float4(dot((h1), float4(-0.38231418, 0.093251124, -0.047867708, 0.10045314)), dot((h1), float4(0.106174126, -0.07658309, 0.0097399205, -0.030283177)), dot((h1), float4(0.07344471, 0.08417288, -0.11213339, 0.004107288)), dot((h1), float4(-0.1979349, 0.2981472, 0.1746439, -0.16744147))) + (target2);
	target2 = float4(dot((i1), float4(0.43939134, 0.098075844, 0.112658866, 0.017880073)), dot((i1), float4(0.14499938, 0.22099596, -0.12010951, 0.028821323)), dot((i1), float4(0.20161533, 0.099283025, -0.13342896, 0.0082069365)), dot((i1), float4(-0.0067911143, -0.017734041, 0.053806942, -0.053472634))) + (target2);
	target2 = float4(dot((a2), float4(0.2429229, 0.11972611, -0.18222691, 0.0842879)), dot((a2), float4(0.012143042, -0.07733264, -0.31171882, 0.12601142)), dot((a2), float4(-0.029962441, -0.37523645, -0.20578085, -0.07302166)), dot((a2), float4(0.017843649, -0.19887479, 0.040127717, -0.033017557))) + (target2);
	target2 = float4(dot((b2), float4(0.09666541, -0.046158988, 0.12464106, -0.15057011)), dot((b2), float4(-0.053779975, -0.12819108, -0.42395857, -0.041440632)), dot((b2), float4(-0.045221806, -0.32956856, 0.078095086, 0.04221429)), dot((b2), float4(-0.06923458, -0.15813568, -0.12961964, 0.08509352))) + (target2);
	target2 = float4(dot((c2), float4(0.2505401, 0.044663083, -0.13285598, -0.036615327)), dot((c2), float4(0.023106987, -0.011316191, -0.026969459, 0.06434473)), dot((c2), float4(-0.0001688444, -0.024175104, 0.02669494, -0.059197906)), dot((c2), float4(-0.11545978, 0.033631656, 0.082885765, -0.110084))) + (target2);
	target2 = float4(dot((d2), float4(-0.12549014, 0.13844866, -0.09028008, 0.05188703)), dot((d2), float4(0.25078717, 0.012716272, -0.15924782, -0.12323306)), dot((d2), float4(-0.06146062, 0.07641059, -0.14551707, -0.20053494)), dot((d2), float4(0.1406611, 0.04245357, -0.09782215, -0.20062317))) + (target2);
	target2 = float4(dot((e2), float4(-0.26341316, -0.3016191, 0.14551535, 0.059902433)), dot((e2), float4(-0.16508758, 0.06403582, -0.09222706, -0.17293817)), dot((e2), float4(0.036919586, 0.12948476, -0.30942333, -0.07280857)), dot((e2), float4(-0.17812039, 0.110633194, 0.20120445, -0.36021966))) + (target2);
	target2 = float4(dot((f2), float4(0.11032128, -0.23266938, -0.13652846, -0.043844085)), dot((f2), float4(-0.024297172, -0.009982061, -0.025019212, 0.02440773)), dot((f2), float4(-0.110301405, 0.18834652, 0.07672643, -0.029404791)), dot((f2), float4(-0.09563319, 0.0987435, 0.017108513, 0.034692347))) + (target2);
	target2 = float4(dot((g2), float4(-0.048525557, 0.16658829, -0.1755198, 0.01661835)), dot((g2), float4(-0.043118346, 0.19444555, -0.038910154, 0.28915378)), dot((g2), float4(0.12048513, 0.113910906, 0.084356636, -0.032290917)), dot((g2), float4(0.030609682, 0.31148425, 0.12969102, -0.12997934))) + (target2);
	target2 = float4(dot((h2), float4(-0.24347968, 0.0901479, 0.16361152, 0.20710163)), dot((h2), float4(0.032619976, 0.060802385, 0.19639444, 0.076565325)), dot((h2), float4(0.16692804, 0.21347383, 0.0054137907, 0.34911337)), dot((h2), float4(-0.046297006, 0.29304698, 0.049575172, 0.35831028))) + (target2);
	target2 = float4(dot((i2), float4(-0.092651226, -0.27768722, 0.0051228474, -0.1053527)), dot((i2), float4(0.045491215, 0.010231745, -0.04532887, -0.00010417442)), dot((i2), float4(0.11757575, 0.21116765, -0.013311027, -0.035180032)), dot((i2), float4(0.11756375, 0.024840422, 0.121157385, 0.2051271))) + (target2);
	target2 = float4(dot((na1), float4(-0.055320628, -0.043079898, -0.09394785, -0.03233552)), dot((na1), float4(0.14249797, -0.18216185, 0.12044827, 0.16400962)), dot((na1), float4(-0.13782813, 0.13923723, -0.05177875, -0.11219184)), dot((na1), float4(-0.05412119, -0.11468015, 0.1349153, 0.09460802))) + (target2);
	target2 = float4(dot((nb1), float4(-0.018258873, 0.024990926, -0.062110204, -0.05727847)), dot((nb1), float4(-0.23629102, -0.31095183, 0.24764718, -0.006963949)), dot((nb1), float4(-0.140925, 0.21505022, 0.0018352414, -0.23087887)), dot((nb1), float4(0.10609654, 0.0007466126, 0.03383791, -0.2521535))) + (target2);
	target2 = float4(dot((nc1), float4(-0.08928898, 0.1569246, 0.034223706, -0.09508409)), dot((nc1), float4(0.21107556, -0.07950364, -0.1124521, -0.03837469)), dot((nc1), float4(0.27720314, -0.035353288, 0.068468235, -0.19909252)), dot((nc1), float4(0.3170095, 0.0851358, -0.1876728, 0.09844746))) + (target2);
	target2 = float4(dot((nd1), float4(0.04326774, 0.14155331, 0.15166105, 0.114750795)), dot((nd1), float4(-0.063746035, -0.21800575, 0.086240664, 0.19737157)), dot((nd1), float4(0.13767312, -0.22868122, 0.110339195, -0.09005264)), dot((nd1), float4(0.048762802, -0.10928361, -0.0039928076, -0.10637459))) + (target2);
	target2 = float4(dot((ne1), float4(0.023298614, -0.017949682, 0.03870307, 0.00049597165)), dot((ne1), float4(0.07140441, 0.007795148, -0.067750655, -0.18959905)), dot((ne1), float4(0.029475417, -0.044714145, -0.11831945, -0.20256434)), dot((ne1), float4(-0.14667986, -0.13990426, -0.14363948, 0.0409640))) + (target2);
	target2 = float4(dot((nf1), float4(0.18983524, -0.12528846, 0.02577546, 0.045207195)), dot((nf1), float4(0.07018097, -0.020557154, -0.25885943, 0.019213859)), dot((nf1), float4(0.015068278, 0.0106482245, 0.0061467723, -0.021913687)), dot((nf1), float4(-0.17990883, 0.08105856, -0.058998212, -0.10641617))) + (target2);
	target2 = float4(dot((ng1), float4(-0.005021213, 0.13006134, 0.1283007, 0.0611477)), dot((ng1), float4(-0.030781588, 0.03640675, 0.053212877, 0.060609598)), dot((ng1), float4(-0.08722711, -0.18160394, 0.15160874, -0.21533446)), dot((ng1), float4(0.045172613, 0.10903534, -0.30678773, 0.2817914))) + (target2);
	target2 = float4(dot((nh1), float4(-0.06942382, -0.0988795, -0.1873821, -0.16819417)), dot((nh1), float4(-0.08785516, 0.021093542, -0.15041956, 0.07222907)), dot((nh1), float4(-0.018080644, 0.015752183, 0.12230656, -0.01441512)), dot((nh1), float4(0.12124481, 0.057520576, -0.23798561, 0.06420038))) + (target2);
	target2 = float4(dot((ni1), float4(-0.0350732, -0.0671371, 0.11239629, 0.09723501)), dot((ni1), float4(-0.054145966, 0.057495046, -0.19681981, -0.12488112)), dot((ni1), float4(0.008372502, -0.08276416, 0.16116115, -0.031532682)), dot((ni1), float4(-0.16092199, 0.34617814, 0.046944335, 0.013095191))) + (target2);
	target2 = float4(dot((na2), float4(-0.2309171, -0.20740104, 0.08665683, 0.07108977)), dot((na2), float4(0.10420613, -0.010152015, -0.18393658, -0.28212613)), dot((na2), float4(-0.12122516, 0.26092738, -0.030344693, 0.024101965)), dot((na2), float4(-0.04000454, 0.13527256, -0.10654187, -0.22189055))) + (target2);
	target2 = float4(dot((nb2), float4(0.06602971, -0.13822217, -0.1175651, 0.20007257)), dot((nb2), float4(0.050674047, -0.014285523, 0.11234997, 0.21565825)), dot((nb2), float4(0.33251405, 0.22478761, -0.17835312, 0.30876723)), dot((nb2), float4(-0.07886978, 0.22517748, 0.010875831, -0.029953295))) + (target2);
	target2 = float4(dot((nc2), float4(0.3083618, -0.123584166, 0.30604517, 0.16092177)), dot((nc2), float4(0.12779777, 0.03232661, -0.19359338, -0.07926006)), dot((nc2), float4(0.112711206, -0.060439207, -0.115064435, -0.27355558)), dot((nc2), float4(0.001815444, -0.13411477, -0.03826723, 0.077829085))) + (target2);
	target2 = float4(dot((nd2), float4(-0.020265967, 0.20102961, -0.01132585, -0.15850788)), dot((nd2), float4(-0.27894706, 0.024541473, -0.16459125, 0.16646145)), dot((nd2), float4(-0.105033666, 0.21834314, 0.21980706, 0.10387183)), dot((nd2), float4(-0.10975655, -0.21726306, 0.039996378, -0.35103965))) + (target2);
	target2 = float4(dot((ne2), float4(-0.038195442, 0.06056814, -0.45779508, -0.096611015)), dot((ne2), float4(0.02967505, 0.14282827, -0.3667849, 0.12282537)), dot((ne2), float4(-0.22234862, -0.26034078, 0.22392158, 0.080877006)), dot((ne2), float4(-0.040221542, 0.32477978, 0.09866475, -0.038721707))) + (target2);
	target2 = float4(dot((nf2), float4(0.12205649, -0.24082763, 0.049058694, 0.12703685)), dot((nf2), float4(0.052729234, -0.008418334, 0.046168383, 0.020337742)), dot((nf2), float4(0.09086409, -0.24735104, -0.049963474, -0.20470645)), dot((nf2), float4(0.13457046, 0.13281673, 0.09272115, -0.07379872))) + (target2);
	target2 = float4(dot((ng2), float4(0.02244616, 0.14189804, 0.055331856, -0.15860988)), dot((ng2), float4(0.058318693, -0.0016504574, 0.0030448188, -0.10147442)), dot((ng2), float4(-0.05570221, 0.018723257, 0.01664426, 0.115529425)), dot((ng2), float4(-0.02717316, -0.05787106, 0.080254346, -0.12332509))) + (target2);
	target2 = float4(dot((nh2), float4(0.16019078, -0.04840569, -0.10423932, -0.075027406)), dot((nh2), float4(-0.20631735, 0.083106056, -0.12388437, -0.12183809)), dot((nh2), float4(-0.018190302, -0.13247506, 0.1951962, -0.07161853)), dot((nh2), float4(0.0647328, -0.2112572, 0.15236832, -0.24558437))) + (target2);
	target2 = float4(dot((ni2), float4(-0.06832158, 0.22054252, -0.019737093, 0.0616053)), dot((ni2), float4(0.06699966, -0.03332688, 0.1890527, -0.046331815)), dot((ni2), float4(-0.17887384, -0.089027286, 0.3194981, -0.013838972)), dot((ni2), float4(0.025053928, -0.0743864, -0.014847898, -0.19598661))) + (target2);
	Out4 = target2;
}

void Anime4K_PS3a(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out5 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 pos = (float2(pix) + 0.5) * rcp;
	float4 a1 = tex2Dlod(SampT3, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b1 = tex2Dlod(SampT3, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c1 = tex2Dlod(SampT3, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d1 = tex2Dlod(SampT3, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e1 = tex2Dlod(SampT3, float4(pos, 0, 0));
	float4 f1 = tex2Dlod(SampT3, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g1 = tex2Dlod(SampT3, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h1 = tex2Dlod(SampT3, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i1 = tex2Dlod(SampT3, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na1 = max(-a1, 0);
	float4 nb1 = max(-b1, 0);
	float4 nc1 = max(-c1, 0);
	float4 nd1 = max(-d1, 0);
	float4 ne1 = max(-e1, 0);
	float4 nf1 = max(-f1, 0);
	float4 ng1 = max(-g1, 0);
	float4 nh1 = max(-h1, 0);
	float4 ni1 = max(-i1, 0);
	a1 = max(a1, 0);
	b1 = max(b1, 0);
	c1 = max(c1, 0);
	d1 = max(d1, 0);
	e1 = max(e1, 0);
	f1 = max(f1, 0);
	g1 = max(g1, 0);
	h1 = max(h1, 0);
	i1 = max(i1, 0);
	float4 a2 = tex2Dlod(SampT4, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b2 = tex2Dlod(SampT4, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c2 = tex2Dlod(SampT4, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d2 = tex2Dlod(SampT4, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e2 = tex2Dlod(SampT4, float4(pos, 0, 0));
	float4 f2 = tex2Dlod(SampT4, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g2 = tex2Dlod(SampT4, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h2 = tex2Dlod(SampT4, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i2 = tex2Dlod(SampT4, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na2 = max(-a2, 0);
	float4 nb2 = max(-b2, 0);
	float4 nc2 = max(-c2, 0);
	float4 nd2 = max(-d2, 0);
	float4 ne2 = max(-e2, 0);
	float4 nf2 = max(-f2, 0);
	float4 ng2 = max(-g2, 0);
	float4 nh2 = max(-h2, 0);
	float4 ni2 = max(-i2, 0);
	a2 = max(a2, 0);
	b2 = max(b2, 0);
	c2 = max(c2, 0);
	d2 = max(d2, 0);
	e2 = max(e2, 0);
	f2 = max(f2, 0);
	g2 = max(g2, 0);
	h2 = max(h2, 0);
	i2 = max(i2, 0);
	float4 target1 = float4( -0.16255508, -0.041602854, 0.09628627, 0.12747966 );
	target1 = float4(dot((a1), float4(0.1156422, -0.13118152, -0.057555363, -0.12577637)), dot((a1), float4(0.13656664, 0.063764885, 0.0015611092, 0.06707094)), dot((a1), float4(0.23103227, -0.1902535, 0.009383415, 0.05323591)), dot((a1), float4(-0.09881847, 0.12580052, 0.0028447553, 0.087465174))) + (target1);
	target1 = float4(dot((b1), float4(0.023715734, 0.12822664, 0.11440009, -0.2594948)), dot((b1), float4(0.15901619, -0.079860024, -0.069189526, -0.008447683)), dot((b1), float4(0.010465818, -0.107430205, 0.1377121, -0.052618783)), dot((b1), float4(-0.05401794, -0.09094713, -0.02780827, 0.0995311))) + (target1);
	target1 = float4(dot((c1), float4(0.014655754, -0.07336922, 0.0761052, 0.008160006)), dot((c1), float4(0.0976315, -0.09931748, -0.14147633, -0.14553718)), dot((c1), float4(-0.10425098, -0.074338034, 0.057346404, -0.14069714)), dot((c1), float4(0.06731683, 0.014602733, -0.10485628, -0.106754564))) + (target1);
	target1 = float4(dot((d1), float4(-0.18000032, -0.11475177, 0.14004572, -0.04573617)), dot((d1), float4(0.2654082, 0.110427424, -0.1257574, 0.0062926346)), dot((d1), float4(0.07008131, -0.09757059, -0.18653339, -0.111400455)), dot((d1), float4(-0.21326934, -0.068473235, -0.0546973, 0.20940857))) + (target1);
	target1 = float4(dot((e1), float4(-0.018083753, 0.19642518, -0.04213514, 0.4724302)), dot((e1), float4(0.2091146, 0.008668434, 0.114459425, -0.12169043)), dot((e1), float4(-0.12149297, 0.30470127, -0.20325947, 0.22899939)), dot((e1), float4(-0.20310159, 0.080623224, 0.024065504, 0.16189654))) + (target1);
	target1 = float4(dot((f1), float4(0.22153069, -0.010648649, -0.0122471545, -0.18476847)), dot((f1), float4(-0.13286535, -0.07542803, -0.12456761, 0.023691572)), dot((f1), float4(0.21529129, 0.12650701, -0.05047403, 0.16347644)), dot((f1), float4(0.059222966, 0.107978106, 0.052241012, -0.10157776))) + (target1);
	target1 = float4(dot((g1), float4(0.053245157, -0.09103809, 0.105658144, -0.08754643)), dot((g1), float4(0.23913434, -0.070054255, -0.2088671, 0.0675039)), dot((g1), float4(-0.06288426, -0.021768395, -0.03485171, -0.10190519)), dot((g1), float4(-0.15678102, 0.012513, -0.07802848, 0.03442446))) + (target1);
	target1 = float4(dot((h1), float4(-0.028817, -0.03416565, 0.16325544, -0.0750008)), dot((h1), float4(0.11284706, 0.09102063, 0.14942992, -0.018136598)), dot((h1), float4(0.13998732, 0.11161235, -0.12313727, -0.23112826)), dot((h1), float4(-0.015143216, 0.08467392, -0.06640328, -0.006661416))) + (target1);
	target1 = float4(dot((i1), float4(0.017297093, -0.25493076, -0.17994808, -0.010386358)), dot((i1), float4(0.07989559, 0.061273754, -0.14367908, -0.102339104)), dot((i1), float4(0.13549612, 0.052633338, 0.098241016, 0.023344131)), dot((i1), float4(0.07035857, 0.0782014, -0.07993234, -0.08682215))) + (target1);
	target1 = float4(dot((a2), float4(0.36794287, -0.023172008, 0.09313475, 0.1006075)), dot((a2), float4(-0.048137277, 0.02877666, -0.27063283, 0.028261969)), dot((a2), float4(-0.3692417, -0.23517531, 0.028388552, -0.10012888)), dot((a2), float4(0.07832, 0.1448923, 0.17988816, -0.10348935))) + (target1);
	target1 = float4(dot((b2), float4(-0.06629671, 0.054654542, -0.26171863, 0.15199377)), dot((b2), float4(0.35957095, 0.05988639, 0.042992886, 0.16362138)), dot((b2), float4(-0.21791938, -0.32374984, 0.29698196, -0.18785295)), dot((b2), float4(-0.12429962, 0.009501225, 0.08521328, -0.049852755))) + (target1);
	target1 = float4(dot((c2), float4(0.15766738, -0.008089345, 0.08845935, 0.2653877)), dot((c2), float4(-0.04841046, 0.04590437, 0.039423246, -0.20700884)), dot((c2), float4(0.14447841, -0.043384884, -0.14808795, 0.07218189)), dot((c2), float4(0.17353393, 0.002877719, -0.03975318, -0.10878484))) + (target1);
	target1 = float4(dot((d2), float4(0.11222389, 0.17030342, 0.41185054, -0.084791176)), dot((d2), float4(0.2779044, 0.05503266, -0.43625602, -0.01684559)), dot((d2), float4(0.0847275, -0.22644295, -0.18901125, 0.19077617)), dot((d2), float4(-0.16267867, -0.23563059, 0.6115694, -0.07168747))) + (target1);
	target1 = float4(dot((e2), float4(0.015268929, -0.021667667, -0.06938558, -0.05013765)), dot((e2), float4(-0.14208716, -0.078210905, -0.023576038, 0.061508566)), dot((e2), float4(0.15536898, 0.023766499, -0.2990819, -0.085189775)), dot((e2), float4(-0.11922906, -0.18069603, 0.11863158, 0.07901883))) + (target1);
	target1 = float4(dot((f2), float4(0.13318339, 0.3436642, 0.11614284, -0.090151444)), dot((f2), float4(0.29247984, -0.099461004, 0.20115575, 0.06976889)), dot((f2), float4(0.14075997, -0.17356718, 0.04850254, 0.12614332)), dot((f2), float4(0.08248716, -0.029998098, -0.109567694, 0.097242))) + (target1);
	target1 = float4(dot((g2), float4(0.102283016, 0.102346785, 0.04298546, 0.00294458)), dot((g2), float4(0.2969136, 0.061365493, -0.10845686, 0.01617549)), dot((g2), float4(-0.059127506, -0.09023823, -0.16071963, 0.30480185)), dot((g2), float4(0.06053867, -0.14396398, 0.05240062, -0.0020818028))) + (target1);
	target1 = float4(dot((h2), float4(0.022530032, -0.20493472, 0.12630959, -0.11481554)), dot((h2), float4(-0.04770017, 0.26375678, -0.33804628, 0.045285236)), dot((h2), float4(0.16849731, -0.08210537, -0.066290505, 0.009036264)), dot((h2), float4(0.2684958, 0.11594341, -0.21235433, -0.009541344))) + (target1);
	target1 = float4(dot((i2), float4(0.22221607, 0.42560205, -0.025208276, 0.14332424)), dot((i2), float4(0.19683546, -0.2515224, 0.09696816, -0.04554422)), dot((i2), float4(0.088301376, 0.10263357, 0.07462843, 0.1857485)), dot((i2), float4(0.07007941, 0.17257528, -0.1663459, 0.19819035))) + (target1);
	target1 = float4(dot((na1), float4(-0.33422568, 0.22068155, 0.21229419, -0.0017977909)), dot((na1), float4(0.22908518, -0.31737608, 0.0637268, -0.24026957)), dot((na1), float4(-0.052035328, 0.11867548, 0.06284452, 0.08011851)), dot((na1), float4(0.0022050992, -0.1062603, 0.075321406, -0.016301792))) + (target1);
	target1 = float4(dot((nb1), float4(0.18647133, -0.19073069, -0.30524725, -0.0010289366)), dot((nb1), float4(-0.042395514, 0.037881456, 0.056054097, -0.03421297)), dot((nb1), float4(-0.21644959, 0.15364948, -0.03914103, 0.34305614)), dot((nb1), float4(0.020428998, 0.13242447, 0.030670341, 0.078916825))) + (target1);
	target1 = float4(dot((nc1), float4(-0.061559163, -0.17371178, 0.10086231, -0.23286462)), dot((nc1), float4(0.33350998, 0.020277103, -0.07366512, 0.2155677)), dot((nc1), float4(-0.040633813, -0.024941592, 0.16570221, 0.15136743)), dot((nc1), float4(-0.1973531, 0.06309346, 0.20248237, 0.05190251))) + (target1);
	target1 = float4(dot((nd1), float4(-0.089644894, 0.16190928, 0.17348176, 0.12337869)), dot((nd1), float4(0.13512145, -0.35417703, 0.074274324, 0.029932164)), dot((nd1), float4(-0.09810823, -0.05601066, 0.029394915, 0.04123706)), dot((nd1), float4(0.1616594, 0.20318456, 0.15095772, -0.049648866))) + (target1);
	target1 = float4(dot((ne1), float4(0.46952993, -0.2967575, -0.38649827, -0.43983704)), dot((ne1), float4(0.14834478, -0.030506441, 0.18501776, -0.15083657)), dot((ne1), float4(-0.11927866, -0.1524667, 0.07677004, -0.118309684)), dot((ne1), float4(0.07611556, -0.16106017, -0.0828538, 0.13656397))) + (target1);
	target1 = float4(dot((nf1), float4(-0.04939808, -0.20486577, -0.034855623, 0.046889585)), dot((nf1), float4(0.53252345, 0.031688303, -0.05244254, 0.1430025)), dot((nf1), float4(0.12711428, -0.18231112, -0.1425771, -0.12742822)), dot((nf1), float4(-0.38512766, -0.019054607, 0.0892418, 0.092776656))) + (target1);
	target1 = float4(dot((ng1), float4(-0.105744444, -0.03536793, -0.13862023, -0.12592442)), dot((ng1), float4(-0.10247078, -0.027341979, 0.037751865, -0.0762698)), dot((ng1), float4(-0.02144931, -0.103435315, 0.40586975, 0.008515978)), dot((ng1), float4(-0.09396661, 0.12214116, 0.023863355, 0.1552095))) + (target1);
	target1 = float4(dot((nh1), float4(0.018858416, -0.182029, -0.05744442, 0.13113242)), dot((nh1), float4(0.053681094, 0.02297272, 0.0065371646, -0.07573973)), dot((nh1), float4(0.16911085, -0.30588147, 0.16328862, -0.047258016)), dot((nh1), float4(-0.29219922, -0.18948974, -0.051437955, 0.0882382))) + (target1);
	target1 = float4(dot((ni1), float4(-0.021155104, 0.053573515, 0.24886242, 0.104298666)), dot((ni1), float4(0.07440132, 0.007910367, -0.004493456, 0.14052817)), dot((ni1), float4(-0.06681412, -0.26769453, 0.023437606, -0.29093856)), dot((ni1), float4(-0.20775446, -0.15753269, 0.13257046, 0.006735399))) + (target1);
	target1 = float4(dot((na2), float4(-0.1299053, -0.012464804, -0.012958428, -0.12679845)), dot((na2), float4(0.21084401, 0.090624444, -0.22729388, -0.15950051)), dot((na2), float4(0.07395335, -0.1041891, 0.06259986, -0.13191415)), dot((na2), float4(0.025556391, 0.03487812, -0.1693054, 0.1125045))) + (target1);
	target1 = float4(dot((nb2), float4(0.1916771, -0.18369348, 0.0587951, -0.07597363)), dot((nb2), float4(-0.02030791, -0.054252382, 0.15208498, -0.21144252)), dot((nb2), float4(-0.2001191, -0.11485618, -0.1752913, -0.049415894)), dot((nb2), float4(0.01943065, -0.16434757, 0.03718008, -0.010295923))) + (target1);
	target1 = float4(dot((nc2), float4(-0.044603452, 0.12697428, -0.104321085, -0.12313407)), dot((nc2), float4(0.019383559, -0.13032277, 0.04012559, 0.118987724)), dot((nc2), float4(-0.24661145, -0.15293793, 0.037243072, 0.038709577)), dot((nc2), float4(-0.12994917, -0.03483303, 0.079595305, 0.09531991))) + (target1);
	target1 = float4(dot((nd2), float4(-0.021859067, -0.07705756, -0.12042984, 0.1087794)), dot((nd2), float4(0.009060085, 0.10045584, -0.11578441, -0.1419117)), dot((nd2), float4(0.19879933, -0.075999945, 0.29679164, -0.22779143)), dot((nd2), float4(0.21082644, 0.15191688, -0.23787339, 0.12054577))) + (target1);
	target1 = float4(dot((ne2), float4(0.16636065, 0.05992027, -0.026526988, 0.0979992)), dot((ne2), float4(0.21066229, 0.014294402, -0.2071816, -0.08312352)), dot((ne2), float4(-0.06262401, -0.13363211, -0.03000262, -0.016549548)), dot((ne2), float4(0.051833395, -0.11139326, -0.08924753, -0.034920745))) + (target1);
	target1 = float4(dot((nf2), float4(0.099836424, 0.12210845, -0.009426102, 0.04862195)), dot((nf2), float4(-0.19452114, -0.15024027, 0.15876383, 0.0707773)), dot((nf2), float4(0.07249264, -0.06490785, -0.19070506, -0.24345201)), dot((nf2), float4(-0.025459828, -0.080187015, 0.12257102, -0.103591055))) + (target1);
	target1 = float4(dot((ng2), float4(-0.039747223, -0.05476214, 0.11907656, -0.040156245)), dot((ng2), float4(0.07834283, 0.07021812, 0.04191671, -0.21329322)), dot((ng2), float4(0.13246708, 0.0134778535, 0.04860092, 0.2024782)), dot((ng2), float4(-0.021774938, 0.003289531, -0.041503876, 0.067827046))) + (target1);
	target1 = float4(dot((nh2), float4(-0.036722995, 0.18742307, -0.067778006, 0.23733437)), dot((nh2), float4(0.12776081, -0.099873625, 0.16363877, 0.16123019)), dot((nh2), float4(0.14014143, -0.13149267, -0.007999648, 0.23561893)), dot((nh2), float4(0.09107308, -0.18590397, 0.13500053, 0.0365712))) + (target1);
	target1 = float4(dot((ni2), float4(0.023911275, 0.21406639, 0.11913366, -0.20745984)), dot((ni2), float4(-0.03754323, -0.15029684, -0.16174106, -0.06180981)), dot((ni2), float4(0.17444386, 0.09355591, -0.10907662, -0.019558005)), dot((ni2), float4(0.08616114, -0.2486941, 0.107935205, -0.24215329))) + (target1);
	float4 target2 = float4( -0.07366732, -0.06278686, 0.11547288, -0.04786791 );
	Out5 = target1;
}

void Anime4K_PS3b(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out6 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 pos = (float2(pix) + 0.5) * rcp;
	float4 a1 = tex2Dlod(SampT3, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b1 = tex2Dlod(SampT3, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c1 = tex2Dlod(SampT3, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d1 = tex2Dlod(SampT3, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e1 = tex2Dlod(SampT3, float4(pos, 0, 0));
	float4 f1 = tex2Dlod(SampT3, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g1 = tex2Dlod(SampT3, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h1 = tex2Dlod(SampT3, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i1 = tex2Dlod(SampT3, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na1 = max(-a1, 0);
	float4 nb1 = max(-b1, 0);
	float4 nc1 = max(-c1, 0);
	float4 nd1 = max(-d1, 0);
	float4 ne1 = max(-e1, 0);
	float4 nf1 = max(-f1, 0);
	float4 ng1 = max(-g1, 0);
	float4 nh1 = max(-h1, 0);
	float4 ni1 = max(-i1, 0);
	a1 = max(a1, 0);
	b1 = max(b1, 0);
	c1 = max(c1, 0);
	d1 = max(d1, 0);
	e1 = max(e1, 0);
	f1 = max(f1, 0);
	g1 = max(g1, 0);
	h1 = max(h1, 0);
	i1 = max(i1, 0);
	float4 a2 = tex2Dlod(SampT4, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b2 = tex2Dlod(SampT4, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c2 = tex2Dlod(SampT4, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d2 = tex2Dlod(SampT4, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e2 = tex2Dlod(SampT4, float4(pos, 0, 0));
	float4 f2 = tex2Dlod(SampT4, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g2 = tex2Dlod(SampT4, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h2 = tex2Dlod(SampT4, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i2 = tex2Dlod(SampT4, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na2 = max(-a2, 0);
	float4 nb2 = max(-b2, 0);
	float4 nc2 = max(-c2, 0);
	float4 nd2 = max(-d2, 0);
	float4 ne2 = max(-e2, 0);
	float4 nf2 = max(-f2, 0);
	float4 ng2 = max(-g2, 0);
	float4 nh2 = max(-h2, 0);
	float4 ni2 = max(-i2, 0);
	a2 = max(a2, 0);
	b2 = max(b2, 0);
	c2 = max(c2, 0);
	d2 = max(d2, 0);
	e2 = max(e2, 0);
	f2 = max(f2, 0);
	g2 = max(g2, 0);
	h2 = max(h2, 0);
	i2 = max(i2, 0);
	float4 target1 = float4( -0.16255508, -0.041602854, 0.09628627, 0.12747966 );
	float4 target2 = float4( -0.07366732, -0.06278686, 0.11547288, -0.04786791 );
	target2 = float4(dot((a1), float4(0.14002717, 0.03416418, -0.115944035, -0.0860279)), dot((a1), float4(0.058876935, 0.0011943586, 0.04220234, 0.062355816)), dot((a1), float4(0.20110254, 0.042772148, -0.34941152, -0.023853427)), dot((a1), float4(0.08939276, -0.00071322336, -0.01974448, 0.02757322))) + (target2);
	target2 = float4(dot((b1), float4(0.07400734, -0.17724502, 0.101782374, -0.1023507)), dot((b1), float4(0.19251242, -0.022523593, -0.014717139, 0.019614108)), dot((b1), float4(0.22637455, -0.15113536, -0.098752305, 0.01754361)), dot((b1), float4(-0.12530822, 0.065425, 0.080687046, 0.017383952))) + (target2);
	target2 = float4(dot((c1), float4(-0.044900224, -0.051043745, 0.26050508, -0.12510507)), dot((c1), float4(-0.04213899, -0.115500204, 0.20679274, -0.051585447)), dot((c1), float4(0.0073328684, -0.07567362, 0.04177571, -0.007354538)), dot((c1), float4(0.16705592, 0.07818187, 0.059024576, 0.041514263))) + (target2);
	target2 = float4(dot((d1), float4(0.19596866, -0.10047298, 0.11121212, 0.082481235)), dot((d1), float4(-0.085393354, 0.033123884, 0.038920198, 0.08472773)), dot((d1), float4(0.03522195, -0.030003218, -0.09097313, -0.007372676)), dot((d1), float4(0.070734546, -0.060309574, 0.020515997, 0.020294813))) + (target2);
	target2 = float4(dot((e1), float4(-0.08415041, 0.26823425, 0.17127061, 0.053938765)), dot((e1), float4(-0.2041298, -0.029255247, -0.14378369, -0.0033184371)), dot((e1), float4(-0.0834695, 0.21203867, 0.18486983, 0.021192972)), dot((e1), float4(-0.18762465, 0.01842292, 0.040807612, -0.28285155))) + (target2);
	target2 = float4(dot((f1), float4(-0.071444504, -0.09696413, 0.055909842, 0.065472044)), dot((f1), float4(-0.16073905, -0.14652419, 0.023814479, -0.04875745)), dot((f1), float4(0.03151272, 0.012872177, 0.12539348, -0.012401859)), dot((f1), float4(0.31961456, 0.036853626, 0.40904784, 0.055437304))) + (target2);
	target2 = float4(dot((g1), float4(-0.020927057, 0.08953939, 0.088546015, 0.049379412)), dot((g1), float4(-0.23479983, 0.00085565075, -0.009464413, -0.059064344)), dot((g1), float4(-0.073076054, 0.061437223, -0.21220255, 0.019205336)), dot((g1), float4(-0.019441728, -0.0912304, -0.13741408, -0.11340151))) + (target2);
	target2 = float4(dot((h1), float4(0.091714375, 0.062438603, 0.15641114, 0.051840104)), dot((h1), float4(-0.17525947, -0.05920895, -0.13261372, 0.07784452)), dot((h1), float4(0.10243093, -0.041936304, -0.021079037, 0.024798041)), dot((h1), float4(0.037679292, -0.030830177, -0.036029477, -0.079719625))) + (target2);
	target2 = float4(dot((i1), float4(0.09153048, -0.041912418, -0.1276734, 0.115786545)), dot((i1), float4(0.09966556, -0.22329834, -0.108105786, 0.043516885)), dot((i1), float4(-0.10249195, 0.06683857, -0.076660454, 0.032041304)), dot((i1), float4(0.062159285, -0.07287391, -0.07083524, 0.058955755))) + (target2);
	target2 = float4(dot((a2), float4(0.13925591, -0.18483852, 0.0165214, 0.21641012)), dot((a2), float4(0.18807505, 0.07704087, 0.03893396, 0.047428373)), dot((a2), float4(0.19418481, -0.25748852, 0.081021786, -0.08350786)), dot((a2), float4(0.13057134, -0.008577424, -0.19419926, -0.14157358))) + (target2);
	target2 = float4(dot((b2), float4(-0.06301399, -0.09310829, 0.09107295, 0.116363674)), dot((b2), float4(-0.10051874, -0.09138247, 0.06165534, 0.20607105)), dot((b2), float4(0.050919298, -0.16847654, -0.14288484, 0.28841344)), dot((b2), float4(-0.011019032, 0.059362046, -0.09833287, -0.09095499))) + (target2);
	target2 = float4(dot((c2), float4(-0.21624683, -0.07461909, -0.24328436, 0.07773235)), dot((c2), float4(-0.01876206, 0.124108806, 0.12330878, 0.08965016)), dot((c2), float4(0.008987255, -0.054439757, -0.09306248, 0.0025699693)), dot((c2), float4(0.17512046, 0.0063252384, -0.046553027, 0.06252218))) + (target2);
	target2 = float4(dot((d2), float4(0.17797774, 0.052788664, -0.52695477, -0.070845306)), dot((d2), float4(-0.0768457, 0.10169022, 0.10339165, 0.011061218)), dot((d2), float4(-0.06500614, -0.11962388, 0.12893896, -0.033032518)), dot((d2), float4(0.010914941, -0.10176263, 0.016989866, 0.13843493))) + (target2);
	target2 = float4(dot((e2), float4(0.4498575, 0.050753895, -0.35924155, 0.23128356)), dot((e2), float4(0.3626344, 0.03323978, 0.13558777, 0.2943383)), dot((e2), float4(-0.18857695, -0.15807427, 0.07132256, 0.011521201)), dot((e2), float4(0.12901132, 0.050633483, -0.20883714, -0.21517687))) + (target2);
	target2 = float4(dot((f2), float4(-0.007034323, 0.1458542, 0.07331739, -0.010828551)), dot((f2), float4(-0.08821435, 0.26724494, -0.061295208, -0.11301564)), dot((f2), float4(-0.1275898, -0.118883595, -0.008509335, -0.078878716)), dot((f2), float4(-0.15626103, -0.0062981425, -0.012484612, -0.07692456))) + (target2);
	target2 = float4(dot((g2), float4(-0.17712432, 0.22146885, -0.15350081, 0.053412)), dot((g2), float4(0.020956295, 0.20994097, 0.118692145, -0.06350743)), dot((g2), float4(0.118008055, -0.11431106, -0.028190786, -0.03998433)), dot((g2), float4(0.09609794, -0.10710715, 0.021440385, 0.061913643))) + (target2);
	target2 = float4(dot((h2), float4(-0.07220576, 0.114823125, -0.055653024, 0.1803409)), dot((h2), float4(0.21927893, -0.115261756, 0.11297751, 0.1982345)), dot((h2), float4(0.029267995, -0.18801664, 0.15545851, -0.07486266)), dot((h2), float4(0.107059665, 0.04473252, -0.012991604, -0.09845943))) + (target2);
	target2 = float4(dot((i2), float4(-0.0855076, -0.24398185, 0.029505143, 0.16977786)), dot((i2), float4(0.014239223, -0.039692834, 0.0986762, -0.08617271)), dot((i2), float4(0.15630183, -0.167163, 0.015726546, 0.13340445)), dot((i2), float4(0.21274531, 0.09103569, 0.015572646, -0.14292516))) + (target2);
	target2 = float4(dot((na1), float4(-0.07120758, 0.017502422, 0.23512627, 0.050294157)), dot((na1), float4(-0.1391182, 0.21387358, -0.18750496, -0.03545248)), dot((na1), float4(-0.12895927, 0.11369438, 0.3741736, 0.1803603)), dot((na1), float4(-0.05497231, -0.09802215, 0.07218814, -0.05216715))) + (target2);
	target2 = float4(dot((nb1), float4(-0.031216163, 0.05476227, 0.121324, 0.19340484)), dot((nb1), float4(0.26304567, 0.048769098, -0.07633719, -0.11655276)), dot((nb1), float4(-0.22097221, 0.11701435, 0.019091062, -0.06859909)), dot((nb1), float4(0.0057130447, -0.08043882, 0.1056272, -0.20875669))) + (target2);
	target2 = float4(dot((nc1), float4(-0.1303287, -0.024545986, 0.2297885, 0.184152)), dot((nc1), float4(0.23683752, -0.09032069, 0.02040227, -0.070972465)), dot((nc1), float4(-0.14536002, 0.03192402, 0.00034511733, -0.010276752)), dot((nc1), float4(-0.12238158, -0.22449107, -0.0878228, -0.1974931))) + (target2);
	target2 = float4(dot((nd1), float4(-0.345411, -0.08967216, 0.20315827, 0.0463197)), dot((nd1), float4(-0.088238314, 0.11257784, 0.08028863, -0.11993164)), dot((nd1), float4(-0.020721637, 0.11590796, -0.053076692, 0.17273119)), dot((nd1), float4(-0.19773935, 0.047473334, 0.04220213, -0.10105775))) + (target2);
	target2 = float4(dot((ne1), float4(0.01774352, -0.23905252, -0.15104173, 0.03382718)), dot((ne1), float4(-0.029116748, 0.122819565, 0.06922476, 0.17504995)), dot((ne1), float4(-0.070671946, -0.13782008, -0.40653947, 0.19865142)), dot((ne1), float4(0.03868912, -0.11386684, -0.041311335, 0.20958701))) + (target2);
	target2 = float4(dot((nf1), float4(0.019477593, -0.009433358, -0.15928364, 0.017931713)), dot((nf1), float4(-0.13480781, 0.07510615, -0.18979515, 0.15517262)), dot((nf1), float4(-0.15261935, -0.07673836, 0.23357031, -0.045679327)), dot((nf1), float4(-0.29111782, -0.092863046, -0.096665405, -0.13043073))) + (target2);
	target2 = float4(dot((ng1), float4(0.009786184, -0.21214269, 0.16580902, -0.3186572)), dot((ng1), float4(0.23618346, 0.008612741, 0.018369747, 0.013351233)), dot((ng1), float4(0.08964326, 0.012998613, 0.31754863, -0.04407326)), dot((ng1), float4(-0.07550377, 0.08797401, 0.094271086, 0.0920314))) + (target2);
	target2 = float4(dot((nh1), float4(-0.025626086, -0.19025484, -0.045282297, -0.24248622)), dot((nh1), float4(0.09697167, 0.25081167, 0.02762338, -0.0027028685)), dot((nh1), float4(-0.013395247, -0.008351234, 0.09182815, -0.026439957)), dot((nh1), float4(-0.080764554, 0.009649054, -0.015618593, 0.06903493))) + (target2);
	target2 = float4(dot((ni1), float4(0.15144084, 0.006812688, 0.07722477, -0.23726766)), dot((ni1), float4(0.09893225, 0.20841157, 0.18913163, -0.06573527)), dot((ni1), float4(0.18078536, -0.052535042, 0.06806257, -0.07974115)), dot((ni1), float4(-0.40492618, -0.03471349, 0.13268931, 0.00016083609))) + (target2);
	target2 = float4(dot((na2), float4(-0.22123417, 0.05219495, -0.02443482, -0.26269525)), dot((na2), float4(0.043395992, -0.10119571, 0.22211014, -0.045644283)), dot((na2), float4(-0.075050056, 0.06624045, 0.11706287, 0.1594094)), dot((na2), float4(0.040263254, 0.006088249, 0.09821594, 0.05119857))) + (target2);
	target2 = float4(dot((nb2), float4(-0.1359838, -0.13730896, -0.11819638, 0.13765272)), dot((nb2), float4(0.085772105, 0.13598563, 0.00615722, 0.026108319)), dot((nb2), float4(-0.14989698, -0.22069088, 0.22080155, -0.16875726)), dot((nb2), float4(0.22662053, -0.049138095, -0.18276499, -0.04851573))) + (target2);
	target2 = float4(dot((nc2), float4(-0.23633143, -0.057579413, 0.06935881, 0.030873962)), dot((nc2), float4(-0.04675013, -0.007248268, -0.07843104, 0.05374762)), dot((nc2), float4(0.13207665, -0.11771674, -0.051989514, 0.15865721)), dot((nc2), float4(0.17955893, 0.053317282, -0.101527795, -0.11873757))) + (target2);
	target2 = float4(dot((nd2), float4(-0.17574823, 0.045519844, 0.1285456, 0.06786445)), dot((nd2), float4(0.116152145, -0.003343947, -0.06100108, -0.110831186)), dot((nd2), float4(0.038584445, -0.18241419, 0.072168864, 0.0017635048)), dot((nd2), float4(0.06896235, -0.0559283, 0.2383614, -0.11216164))) + (target2);
	target2 = float4(dot((ne2), float4(-0.22214325, -0.09062008, 0.27807632, -0.0792693)), dot((ne2), float4(-0.16752025, 0.04298391, -0.0072328355, -0.012500297)), dot((ne2), float4(0.39590892, -0.2098661, -0.123739436, -0.0028807693)), dot((ne2), float4(0.0366774, -0.007913526, 0.017585058, -0.0010119011))) + (target2);
	target2 = float4(dot((nf2), float4(0.014059116, -0.23937507, 0.04344956, -0.19981036)), dot((nf2), float4(0.19940482, -0.0070899655, 0.21863829, 0.09243793)), dot((nf2), float4(0.16831028, 0.05102661, 0.014209773, 0.24139273)), dot((nf2), float4(0.16160843, 0.14583974, -0.063842624, 0.11667779))) + (target2);
	target2 = float4(dot((ng2), float4(0.16715737, -0.050105397, -0.03423738, 0.16408625)), dot((ng2), float4(-0.09880053, -0.01993378, -0.13328381, 0.10486815)), dot((ng2), float4(0.00053459726, -0.15830508, -0.1851269, -0.011303046)), dot((ng2), float4(-0.08722921, -0.028736366, 0.012596559, -0.025475042))) + (target2);
	target2 = float4(dot((nh2), float4(0.118060954, -8.479728e-05, -0.16743746, -0.032164577)), dot((nh2), float4(-0.24267668, 0.11292645, -0.17963362, -0.21628135)), dot((nh2), float4(-0.0098548755, -0.05507332, -0.14095132, -0.12668937)), dot((nh2), float4(-0.04774737, -0.20990159, 0.19843975, -0.008645119))) + (target2);
	target2 = float4(dot((ni2), float4(0.11424831, 0.24253003, -0.15157521, -0.02293248)), dot((ni2), float4(-0.19821498, 0.24522384, -0.08158828, -0.052961793)), dot((ni2), float4(0.016948126, -0.13992928, 0.07676344, 0.08597288)), dot((ni2), float4(0.0033053497, 0.08576702, -0.08844756, -0.07834255))) + (target2);
	Out6 = target2;
}

void Anime4K_PS4a(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out7 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 pos = (float2(pix) + 0.5) * rcp;
	float4 a1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d1 = tex2Dlod(SampT1, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e1 = tex2Dlod(SampT1, float4(pos, 0, 0));
	float4 f1 = tex2Dlod(SampT1, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na1 = max(-a1, 0);
	float4 nb1 = max(-b1, 0);
	float4 nc1 = max(-c1, 0);
	float4 nd1 = max(-d1, 0);
	float4 ne1 = max(-e1, 0);
	float4 nf1 = max(-f1, 0);
	float4 ng1 = max(-g1, 0);
	float4 nh1 = max(-h1, 0);
	float4 ni1 = max(-i1, 0);
	a1 = max(a1, 0);
	b1 = max(b1, 0);
	c1 = max(c1, 0);
	d1 = max(d1, 0);
	e1 = max(e1, 0);
	f1 = max(f1, 0);
	g1 = max(g1, 0);
	h1 = max(h1, 0);
	i1 = max(i1, 0);
	float4 a2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d2 = tex2Dlod(SampT2, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e2 = tex2Dlod(SampT2, float4(pos, 0, 0));
	float4 f2 = tex2Dlod(SampT2, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na2 = max(-a2, 0);
	float4 nb2 = max(-b2, 0);
	float4 nc2 = max(-c2, 0);
	float4 nd2 = max(-d2, 0);
	float4 ne2 = max(-e2, 0);
	float4 nf2 = max(-f2, 0);
	float4 ng2 = max(-g2, 0);
	float4 nh2 = max(-h2, 0);
	float4 ni2 = max(-i2, 0);
	a2 = max(a2, 0);
	b2 = max(b2, 0);
	c2 = max(c2, 0);
	d2 = max(d2, 0);
	e2 = max(e2, 0);
	f2 = max(f2, 0);
	g2 = max(g2, 0);
	h2 = max(h2, 0);
	i2 = max(i2, 0);
	float4 target1 = float4( 0.03128986, -0.070663765, -0.056307543, -0.043389197 );
	target1 = float4(dot((a1), float4(0.012843345, 0.06774971, -0.093057916, 0.11699043)), dot((a1), float4(0.047590222, -0.028615275, 0.08288735, 0.062987246)), dot((a1), float4(0.0052741203, 0.030839639, 0.02991863, 0.038180597)), dot((a1), float4(0.017328946, 0.053735327, -0.040167376, 0.11130321))) + (target1);
	target1 = float4(dot((b1), float4(0.047898952, -0.24849094, -0.111574546, 0.04825172)), dot((b1), float4(0.013089616, -0.13717765, -0.017941473, -0.07243479)), dot((b1), float4(0.13206771, -0.14899106, 0.017136412, -0.30205736)), dot((b1), float4(0.053474475, 0.032647215, -0.04121033, -0.009043054))) + (target1);
	target1 = float4(dot((c1), float4(-0.006104078, -0.12583707, 0.038220566, 0.10613474)), dot((c1), float4(-0.056147296, -0.06810525, 0.12901759, -0.011039028)), dot((c1), float4(-0.05430816, -0.18965304, 0.14772348, -0.017407915)), dot((c1), float4(-0.012150009, -0.03767409, -0.011318772, -0.035597485))) + (target1);
	target1 = float4(dot((d1), float4(0.070510425, -0.08330366, -0.112844236, -0.039772045)), dot((d1), float4(0.07079898, 0.14733653, 0.039776023, 0.055393253)), dot((d1), float4(0.063229784, 0.1879776, 0.1109856, 0.13704132)), dot((d1), float4(0.12203576, 0.038365003, -0.013311713, -0.017909162))) + (target1);
	target1 = float4(dot((e1), float4(0.01609076, 0.22690177, -0.095299855, -0.031449903)), dot((e1), float4(0.29408732, -0.16917813, -0.07046006, -0.020992422)), dot((e1), float4(-0.27179766, -0.3125674, -0.03500062, 0.11367832)), dot((e1), float4(0.06092111, -0.059012905, 0.14539354, -0.16279401))) + (target1);
	target1 = float4(dot((f1), float4(-0.014307108, 0.1848716, -0.09059771, -0.22886358)), dot((f1), float4(0.066424, 0.0827183, -0.0033756928, 0.14303732)), dot((f1), float4(-0.10264224, 0.055873994, 0.015373264, 0.060101535)), dot((f1), float4(0.03198627, -0.08671376, 0.1482131, -0.056595195))) + (target1);
	target1 = float4(dot((g1), float4(-0.085188106, -0.008070544, -0.11921908, 0.07129521)), dot((g1), float4(0.07173675, 0.17174324, -0.026167218, 0.08404156)), dot((g1), float4(0.112149395, 0.09781431, 0.0726004, -0.06052682)), dot((g1), float4(0.12051379, 0.15725529, 0.1150364, -0.024796983))) + (target1);
	target1 = float4(dot((h1), float4(-0.118749954, -0.20407347, -0.1381503, 0.09632992)), dot((h1), float4(0.21372789, -0.31983793, -0.2288562, -0.0007208436)), dot((h1), float4(0.1825785, 0.06569954, 0.010778781, 0.042766806)), dot((h1), float4(0.12766796, 0.061804183, 0.046662748, -0.008586152))) + (target1);
	target1 = float4(dot((i1), float4(-0.08471548, -0.1537214, -0.19381963, 0.10709368)), dot((i1), float4(0.11370638, 0.018495824, -0.029650096, 0.091088474)), dot((i1), float4(0.044628102, -0.10132307, -0.12020838, -0.08593706)), dot((i1), float4(0.21962023, 0.055931155, 0.14787269, 0.02723246))) + (target1);
	target1 = float4(dot((a2), float4(0.023070067, 0.078707196, -0.0010075673, -0.08910195)), dot((a2), float4(0.047927327, -0.02090998, -0.02985451, 0.08069201)), dot((a2), float4(-0.0039206124, 0.061532218, -0.013571645, 0.021186491)), dot((a2), float4(0.044357426, -0.01990171, 0.072454736, -0.015898732))) + (target1);
	target1 = float4(dot((b2), float4(0.19465011, 0.07081408, 0.02866604, -0.14039196)), dot((b2), float4(-0.099643335, -0.03980578, 0.047467582, 0.14613628)), dot((b2), float4(-0.13729279, -0.055030484, 0.0021829177, -0.08654854)), dot((b2), float4(-0.01785864, -0.007838133, -0.0085278815, 0.091417976))) + (target1);
	target1 = float4(dot((c2), float4(0.2008973, 0.029072378, -0.032486536, -0.08590457)), dot((c2), float4(-0.055368304, 0.057559345, -0.024021279, -0.037932087)), dot((c2), float4(-0.11570937, -0.12295086, -0.03250597, -0.21787491)), dot((c2), float4(-0.020534834, -0.093348056, 0.03629745, 0.06611054))) + (target1);
	target1 = float4(dot((d2), float4(0.0013978226, 0.06383916, -0.022544125, 0.16181955)), dot((d2), float4(0.12190444, -0.16512986, 0.022348702, -0.087810166)), dot((d2), float4(-0.1388371, 0.020202242, -0.04619122, -0.017245274)), dot((d2), float4(0.053365257, -0.05118216, -0.007816115, 0.2592078))) + (target1);
	target1 = float4(dot((e2), float4(-0.29257166, 0.052169085, -0.07392426, -0.23507537)), dot((e2), float4(0.18668509, 0.08033462, 0.08598093, 0.00095621345)), dot((e2), float4(0.39435357, -0.06759564, -0.099814445, 0.09456823)), dot((e2), float4(-0.015695287, 0.15172167, 0.16442427, 0.35083038))) + (target1);
	target1 = float4(dot((f2), float4(0.09508197, -0.012995353, -0.0010891877, -0.25718254)), dot((f2), float4(-0.10668374, 0.10549121, 0.0013024746, -0.080950156)), dot((f2), float4(0.07861556, 0.20355113, 0.040683478, -0.20833632)), dot((f2), float4(-0.18495509, 0.02486487, 0.09813279, -0.011176342))) + (target1);
	target1 = float4(dot((g2), float4(0.04636551, 0.018154364, 0.056760095, 0.037774805)), dot((g2), float4(0.01815646, 0.08175996, 0.056198932, -0.098509185)), dot((g2), float4(-0.061344985, 0.02177905, -0.01944339, -0.050058816)), dot((g2), float4(0.16105172, 0.05214974, 0.10342066, 0.22327778))) + (target1);
	target1 = float4(dot((h2), float4(0.3342538, -0.0605624, 0.23033214, 0.09768287)), dot((h2), float4(0.24596402, -0.31846803, 0.100796476, -0.08599002)), dot((h2), float4(-0.05070882, -0.030116247, -0.11549748, -0.18570031)), dot((h2), float4(-0.1629279, 0.14499578, 0.13272488, -0.095745035))) + (target1);
	target1 = float4(dot((i2), float4(0.017806288, 0.036575943, 0.08177283, 0.089009784)), dot((i2), float4(0.03143078, -0.04645106, 0.14059572, -0.054094527)), dot((i2), float4(0.1363342, -0.13187204, -0.026990665, -0.10889895)), dot((i2), float4(-0.018307902, -0.019356936, -0.025628868, -0.08352851))) + (target1);
	target1 = float4(dot((na1), float4(-0.10441912, 0.14455585, 0.051149122, -0.030743994)), dot((na1), float4(0.06942166, -0.10067584, -0.051351603, 0.06534117)), dot((na1), float4(0.021075722, -0.006786432, -0.012551037, -0.05894921)), dot((na1), float4(0.022823252, -0.15945506, 0.017784216, -0.007193482))) + (target1);
	target1 = float4(dot((nb1), float4(-0.105177015, 0.09426312, -0.04744092, -0.0033455554)), dot((nb1), float4(0.12079406, 0.0872351, -0.036118995, 0.0052299164)), dot((nb1), float4(-0.021824203, 0.042457238, -0.088347785, 0.14114419)), dot((nb1), float4(0.0051873215, -0.027718134, 0.025714433, -0.23041077))) + (target1);
	target1 = float4(dot((nc1), float4(-0.10924918, 0.01170718, 0.0091770645, 0.27796802)), dot((nc1), float4(0.07170065, 0.09113452, -0.071032606, -0.08136213)), dot((nc1), float4(0.15847342, 0.155801, -0.06911904, 0.20615137)), dot((nc1), float4(0.045235954, 0.012455027, -0.0078831315, -0.22055252))) + (target1);
	target1 = float4(dot((nd1), float4(0.02993543, -0.26578894, -0.14845847, 0.009672752)), dot((nd1), float4(-0.011065637, 0.16489314, 0.11076599, -0.013014179)), dot((nd1), float4(0.015992155, 0.0020848098, -0.015617476, 0.10577515)), dot((nd1), float4(-0.106134124, 0.12432517, 0.12498255, 0.02908296))) + (target1);
	target1 = float4(dot((ne1), float4(-0.0728776, -0.14621304, -0.1769697, 0.10336065)), dot((ne1), float4(-0.14159116, -0.0007887494, -0.1076886, -0.15257628)), dot((ne1), float4(0.105368264, 0.14413477, 0.08036942, 0.05553209)), dot((ne1), float4(-0.016262107, 0.11337385, 0.10428512, 0.12439473))) + (target1);
	target1 = float4(dot((nf1), float4(-0.067323305, 0.02427729, -0.014213087, -0.1949913)), dot((nf1), float4(0.23115864, 0.01246805, -0.022559473, 0.27712336)), dot((nf1), float4(0.0817162, 0.021550559, 0.058270242, -0.020843407)), dot((nf1), float4(0.13127932, 0.066352196, -0.069260366, 0.16199547))) + (target1);
	target1 = float4(dot((ng1), float4(-0.06066066, 0.032292802, 0.0028520338, -0.10283239)), dot((ng1), float4(0.009365795, 0.10364246, 0.10786728, -0.13716424)), dot((ng1), float4(-0.005817299, -0.105340734, 0.041312158, 0.2013461)), dot((ng1), float4(0.016661849, -0.040422246, 0.0634878, -0.14106691))) + (target1);
	target1 = float4(dot((nh1), float4(-0.14796652, -0.044074174, 0.0027458945, -0.33933377)), dot((nh1), float4(0.042259417, 0.24739462, 0.043400105, 0.046819236)), dot((nh1), float4(-0.08663438, 0.04777009, -0.11496284, -0.12803015)), dot((nh1), float4(0.09733461, -0.026686348, 0.08113486, 0.006137677))) + (target1);
	target1 = float4(dot((ni1), float4(-0.07903079, 0.14344518, 0.102321856, -0.1145046)), dot((ni1), float4(-0.009489394, 0.08629371, 0.07221763, -0.088674895)), dot((ni1), float4(0.018812884, 0.123602144, 0.14465447, -0.08679749)), dot((ni1), float4(-0.031424083, 0.045581687, -0.23171869, -0.20322132))) + (target1);
	target1 = float4(dot((na2), float4(-0.09741677, 0.03060611, 0.018646225, -0.013920286)), dot((na2), float4(0.0010184142, 0.11817057, -0.1362759, 0.0041473205)), dot((na2), float4(-0.06932825, 0.04148144, 0.045627713, 0.023480741)), dot((na2), float4(0.044964395, 0.000755089, -0.01720389, -0.00036270308))) + (target1);
	target1 = float4(dot((nb2), float4(-0.047821313, -0.003727664, -0.14427665, 0.09688153)), dot((nb2), float4(0.15457056, -0.03735384, 0.21584798, 0.0071055717)), dot((nb2), float4(0.081069574, -0.00673114, 0.17612408, 0.0704578)), dot((nb2), float4(-0.061125267, -0.0585745, 0.03723236, -0.008490558))) + (target1);
	target1 = float4(dot((nc2), float4(0.005648931, 0.14356652, -0.17543222, 0.046658885)), dot((nc2), float4(-0.021415008, -0.09023091, -0.31645912, -0.13449514)), dot((nc2), float4(0.07515239, -0.092833556, -0.14794292, -0.032724228)), dot((nc2), float4(0.024656001, -0.11933706, -0.10830711, -0.07927336))) + (target1);
	target1 = float4(dot((nd2), float4(-0.012330256, 0.105316125, -0.06755245, -0.10781668)), dot((nd2), float4(0.030906612, 0.1066287, 0.2835302, -0.021025939)), dot((nd2), float4(0.009849825, 0.007410255, 0.06922882, -0.057754997)), dot((nd2), float4(0.16186711, 0.08471377, 0.18501134, -0.19532007))) + (target1);
	target1 = float4(dot((ne2), float4(0.09254016, 0.10726608, 0.07552837, -0.1769102)), dot((ne2), float4(0.21572222, -0.13617107, -0.01980061, 0.35534126)), dot((ne2), float4(-0.250398, 0.06726572, 0.10523871, -0.22155605)), dot((ne2), float4(-0.017990865, -0.17355372, -0.062427603, -0.13921477))) + (target1);
	target1 = float4(dot((nf2), float4(0.0054315915, 0.0020591016, 0.042036943, -0.033534657)), dot((nf2), float4(0.028563919, -0.07287573, -0.19993319, -0.049439076)), dot((nf2), float4(-0.030617325, -0.15371658, -0.1311562, 0.07299748)), dot((nf2), float4(0.12851912, -0.3468236, -0.11087494, 0.049393892))) + (target1);
	target1 = float4(dot((ng2), float4(0.04817828, 0.07101367, 0.14994971, -0.044900555)), dot((ng2), float4(0.009956909, -0.03388178, -0.006995002, -0.05698395)), dot((ng2), float4(0.08608736, 0.08030968, 0.13461865, 0.07130313)), dot((ng2), float4(-0.04149299, -0.032450564, -0.061656967, -0.17835349))) + (target1);
	target1 = float4(dot((nh2), float4(0.09259944, 0.10526596, 0.11869906, 0.017331708)), dot((nh2), float4(-0.1760367, 0.25768888, -0.30243787, 0.04682896)), dot((nh2), float4(-0.05008204, 0.11187724, 0.1930932, 0.02930385)), dot((nh2), float4(0.12799591, -0.06537007, -0.13290296, 0.15250616))) + (target1);
	target1 = float4(dot((ni2), float4(-0.01343636, 0.088516094, -0.036102388, -0.019361602)), dot((ni2), float4(-0.015147329, -0.0716172, -0.16996604, -0.07008898)), dot((ni2), float4(-0.12101166, 0.012281597, 0.0068835146, -0.111906745)), dot((ni2), float4(0.04787181, -0.01175244, 0.16938321, -0.008676077))) + (target1);
	float4 target2 = float4( -0.014193535, -0.035853464, -0.0019574068, 0.035060503 );
	Out7 = target1;
}

void Anime4K_PS4b(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out8 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 pos = (float2(pix) + 0.5) * rcp;
	float4 a1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c1 = tex2Dlod(SampT1, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d1 = tex2Dlod(SampT1, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e1 = tex2Dlod(SampT1, float4(pos, 0, 0));
	float4 f1 = tex2Dlod(SampT1, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i1 = tex2Dlod(SampT1, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na1 = max(-a1, 0);
	float4 nb1 = max(-b1, 0);
	float4 nc1 = max(-c1, 0);
	float4 nd1 = max(-d1, 0);
	float4 ne1 = max(-e1, 0);
	float4 nf1 = max(-f1, 0);
	float4 ng1 = max(-g1, 0);
	float4 nh1 = max(-h1, 0);
	float4 ni1 = max(-i1, 0);
	a1 = max(a1, 0);
	b1 = max(b1, 0);
	c1 = max(c1, 0);
	d1 = max(d1, 0);
	e1 = max(e1, 0);
	f1 = max(f1, 0);
	g1 = max(g1, 0);
	h1 = max(h1, 0);
	i1 = max(i1, 0);
	float4 a2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c2 = tex2Dlod(SampT2, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d2 = tex2Dlod(SampT2, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e2 = tex2Dlod(SampT2, float4(pos, 0, 0));
	float4 f2 = tex2Dlod(SampT2, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i2 = tex2Dlod(SampT2, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 na2 = max(-a2, 0);
	float4 nb2 = max(-b2, 0);
	float4 nc2 = max(-c2, 0);
	float4 nd2 = max(-d2, 0);
	float4 ne2 = max(-e2, 0);
	float4 nf2 = max(-f2, 0);
	float4 ng2 = max(-g2, 0);
	float4 nh2 = max(-h2, 0);
	float4 ni2 = max(-i2, 0);
	a2 = max(a2, 0);
	b2 = max(b2, 0);
	c2 = max(c2, 0);
	d2 = max(d2, 0);
	e2 = max(e2, 0);
	f2 = max(f2, 0);
	g2 = max(g2, 0);
	h2 = max(h2, 0);
	i2 = max(i2, 0);
	float4 target1 = float4( 0.03128986, -0.070663765, -0.056307543, -0.043389197 );
	float4 target2 = float4( -0.014193535, -0.035853464, -0.0019574068, 0.035060503 );
	target2 = float4(dot((a1), float4(-0.010251427, 0.017431414, 0.0024869177, 0.016637174)), dot((a1), float4(-0.045750465, 0.080067836, -0.034495536, 0.040788822)), dot((a1), float4(0.016315231, 0.025827147, 0.09772538, -0.022752339)), dot((a1), float4(-0.008768869, 0.10838066, 0.07213915, 0.10970543))) + (target2);
	target2 = float4(dot((b1), float4(0.11526194, 0.12261753, -0.009849901, 0.045187697)), dot((b1), float4(0.09676918, -0.24500768, 0.023189532, 0.06505389)), dot((b1), float4(-0.04237834, 0.10468346, 0.0011982447, 0.096869685)), dot((b1), float4(-0.2271947, 0.13780572, 0.04185303, -0.1784324))) + (target2);
	target2 = float4(dot((c1), float4(0.04672689, 0.07533596, 0.012960037, 0.0455828)), dot((c1), float4(0.13536161, -0.032177944, -0.04256549, 0.15624708)), dot((c1), float4(-0.1818021, -0.024819814, 0.03154665, 0.0880299)), dot((c1), float4(-0.20668268, 0.036118865, 0.10697645, -0.044446476))) + (target2);
	target2 = float4(dot((d1), float4(-0.03187084, -0.02988392, 0.052836955, -0.045959223)), dot((d1), float4(-0.04798656, -0.13252808, -0.051288467, -0.0385304)), dot((d1), float4(0.05435525, -0.13699181, -0.048392758, -0.113381095)), dot((d1), float4(-0.060023244, -0.013882888, -0.02818318, 0.048340388))) + (target2);
	target2 = float4(dot((e1), float4(0.06799445, 0.0029125893, -0.12278812, 0.008572816)), dot((e1), float4(-0.32721373, -0.029136823, -0.0646935, 0.15084247)), dot((e1), float4(0.09433875, 0.01100064, 0.009398038, -0.22798048)), dot((e1), float4(-0.24025385, -0.12017942, -0.021518359, -0.027803216))) + (target2);
	target2 = float4(dot((f1), float4(0.14571115, -0.0030899157, 0.083688706, -0.030820336)), dot((f1), float4(0.24804439, -0.11837261, 0.13209106, 0.15591313)), dot((f1), float4(0.13177192, 0.14447895, 0.051847935, 0.00807933)), dot((f1), float4(-0.1820655, 0.11825037, -0.27009267, 0.08577916))) + (target2);
	target2 = float4(dot((g1), float4(0.07043623, 0.12019198, 0.09853516, 0.023477113)), dot((g1), float4(-0.006127145, 0.02408659, -0.03085117, -0.050639734)), dot((g1), float4(-0.16473344, 0.038805984, -0.13666795, 0.05486259)), dot((g1), float4(-0.091646075, 0.043282606, 0.057578508, 0.10117338))) + (target2);
	target2 = float4(dot((h1), float4(0.07739963, 0.07235146, -0.09421921, -0.041750733)), dot((h1), float4(0.019718317, -0.08198499, -0.024668563, 0.07785575)), dot((h1), float4(-0.17859067, -0.13072458, 0.058651946, 0.0375434)), dot((h1), float4(-0.107660785, 0.0808431, 0.058679227, -0.11090677))) + (target2);
	target2 = float4(dot((i1), float4(0.13032761, 0.03946319, -0.034065075, 0.018556409)), dot((i1), float4(0.2291367, 0.0063910848, -0.058277655, -0.07521306)), dot((i1), float4(-0.1677081, 0.09128152, 0.052419346, 0.12746032)), dot((i1), float4(-0.22246332, 0.0013804171, -0.030012188, 0.0899423))) + (target2);
	target2 = float4(dot((a2), float4(-0.14820024, -0.028731624, -0.007544352, -0.033130456)), dot((a2), float4(0.03316697, -0.03655249, -0.058063164, -0.17607957)), dot((a2), float4(0.074021704, 0.041885335, 0.030487465, 0.0020156964)), dot((a2), float4(0.0349015, 0.025598902, -0.073317364, 0.15351814))) + (target2);
	target2 = float4(dot((b2), float4(-0.33111712, -0.10840586, 0.0028098845, 0.0040087802)), dot((b2), float4(0.11070417, -0.114877716, 0.07325011, 0.15237121)), dot((b2), float4(-0.11759775, 0.026571346, -0.008114658, 0.10423624)), dot((b2), float4(0.12881225, 0.01617625, 0.11581408, 0.010486565))) + (target2);
	target2 = float4(dot((c2), float4(-0.14014785, -0.05651376, -0.0045316, 0.15113525)), dot((c2), float4(0.03670812, -0.009220771, -0.0781469, 0.14979461)), dot((c2), float4(0.041663505, 0.18786587, 0.09609792, -0.003579166)), dot((c2), float4(-0.25026393, 0.11221872, -0.077175744, -0.097722545))) + (target2);
	target2 = float4(dot((d2), float4(0.005191016, -0.116905205, 0.08867301, -0.078146204)), dot((d2), float4(-0.05746076, 0.035447106, -0.027591052, 0.21156693)), dot((d2), float4(0.14736177, -0.1389216, 0.020395119, -0.24100207)), dot((d2), float4(-0.37837118, -0.06583864, -0.067704394, -0.34081197))) + (target2);
	target2 = float4(dot((e2), float4(0.3395633, -0.1203106, 0.0106182005, 0.45373476)), dot((e2), float4(-0.16366479, 0.1201394, -0.007498128, -0.019419974)), dot((e2), float4(-0.16501908, 0.059141878, -0.13781549, -0.029461615)), dot((e2), float4(0.19205959, 0.024588805, -0.031079333, -0.109356895))) + (target2);
	target2 = float4(dot((f2), float4(-0.20302778, -0.14157735, 0.0066573587, -0.036978997)), dot((f2), float4(0.023634301, 0.115462445, -0.14406916, 0.07784742)), dot((f2), float4(0.0037064455, -0.10275177, -0.029837208, -0.009329581)), dot((f2), float4(0.23106048, -0.05708588, 0.056612004, 0.11628078))) + (target2);
	target2 = float4(dot((g2), float4(-0.050052032, 0.07106667, -0.005880379, -0.18414119)), dot((g2), float4(0.061341796, -0.062498234, -0.031624768, -0.070826136)), dot((g2), float4(-0.108812004, 0.08073948, 0.0334547, 0.027453694)), dot((g2), float4(-0.27657855, 0.18898413, 0.10361753, 0.022999335))) + (target2);
	target2 = float4(dot((h2), float4(0.014818375, -0.08041041, 0.05470518, 0.05177294)), dot((h2), float4(0.17337285, 0.022390872, 0.014654071, -0.13493995)), dot((h2), float4(0.10936815, 0.0053962595, 0.06899392, -0.055468578)), dot((h2), float4(-0.030657725, 0.090021096, -0.03431451, -0.19131596))) + (target2);
	target2 = float4(dot((i2), float4(0.08200318, -0.041665014, -0.016218789, 0.013318846)), dot((i2), float4(-0.10802187, -0.05528946, -0.12353001, -0.16708943)), dot((i2), float4(-0.075451784, 0.1799087, -0.034801062, 0.17779571)), dot((i2), float4(0.006642357, -0.07113583, 0.06995437, 0.20705931))) + (target2);
	target2 = float4(dot((na1), float4(0.10754426, -0.09719291, -0.031175358, 0.0302328)), dot((na1), float4(-0.03437161, 0.042339396, -0.06077806, -0.011108347)), dot((na1), float4(-0.089123115, -0.02457928, -0.025603233, -0.08815118)), dot((na1), float4(-0.12592112, -0.10472151, 0.0030798917, -0.11247357))) + (target2);
	target2 = float4(dot((nb1), float4(-0.03634052, -0.01030603, 0.11631174, -0.034056764)), dot((nb1), float4(-0.0752815, 0.05347118, 0.017359301, -0.06371101)), dot((nb1), float4(-0.032257803, -0.013455479, 0.0053947037, 0.10579902)), dot((nb1), float4(-0.020932812, -0.1528448, -0.10187295, 0.06297638))) + (target2);
	target2 = float4(dot((nc1), float4(0.0026892002, 0.017382741, 0.016445315, -0.23449722)), dot((nc1), float4(-0.09832557, 0.0868499, -0.096997134, 0.004868548)), dot((nc1), float4(0.07002896, 0.024310237, -0.05655256, -0.046150357)), dot((nc1), float4(0.17336288, 0.1024202, -0.03888035, 0.16268611))) + (target2);
	target2 = float4(dot((nd1), float4(-0.08197917, 0.17058893, 0.20562899, -0.026852611)), dot((nd1), float4(0.06499742, 0.003096477, 0.06886438, 0.11638924)), dot((nd1), float4(0.044401966, 0.073047325, -0.10150125, -0.2897435)), dot((nd1), float4(0.119590975, -0.2325016, -0.09421983, 0.10056706))) + (target2);
	target2 = float4(dot((ne1), float4(0.05599001, 0.07353149, 0.19414866, -0.1875029)), dot((ne1), float4(0.20881969, 0.10849278, 0.084341206, -0.13233592)), dot((ne1), float4(0.057560008, -0.04358825, -0.054937962, 0.247698)), dot((ne1), float4(0.03211348, -0.07277266, -0.19548011, 0.054934226))) + (target2);
	target2 = float4(dot((nf1), float4(0.006909254, -0.011208758, -0.11034183, 0.029486256)), dot((nf1), float4(-0.043635696, 0.10583326, -0.2710617, -0.17993683)), dot((nf1), float4(-0.0420242, -0.039475866, -0.15182555, 0.10480137)), dot((nf1), float4(0.0029297285, -0.091568366, 0.27160573, -0.031949393))) + (target2);
	target2 = float4(dot((ng1), float4(0.012359864, 0.0008418082, 0.04127642, -0.10207868)), dot((ng1), float4(-0.024621721, -0.034133818, 0.021086683, -0.02459281)), dot((ng1), float4(-0.066488825, 0.1275645, -0.055507325, -0.16278388)), dot((ng1), float4(-0.041012418, -0.22584224, 0.017740795, 0.2084072))) + (target2);
	target2 = float4(dot((nh1), float4(0.07907339, -0.014701197, 0.13561183, 0.11731138)), dot((nh1), float4(-0.08811312, -0.08600121, 0.17435691, -0.076414265)), dot((nh1), float4(-0.043821383, -0.07344954, -0.25248256, 0.011668736)), dot((nh1), float4(-0.12781687, -0.06233793, -0.18915577, -0.24489906))) + (target2);
	target2 = float4(dot((ni1), float4(0.015452916, 0.087654404, 0.0119902035, 0.16349368)), dot((ni1), float4(-0.1093781, 0.083113015, -0.12981133, 0.0475539)), dot((ni1), float4(-0.031768844, -0.11759004, -0.043321397, -0.12394514)), dot((ni1), float4(-0.049816687, -0.02852037, 0.30873615, 0.012860273))) + (target2);
	target2 = float4(dot((na2), float4(0.024975974, -0.14491238, -0.088403955, 0.03808985)), dot((na2), float4(0.14167881, -0.024630755, 0.069909796, 0.055002328)), dot((na2), float4(-0.03849521, 0.1262065, -0.1582284, 0.046191234)), dot((na2), float4(0.092395015, 0.22724074, -0.06366643, -0.15073699))) + (target2);
	target2 = float4(dot((nb2), float4(0.040616892, 0.012306014, 0.033986375, 0.008318977)), dot((nb2), float4(-0.05149903, -0.0072504813, 0.09466625, 0.2319992)), dot((nb2), float4(0.07913543, 0.09324519, -0.11271816, -0.23813216)), dot((nb2), float4(-0.12622666, 0.013837971, 0.06514161, -0.064383216))) + (target2);
	target2 = float4(dot((nc2), float4(0.0058016274, -0.14704724, 0.07488793, -0.078130014)), dot((nc2), float4(0.07342614, -0.09635743, 0.049912058, -0.17273565)), dot((nc2), float4(-0.02532061, 0.011660911, -0.23186599, 0.009148666)), dot((nc2), float4(0.046294674, -0.028665043, -0.12174707, 0.042669322))) + (target2);
	target2 = float4(dot((nd2), float4(0.02457923, 0.0027447701, 0.055913534, -0.0037265806)), dot((nd2), float4(0.06036786, 0.12410346, -0.030516708, -0.06458783)), dot((nd2), float4(-0.08706319, 0.07509643, 0.090205066, 0.08390646)), dot((nd2), float4(0.011597113, 0.23769653, 0.005610863, 0.03704848))) + (target2);
	target2 = float4(dot((ne2), float4(-0.24644387, -0.34143484, 0.22231472, -0.07893139)), dot((ne2), float4(0.09733959, -0.10905996, -0.074195, -0.0031443893)), dot((ne2), float4(0.15941189, 0.123846896, 0.17869541, -0.2252749)), dot((ne2), float4(-0.039000493, -0.025850125, 0.007901206, 0.020515904))) + (target2);
	target2 = float4(dot((nf2), float4(0.046822242, 0.020917192, 0.053817958, 0.090974085)), dot((nf2), float4(0.19209228, 0.064485386, 0.2291973, 0.24965459)), dot((nf2), float4(0.10584968, 0.022432446, 0.15079306, -0.11586238)), dot((nf2), float4(-0.20782734, 0.0021164739, -0.18283905, -0.1068585))) + (target2);
	target2 = float4(dot((ng2), float4(-0.018472567, -0.18806975, -0.09412236, -0.025784107)), dot((ng2), float4(-0.09019175, 0.017498987, -0.11218875, -0.031477705)), dot((ng2), float4(-0.0014198436, 0.06471353, 0.077031404, -0.10906885)), dot((ng2), float4(0.11438912, -0.11078878, -0.18779173, 0.074243516))) + (target2);
	target2 = float4(dot((nh2), float4(-0.06388332, 0.02474024, -0.20977338, -0.03359222)), dot((nh2), float4(0.0813248, 0.09227594, 0.058364637, 0.03962627)), dot((nh2), float4(0.1583895, -0.07166613, -0.014288648, -0.011652336)), dot((nh2), float4(-0.17604364, -0.046409506, 0.23180534, 0.08433068))) + (target2);
	target2 = float4(dot((ni2), float4(-0.05829235, 0.06738748, -0.06104219, 0.003745323)), dot((ni2), float4(-0.026256828, -0.093329325, 0.119381785, 0.14953502)), dot((ni2), float4(0.051615473, -0.03197624, 0.10763423, -0.009772352)), dot((ni2), float4(-0.082805336, 0.067339435, -0.31583574, -0.05511591))) + (target2);
	Out8 = target2;
}

void Anime4K_PS5(float4 vpos : SV_Position, float2 uv : TEXCOORD0, out float4 Out9 : SV_Target0)
{
	int2 pix = int2(uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT));
	float2 rcp = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 pos = (float2(pix) + 0.5) * rcp;
	float4 a1 = tex2Dlod(SampT3, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b1 = tex2Dlod(SampT3, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c1 = tex2Dlod(SampT3, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d1 = tex2Dlod(SampT3, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e1 = tex2Dlod(SampT3, float4(pos, 0, 0));
	float4 f1 = tex2Dlod(SampT3, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g1 = tex2Dlod(SampT3, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h1 = tex2Dlod(SampT3, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i1 = tex2Dlod(SampT3, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float4 a2 = tex2Dlod(SampT4, float4(pos + float2(-rcp.x, -rcp.y), 0, 0));
	float4 b2 = tex2Dlod(SampT4, float4(pos + float2(-rcp.x, 0), 0, 0));
	float4 c2 = tex2Dlod(SampT4, float4(pos + float2(-rcp.x, rcp.y), 0, 0));
	float4 d2 = tex2Dlod(SampT4, float4(pos + float2(0, -rcp.y), 0, 0));
	float4 e2 = tex2Dlod(SampT4, float4(pos, 0, 0));
	float4 f2 = tex2Dlod(SampT4, float4(pos + float2(0, rcp.y), 0, 0));
	float4 g2 = tex2Dlod(SampT4, float4(pos + float2(rcp.x, -rcp.y), 0, 0));
	float4 h2 = tex2Dlod(SampT4, float4(pos + float2(rcp.x, 0), 0, 0));
	float4 i2 = tex2Dlod(SampT4, float4(pos + float2(rcp.x, rcp.y), 0, 0));
	float3 result = float3( -0.0056639817, -0.0017339308, -0.0011913306 );
	result = float3(dot((max(a1, 0)), float4(-0.01858372, 0.0129101565, 0.01970984, -0.009190449)), dot((max(a1, 0)), float4(0.017144108, -0.0073674284, 0.01209068, -0.006996753)), dot((max(a1, 0)), float4(0.02794388, -0.011766938, 0.009530311, -0.0038750458))) + (result);
	result = float3(dot((max(b1, 0)), float4(0.15856947, 0.038381726, -0.011787879, 0.055921376)), dot((max(b1, 0)), float4(0.10162126, -0.017771017, -0.0152445, 0.08389841)), dot((max(b1, 0)), float4(0.08489005, -0.03226132, -0.007564454, 0.08452836))) + (result);
	result = float3(dot((max(c1, 0)), float4(0.026705442, 0.016254421, 0.03950644, -0.03793455)), dot((max(c1, 0)), float4(-0.0070655374, -0.025398912, 0.06586101, -0.04957139)), dot((max(c1, 0)), float4(-0.018199183, -0.03461042, 0.0707467, -0.04777402))) + (result);
	result = float3(dot((max(d1, 0)), float4(-0.115341224, -0.059433736, 0.010830498, 0.067396216)), dot((max(d1, 0)), float4(-0.04463122, -0.04303295, -0.011057443, 0.06553637)), dot((max(d1, 0)), float4(-0.016549354, -0.042805545, -0.0141014, 0.06705378))) + (result);
	result = float3(dot((max(e1, 0)), float4(-0.12767975, 0.11554901, -0.22092125, -0.06326996)), dot((max(e1, 0)), float4(-0.19935511, 0.11426503, -0.22041021, -0.061314825)), dot((max(e1, 0)), float4(-0.20109995, 0.11161185, -0.2142712, -0.059039716))) + (result);
	result = float3(dot((max(f1, 0)), float4(0.007717391, 0.021419598, 0.053556852, -0.09881205)), dot((max(f1, 0)), float4(-0.046238754, 0.0036924274, 0.0824714, -0.043157153)), dot((max(f1, 0)), float4(-0.056983955, -0.00033630748, 0.08295022, -0.040801782))) + (result);
	result = float3(dot((max(g1, 0)), float4(0.0052828738, 0.009478552, -0.010412882, -0.010701383)), dot((max(g1, 0)), float4(0.049702674, 0.010345037, 0.0006965096, -0.023212843)), dot((max(g1, 0)), float4(0.056108, 0.0094180945, 0.0021917222, -0.024252625))) + (result);
	result = float3(dot((max(h1, 0)), float4(0.07542127, -0.08054489, 0.09727509, 0.01325714)), dot((max(h1, 0)), float4(0.0739301, -0.037553925, 0.102272816, -0.004582272)), dot((max(h1, 0)), float4(0.06642962, -0.026762033, 0.097533874, -0.006647532))) + (result);
	result = float3(dot((max(i1, 0)), float4(0.03005975, -0.028650383, -0.071352504, 0.023253804)), dot((max(i1, 0)), float4(0.017012767, -0.0019064787, -0.019919744, 0.042413715)), dot((max(i1, 0)), float4(0.007840201, 0.01083078, -0.008299795, 0.04681489))) + (result);
	result = float3(dot((max(a2, 0)), float4(-0.052201163, 0.008365179, -0.06236095, 0.0029381379)), dot((max(a2, 0)), float4(-0.021727808, -0.016546093, -0.019278256, -0.0033039588)), dot((max(a2, 0)), float4(-0.020888992, -0.0111018475, -0.021443967, -0.006425339))) + (result);
	result = float3(dot((max(b2, 0)), float4(0.02397296, -0.013487, 0.066447854, 0.028300207)), dot((max(b2, 0)), float4(-0.041659098, 0.0067506596, 0.13331215, -0.0048033795)), dot((max(b2, 0)), float4(-0.050882675, 0.005435185, 0.13754861, -0.010058485))) + (result);
	result = float3(dot((max(c2, 0)), float4(0.08140248, -0.0112075955, -0.045716517, -0.030486025)), dot((max(c2, 0)), float4(0.018564016, 0.0022339798, -0.0076076477, -0.07539711)), dot((max(c2, 0)), float4(0.0036607496, 0.0045722146, -0.0016939791, -0.07185734))) + (result);
	result = float3(dot((max(d2, 0)), float4(-0.0155724995, -0.013894624, -0.0052947477, 0.022075793)), dot((max(d2, 0)), float4(0.048904862, -0.0061430936, -0.0176474, 0.031703226)), dot((max(d2, 0)), float4(0.059412133, -0.011662488, -0.018611705, 0.026735537))) + (result);
	result = float3(dot((max(e2, 0)), float4(-0.18287502, -0.08616293, -0.054274965, 0.06965258)), dot((max(e2, 0)), float4(-0.18703277, -0.011741755, 0.016794622, 0.08260611)), dot((max(e2, 0)), float4(-0.18331653, -0.009296464, 0.022522328, 0.08285337))) + (result);
	result = float3(dot((max(f2, 0)), float4(0.08107809, -0.031931, 0.025930194, -0.14357394)), dot((max(f2, 0)), float4(0.0336241, 0.01179566, 0.042288166, -0.11003491)), dot((max(f2, 0)), float4(0.025449684, 0.019694995, 0.04673656, -0.094090074))) + (result);
	result = float3(dot((max(g2, 0)), float4(0.007188181, -0.008030409, 0.014874803, -0.011178416)), dot((max(g2, 0)), float4(0.050626095, -0.018670242, -0.03657919, -0.004358302)), dot((max(g2, 0)), float4(0.050705966, -0.019766346, -0.034044486, -0.013611815))) + (result);
	result = float3(dot((max(h2, 0)), float4(0.07987872, -0.01514355, -0.0005701044, 0.002018227)), dot((max(h2, 0)), float4(0.11399873, 0.0068139364, -0.011158322, 0.043359682)), dot((max(h2, 0)), float4(0.12089382, 0.010206274, 0.006484812, 0.042987905))) + (result);
	result = float3(dot((max(i2, 0)), float4(0.0017806455, 0.0058658062, -0.054827355, -0.017649114)), dot((max(i2, 0)), float4(-0.0015697709, 0.021681193, -0.04541651, 0.017717479)), dot((max(i2, 0)), float4(-0.0018252691, 0.028615465, -0.027485048, 0.027309911))) + (result);
	result = float3(dot((max(-a1, 0)), float4(0.02555098, -0.0029332284, -0.019786593, 0.06648065)), dot((max(-a1, 0)), float4(-0.0028983613, 0.015552135, -0.0031676649, 0.0672302)), dot((max(-a1, 0)), float4(-0.005134733, 0.022189403, -0.0014604586, 0.04586375))) + (result);
	result = float3(dot((max(-b1, 0)), float4(-0.06674696, -0.03636718, 0.042305287, 0.033586804)), dot((max(-b1, 0)), float4(0.002328631, 0.014560653, 0.015249338, 0.00701501)), dot((max(-b1, 0)), float4(0.014039355, 0.028076636, 0.0136925895, -0.011588751))) + (result);
	result = float3(dot((max(-c1, 0)), float4(-0.039022632, -0.02614261, 0.015304643, 0.016862666)), dot((max(-c1, 0)), float4(0.015240631, 0.0051843156, -0.022641543, 0.020819275)), dot((max(-c1, 0)), float4(0.02699061, 0.012590042, -0.030434309, 0.022333218))) + (result);
	result = float3(dot((max(-d1, 0)), float4(0.08056982, 0.08762212, -0.044551965, -0.014341297)), dot((max(-d1, 0)), float4(0.026592938, 0.10150359, -0.016349116, -0.030914815)), dot((max(-d1, 0)), float4(0.009744146, 0.09662005, -0.014629014, -0.038747486))) + (result);
	result = float3(dot((max(-e1, 0)), float4(-0.048734166, -0.2345022, 0.12412277, -0.0030797734)), dot((max(-e1, 0)), float4(0.019775594, -0.23639877, 0.10245112, -0.01989389)), dot((max(-e1, 0)), float4(0.03124684, -0.22958128, 0.10389806, -0.02020691))) + (result);
	result = float3(dot((max(-f1, 0)), float4(-0.0133485105, 0.041081797, -0.02155099, 0.017466968)), dot((max(-f1, 0)), float4(0.029644802, 0.059993293, -0.035306025, -0.01866363)), dot((max(-f1, 0)), float4(0.041630358, 0.060033485, -0.03838472, -0.004764589))) + (result);
	result = float3(dot((max(-g1, 0)), float4(0.0030783121, -0.023528632, 0.020095564, 0.008429918)), dot((max(-g1, 0)), float4(-0.04064586, -0.029308239, 0.018979732, 0.021180628)), dot((max(-g1, 0)), float4(-0.04504904, -0.022441925, 0.015117934, 0.020137152))) + (result);
	result = float3(dot((max(-h1, 0)), float4(0.0012200709, 0.08750284, -0.09627132, -0.05180081)), dot((max(-h1, 0)), float4(0.013313984, 0.038747437, -0.09706183, -0.03555434)), dot((max(-h1, 0)), float4(0.014122978, 0.027102578, -0.09405641, -0.021694236))) + (result);
	result = float3(dot((max(-i1, 0)), float4(-0.022396728, 0.045423746, 0.05618814, -0.014828652)), dot((max(-i1, 0)), float4(-0.018316073, 0.025315331, 0.022210265, -0.010245087)), dot((max(-i1, 0)), float4(-0.01250564, 0.010639915, 0.014195103, 0.0020570823))) + (result);
	result = float3(dot((max(-a2, 0)), float4(0.046651457, -0.0077845114, 0.01338984, 0.0014878022)), dot((max(-a2, 0)), float4(0.001333767, -0.012861641, 0.029198132, 0.020025207)), dot((max(-a2, 0)), float4(-0.003572458, -0.015116351, 0.026183384, 0.024829973))) + (result);
	result = float3(dot((max(-b2, 0)), float4(-0.09506711, 0.02552611, 0.03234602, -0.034516744)), dot((max(-b2, 0)), float4(-0.06541528, 0.01181497, -0.03153924, 0.00018784113)), dot((max(-b2, 0)), float4(-0.051106647, 0.0020236392, -0.035502207, 0.0085376045))) + (result);
	result = float3(dot((max(-c2, 0)), float4(-0.05945615, -0.0061961384, 0.044197917, -0.04109929)), dot((max(-c2, 0)), float4(-0.0046793907, -0.0040663416, -0.033448357, 0.006773195)), dot((max(-c2, 0)), float4(0.011128929, -0.010319631, -0.04109943, 0.016976412))) + (result);
	result = float3(dot((max(-d2, 0)), float4(0.02855516, -0.06393814, -0.058905125, -0.013616608)), dot((max(-d2, 0)), float4(-0.033051047, -0.082921155, -0.038639963, -0.007876684)), dot((max(-d2, 0)), float4(-0.04864978, -0.0730681, -0.027698845, -0.006182652))) + (result);
	result = float3(dot((max(-e2, 0)), float4(0.15423118, 0.1485341, 0.1263968, 0.04213644)), dot((max(-e2, 0)), float4(0.14667909, 0.096721016, 0.088775866, 0.020989005)), dot((max(-e2, 0)), float4(0.14534634, 0.0820024, 0.083860956, 0.010447147))) + (result);
	result = float3(dot((max(-f2, 0)), float4(-0.068275765, 0.03738383, -0.0011161854, 0.052985556)), dot((max(-f2, 0)), float4(-0.018390667, 0.019398715, -0.039955888, 0.017621813)), dot((max(-f2, 0)), float4(-0.011452603, 0.005998161, -0.04444185, 0.009551621))) + (result);
	result = float3(dot((max(-g2, 0)), float4(0.01387326, -0.034494568, 0.0074023325, 0.00019609048)), dot((max(-g2, 0)), float4(-0.0033411914, -0.019219222, 0.022065453, -0.0042242454)), dot((max(-g2, 0)), float4(-0.009420935, -0.009562797, 0.027121471, 2.0403608e-05))) + (result);
	result = float3(dot((max(-h2, 0)), float4(-0.015793918, 0.004534637, -0.055682972, 0.043045517)), dot((max(-h2, 0)), float4(-0.024342488, -0.025236975, -0.054670315, -0.0075941198)), dot((max(-h2, 0)), float4(-0.037188973, -0.028567247, -0.06584981, -0.014196169))) + (result);
	result = float3(dot((max(-i2, 0)), float4(0.0132598495, 0.010604703, 0.030967329, 0.008636854)), dot((max(-i2, 0)), float4(0.01775289, -0.007352816, 0.027615465, -0.033379406)), dot((max(-i2, 0)), float4(0.017206183, -0.017301153, 0.0145311365, -0.042725433))) + (result);
	result += tex2Dlod(SampInput, float4(pos, 0, 0)).rgb;
	Out9 = float4(result, 1.0);
}

technique Anime4K_Restore_Soft_L
{
	pass P1
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS1a;
		RenderTarget0 = Anime4K_T1;
	}
	pass P2
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS1b;
		RenderTarget0 = Anime4K_T2;
	}
	pass P3
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS2a;
		RenderTarget0 = Anime4K_T3;
	}
	pass P4
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS2b;
		RenderTarget0 = Anime4K_T4;
	}
	pass P5
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS3a;
		RenderTarget0 = Anime4K_T1;
	}
	pass P6
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS3b;
		RenderTarget0 = Anime4K_T2;
	}
	pass P7
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS4a;
		RenderTarget0 = Anime4K_T3;
	}
	pass P8
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS4b;
		RenderTarget0 = Anime4K_T4;
	}
	pass P9
	{
		VertexShader = Anime4K_VS;
		PixelShader = Anime4K_PS5;
	}
}
