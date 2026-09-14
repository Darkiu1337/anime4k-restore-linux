// Anime4K Restore CNN (L) ported to ReShade FX.
// Source: Magpie Anime4K_Restore_L.hlsl <- bloc97/Anime4K glsl/Restore.
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
	float4 target1 = float4( -0.44569078, -0.084358215, -0.014156722, -0.0353374 );
	target1 = float4(dot((src00), float3(-0.27899465, 0.2164516, -0.009546488)), dot((src00), float3(-0.14974926, -0.47826648, -0.24541017)), dot((src00), float3(0.6271667, 0.09537477, -0.20505093)), dot((src00), float3(-0.04888494, 0.16404815, -0.11507772))) + (target1);
	target1 = float4(dot((src01), float3(-0.22372562, -0.10638798, 0.24542068)), dot((src01), float3(0.046120282, -0.010795577, 0.11135218)), dot((src01), float3(0.44437107, 0.19478157, -0.27672207)), dot((src01), float3(0.54215515, 0.5756847, 0.09624475))) + (target1);
	target1 = float4(dot((src02), float3(0.1703517, 0.2102622, -0.32159516)), dot((src02), float3(-0.17810228, 0.08207581, -0.017147528)), dot((src02), float3(-0.34460765, 0.17641851, 0.41743183)), dot((src02), float3(-0.40586865, 0.23701222, 0.19025058))) + (target1);
	target1 = float4(dot((src10), float3(0.4708481, -0.36032093, -0.09320259)), dot((src10), float3(-0.1587934, -0.044305246, -0.23072109)), dot((src10), float3(-0.15760423, 0.19414884, 0.0242641)), dot((src10), float3(-0.11388875, 0.31109568, 0.040976923))) + (target1);
	target1 = float4(dot((src11), float3(0.00951417, 0.15047263, -0.12219134)), dot((src11), float3(0.2746557, 0.08832856, 0.12957081)), dot((src11), float3(-0.49743456, -0.24360974, 0.2876983)), dot((src11), float3(0.14564055, -0.3517844, 0.13303527))) + (target1);
	target1 = float4(dot((src12), float3(-0.12760738, -0.26698044, 0.3510441)), dot((src12), float3(0.16703783, -0.096000046, 0.2620507)), dot((src12), float3(0.04391735, -0.46030682, -0.30533043)), dot((src12), float3(0.34657615, -0.38363042, -0.32785))) + (target1);
	target1 = float4(dot((src20), float3(0.63138646, -0.04012397, -0.045394078)), dot((src20), float3(-0.12703805, -0.1390924, 0.18203364)), dot((src20), float3(0.38107973, 0.07578805, 0.16900069)), dot((src20), float3(-0.09134196, -0.09274019, 0.13399005))) + (target1);
	target1 = float4(dot((src21), float3(-0.13648264, 0.40967095, -0.00555831)), dot((src21), float3(-0.13971807, 0.19853555, 0.06922444)), dot((src21), float3(-0.32322997, -0.26386982, 0.034828495)), dot((src21), float3(-0.08377875, -0.50860924, -0.08413197))) + (target1);
	target1 = float4(dot((src22), float3(0.21196735, -0.30186844, -0.074009515)), dot((src22), float3(0.24934316, 0.44828892, -0.34400147)), dot((src22), float3(-0.27111465, 0.35906994, -0.22145566)), dot((src22), float3(-0.19941513, -0.35723612, -0.15622428))) + (target1);
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
	float4 target2 = float4( -0.009787335, 0.051148742, -0.007458707, -0.016416457 );
	target2 = float4(dot((src00), float3(0.1953752, 0.2346731, -0.05342483)), dot((src00), float3(-0.09707663, 0.085327715, 0.112148136)), dot((src00), float3(0.43315637, 0.36244828, 0.07938104)), dot((src00), float3(0.3862221, 0.06630519, 0.14795923))) + (target2);
	target2 = float4(dot((src01), float3(0.25197014, -0.36539522, -0.4117931)), dot((src01), float3(0.032906674, 0.10986396, 0.46616048)), dot((src01), float3(0.3392793, 0.5440999, 0.0827279)), dot((src01), float3(0.18099307, 0.41803896, 0.040264074))) + (target2);
	target2 = float4(dot((src02), float3(-0.060543116, -0.08720925, 0.15297869)), dot((src02), float3(0.34531194, 0.63656414, -0.11485237)), dot((src02), float3(-0.3202978, -0.052656054, -0.21027736)), dot((src02), float3(0.32803985, -0.076137036, -0.24086118))) + (target2);
	target2 = float4(dot((src10), float3(-0.2044052, 0.19812255, 0.31697252)), dot((src10), float3(0.111065395, -0.3797384, -0.31267545)), dot((src10), float3(-0.36082193, 0.03176089, -0.068170965)), dot((src10), float3(-0.39179638, -0.35085422, -0.06266394))) + (target2);
	target2 = float4(dot((src11), float3(0.0055682547, -0.25253078, 0.005511427)), dot((src11), float3(0.24352197, -0.4218859, -0.36491954)), dot((src11), float3(0.08972456, 0.08408476, 0.3825727)), dot((src11), float3(-0.4340704, -0.5052765, 0.01774532))) + (target2);
	target2 = float4(dot((src12), float3(0.13323675, -0.5879293, -0.09206729)), dot((src12), float3(-0.6641518, -0.1286407, 0.41892347)), dot((src12), float3(-0.38277033, 0.1355451, 0.16736335)), dot((src12), float3(0.67553586, 0.19463064, -0.017109495))) + (target2);
	target2 = float4(dot((src20), float3(0.0627963, 0.21872504, 0.2814043)), dot((src20), float3(0.29361042, -0.21531922, -0.1474019)), dot((src20), float3(0.23339616, -0.5016595, 0.08778552)), dot((src20), float3(-0.42217752, 0.20158494, 0.28085083))) + (target2);
	target2 = float4(dot((src21), float3(-0.009900911, 0.541632, 0.1506882)), dot((src21), float3(-0.42754972, -0.28397697, 0.15196925)), dot((src21), float3(0.02737237, -0.36375052, -0.30358136)), dot((src21), float3(-0.17740859, -0.172693, -0.29542333))) + (target2);
	target2 = float4(dot((src22), float3(-0.3690586, 0.121049926, -0.34591553)), dot((src22), float3(0.19382606, 0.54470515, -0.14778244)), dot((src22), float3(-0.040331036, -0.23628974, -0.23809184)), dot((src22), float3(-0.14121497, 0.20663929, 0.12616424))) + (target2);
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
	float4 target1 = float4( -0.02852779, 0.027645616, 0.06510905, 0.029781172 );
	target1 = float4(dot((a1), float4(0.028458824, 0.035127334, -0.26446894, -0.10270838)), dot((a1), float4(0.10831271, 0.14161696, -0.053199783, -0.3593573)), dot((a1), float4(0.017246738, 0.3893337, 0.053528484, 0.049874853)), dot((a1), float4(0.42066097, 0.18358134, -0.3486933, 0.08600247))) + (target1);
	target1 = float4(dot((b1), float4(-0.15829772, -0.29878524, -0.049366333, 0.029009456)), dot((b1), float4(-0.31038332, 0.10245719, -0.03277819, -0.18138678)), dot((b1), float4(0.0423391, 0.004307728, -0.062031534, 0.17342477)), dot((b1), float4(-0.11978196, 0.052934717, -0.004734159, -0.1632741))) + (target1);
	target1 = float4(dot((c1), float4(-0.14941882, -0.014216013, -0.20317195, 0.08515265)), dot((c1), float4(-0.3337916, -0.34028724, 0.17806017, 0.092163175)), dot((c1), float4(-0.07740701, 0.06367363, -0.14011545, -0.036603887)), dot((c1), float4(-0.8221198, -0.19704603, 0.05067841, -0.2528259))) + (target1);
	target1 = float4(dot((d1), float4(0.044333473, 0.013970764, 0.04531751, 0.0565207)), dot((d1), float4(0.10871938, -0.21189599, -0.20269018, 0.073703125)), dot((d1), float4(-0.12288588, -0.0757029, 0.038650505, -0.10746413)), dot((d1), float4(0.0077913217, 0.055366833, -0.09677452, 0.22798601))) + (target1);
	target1 = float4(dot((e1), float4(0.33476707, -0.14572862, 0.18070522, 0.16165797)), dot((e1), float4(0.22631067, -0.21331434, 0.34974626, 0.28470036)), dot((e1), float4(0.10190012, 0.024614803, 0.028480766, 0.23497322)), dot((e1), float4(0.25268495, -0.26254398, -0.07855834, -0.15804033))) + (target1);
	target1 = float4(dot((f1), float4(-0.09853942, -0.16078049, -0.13042259, -0.099300735)), dot((f1), float4(-0.21105993, 0.08541815, 0.0253011, 0.07577514)), dot((f1), float4(0.27787793, 0.16101131, -0.05298311, 0.041623414)), dot((f1), float4(0.24688315, -0.0005086922, 0.16506846, -0.18045023))) + (target1);
	target1 = float4(dot((g1), float4(-0.015007392, 0.2049891, -0.1651912, 0.025189033)), dot((g1), float4(0.0720429, -0.061911974, 0.1125125, 0.061680123)), dot((g1), float4(-0.018456718, -0.10679284, 0.55918777, -0.13096866)), dot((g1), float4(0.012792885, 0.2530616, 0.1414716, -0.035809774))) + (target1);
	target1 = float4(dot((h1), float4(0.037606955, 0.31857902, 0.051491242, -0.198442)), dot((h1), float4(0.05987735, -0.058445334, 0.12321206, 0.093920216)), dot((h1), float4(-0.09903669, 0.10280441, 0.14069863, -0.015952505)), dot((h1), float4(0.09681222, -0.0018247474, -0.013259678, -0.3040559))) + (target1);
	target1 = float4(dot((i1), float4(0.044491854, 0.36708844, -0.101501055, -0.19508216)), dot((i1), float4(0.079992026, -0.14958903, -0.05275797, -0.088995665)), dot((i1), float4(-0.07424999, -0.060033463, -0.0099711865, -0.025926083)), dot((i1), float4(0.064774506, -0.5950615, 0.075409986, 0.023040347))) + (target1);
	target1 = float4(dot((a2), float4(-0.00168658, -0.027147152, 0.18404783, -0.022954177)), dot((a2), float4(0.1879708, 0.0013266837, -0.088930264, 0.15315148)), dot((a2), float4(-0.08964568, 0.043110568, -0.0841814, 0.00096489635)), dot((a2), float4(0.124567054, -0.16238526, -0.06812457, 0.21262483))) + (target1);
	target1 = float4(dot((b2), float4(0.03728663, -0.032217886, -0.15136409, 0.20516208)), dot((b2), float4(0.16259944, -0.043085426, -0.21990341, 0.32518774)), dot((b2), float4(0.2534931, -0.37875995, 0.0043716, -0.15583529)), dot((b2), float4(-0.10620075, 0.16151664, 0.1293011, 0.20054214))) + (target1);
	target1 = float4(dot((c2), float4(0.05088376, 0.020740725, 0.011289051, 0.06747376)), dot((c2), float4(-0.21300486, 0.028916309, -0.24014536, -0.3315815)), dot((c2), float4(0.30702966, 0.14391874, -0.2176207, 0.07900332)), dot((c2), float4(0.09044539, 0.15526149, 0.09995701, -0.26542482))) + (target1);
	target1 = float4(dot((d2), float4(0.15973654, -0.24198112, 0.05717073, -0.2708247)), dot((d2), float4(0.2114867, -0.10985252, 0.019566689, 0.2845983)), dot((d2), float4(-0.19423203, 0.056409992, -0.12794583, -0.048893075)), dot((d2), float4(-0.1529657, 0.111373484, 0.006978016, -0.09198705))) + (target1);
	target1 = float4(dot((e2), float4(0.07690064, -0.122893825, -0.0431315, 0.049651224)), dot((e2), float4(0.038431194, -0.022761922, 0.19884229, 0.3001686)), dot((e2), float4(0.1205243, -0.10097431, -0.053464055, -0.05545239)), dot((e2), float4(0.1320201, 0.022808496, -0.08487898, 0.48026356))) + (target1);
	target1 = float4(dot((f2), float4(0.04079296, 0.06027275, 0.14123397, 0.10914477)), dot((f2), float4(0.052179057, -0.083381295, 0.12711276, -0.22596069)), dot((f2), float4(0.08785134, -0.29543424, 0.08260646, -0.15743312)), dot((f2), float4(0.17674746, -0.10703248, 0.23608543, 0.103631504))) + (target1);
	target1 = float4(dot((g2), float4(0.038997833, -0.20137171, 0.25628343, -0.07446986)), dot((g2), float4(-0.14136268, 0.0115205245, 0.06598252, 0.29977)), dot((g2), float4(-0.31973416, 0.22825807, -0.003479285, 0.08878428)), dot((g2), float4(0.11666723, -0.14853193, -0.12315031, 0.15130284))) + (target1);
	target1 = float4(dot((h2), float4(-0.04147214, -0.06448227, -0.17228132, 0.21867155)), dot((h2), float4(-0.050535224, -0.086743675, -0.18035689, 0.02585289)), dot((h2), float4(-0.21205503, 0.029389668, -0.09757749, 0.13752261)), dot((h2), float4(-0.07425368, -0.07494379, 0.13929781, 0.17800835))) + (target1);
	target1 = float4(dot((i2), float4(0.20552272, 0.08278268, 0.087584734, 0.29423076)), dot((i2), float4(-0.03113836, -0.17029381, -0.026447749, 0.016036067)), dot((i2), float4(-0.201244, -0.0008433311, 0.09185437, -0.17132477)), dot((i2), float4(-0.07602455, -0.11591232, 0.15650395, 0.09271113))) + (target1);
	target1 = float4(dot((na1), float4(0.09120441, 0.04248785, -0.0109574385, 0.2740676)), dot((na1), float4(0.1345777, -0.14849417, -0.15350367, 0.1931403)), dot((na1), float4(0.0468555, -0.013588658, 0.1872175, 0.049231507)), dot((na1), float4(0.2635145, -0.12794739, -0.17311442, -0.17728893))) + (target1);
	target1 = float4(dot((nb1), float4(0.0265621, 0.25218308, -0.17352693, -0.19486824)), dot((nb1), float4(0.10291274, -0.027579704, -0.16788955, 0.035516337)), dot((nb1), float4(-0.0884961, 0.044006765, -0.1829588, -0.04287895)), dot((nb1), float4(-0.086093664, -0.05947863, -0.19120377, -0.059360266))) + (target1);
	target1 = float4(dot((nc1), float4(-0.0077623413, -0.014011599, 0.14976685, -0.015102705)), dot((nc1), float4(0.061803013, 0.23037176, -0.0017081804, -0.07807527)), dot((nc1), float4(-0.14371866, 0.09881457, -0.0420665, 0.053166322)), dot((nc1), float4(-0.2929254, -0.018942501, 0.075949386, 0.21431307))) + (target1);
	target1 = float4(dot((nd1), float4(0.15482867, -0.08669985, -0.11653363, 0.002487127)), dot((nd1), float4(-0.13303289, -0.26125848, -0.022335036, -0.053429328)), dot((nd1), float4(0.05441111, 0.085498355, -0.019448604, 0.07700748)), dot((nd1), float4(0.20482185, 0.06895137, -0.19071092, -0.15176988))) + (target1);
	target1 = float4(dot((ne1), float4(0.058373976, 0.1348292, -0.14086236, -0.2190568)), dot((ne1), float4(-0.18893883, -0.037208326, -0.08550504, -0.01693728)), dot((ne1), float4(0.063239604, 0.121938735, 0.18930112, -0.110385895)), dot((ne1), float4(-0.16802256, 0.123416096, -0.07056712, -0.10306489))) + (target1);
	target1 = float4(dot((nf1), float4(-0.21300407, 0.008286501, -0.10365199, -0.039589003)), dot((nf1), float4(-0.049379632, -0.12187443, 0.15844372, -0.027428184)), dot((nf1), float4(0.13865358, -0.11094277, 0.068476856, 0.022865763)), dot((nf1), float4(0.0037872058, 0.021951213, -0.09683496, 0.067510754))) + (target1);
	target1 = float4(dot((ng1), float4(0.05690448, 0.07831065, 0.16295952, -0.0968358)), dot((ng1), float4(-0.09136643, 0.015976364, 0.17686251, 0.024937721)), dot((ng1), float4(-0.17356895, -0.06423979, -0.26599383, -0.10509048)), dot((ng1), float4(-0.18716863, -0.01891357, -0.11806091, -0.097365916))) + (target1);
	target1 = float4(dot((nh1), float4(-0.06446155, 0.20326103, -0.033653136, 0.0154429395)), dot((nh1), float4(0.05177888, -0.04118929, 0.13276093, -0.12517625)), dot((nh1), float4(-0.019579697, 0.07845964, -0.061998203, -0.022282483)), dot((nh1), float4(0.046922565, 0.15494241, -0.049391422, 0.14295246))) + (target1);
	target1 = float4(dot((ni1), float4(-0.102786146, 0.17208168, -0.051487174, 0.15695319)), dot((ni1), float4(0.028481564, -0.24589455, 0.14276022, 0.13917996)), dot((ni1), float4(0.12239765, -0.045410756, 0.26189017, 0.07303566)), dot((ni1), float4(0.010855834, 0.17422688, -0.0027747392, -0.055219136))) + (target1);
	target1 = float4(dot((na2), float4(0.014127897, 0.12229517, -0.22651868, 0.124154285)), dot((na2), float4(-0.13218386, -0.32898104, 0.111792624, 0.016944582)), dot((na2), float4(-0.4342469, -0.21103851, 0.020457482, -0.14404331)), dot((na2), float4(-0.10977742, 0.06275854, -0.048701756, 0.054385293))) + (target1);
	target1 = float4(dot((nb2), float4(0.09574338, -0.28155354, 0.06535372, 0.08769791)), dot((nb2), float4(0.04884873, 0.03411368, 0.40051946, -0.011710461)), dot((nb2), float4(-0.12329247, -0.017508674, -0.24508828, 0.10430247)), dot((nb2), float4(0.3191857, -0.28257895, 0.05891001, 0.096506774))) + (target1);
	target1 = float4(dot((nc2), float4(0.036757194, 0.19377777, 0.054016564, 0.015482294)), dot((nc2), float4(0.1374388, -0.053538468, 0.2677718, -0.08899067)), dot((nc2), float4(-0.14553823, -0.32605696, 0.26038665, 0.26156536)), dot((nc2), float4(0.11012423, 0.07757925, 0.029049544, 0.26035222))) + (target1);
	target1 = float4(dot((nd2), float4(-0.19651565, 0.34684682, 0.07256215, 0.24001615)), dot((nd2), float4(0.30669728, -0.040679373, -0.018623354, -0.007573629)), dot((nd2), float4(-0.03192298, -0.0006501724, -0.021843085, -0.25308976)), dot((nd2), float4(0.090777226, -0.069249466, 0.026858928, -0.08101683))) + (target1);
	target1 = float4(dot((ne2), float4(-0.19491735, 0.1478019, 0.051415507, 0.052763764)), dot((ne2), float4(0.29386947, 0.11557711, -0.009313462, 0.06731275)), dot((ne2), float4(-0.16541481, 0.09745131, 0.17577961, 0.038889345)), dot((ne2), float4(-0.12270087, -0.037188005, 0.30678266, 0.01219997))) + (target1);
	target1 = float4(dot((nf2), float4(0.21972072, -0.24501611, -0.13467999, 0.07995422)), dot((nf2), float4(-0.16669928, 0.10681031, 0.019233517, -0.091647364)), dot((nf2), float4(-0.0471254, -0.10724696, -0.2220906, 0.0524831)), dot((nf2), float4(0.07962133, 0.046246808, 0.11756837, 0.2427797))) + (target1);
	target1 = float4(dot((ng2), float4(-0.018560572, -0.04259962, 0.019554865, 0.29822263)), dot((ng2), float4(0.28909272, -0.2526796, 0.052288387, -0.10352501)), dot((ng2), float4(0.27052113, 0.24546415, 0.22942105, -0.17112546)), dot((ng2), float4(-0.16862495, 0.13772464, 0.14541095, -0.22842947))) + (target1);
	target1 = float4(dot((nh2), float4(-0.052647978, -0.13620298, 0.03873432, -0.18878175)), dot((nh2), float4(0.17638408, 0.14337336, 0.13013794, 0.11648163)), dot((nh2), float4(0.2265538, 0.057785455, 0.24192083, 0.0049888026)), dot((nh2), float4(-0.028214354, 0.14105307, -0.104368195, -0.17706485))) + (target1);
	target1 = float4(dot((ni2), float4(0.003658791, -0.26248586, -0.082900435, -0.06499875)), dot((ni2), float4(0.057943232, 0.29328227, -0.034102313, 0.15446658)), dot((ni2), float4(-0.013143919, 0.18253878, -0.05913703, -0.08087537)), dot((ni2), float4(0.08626453, 0.05693778, -0.11045182, 0.18904833))) + (target1);
	float4 target2 = float4( 0.019262059, 0.043436494, -0.124304086, -0.014933208 );
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
	float4 target1 = float4( -0.02852779, 0.027645616, 0.06510905, 0.029781172 );
	float4 target2 = float4( 0.019262059, 0.043436494, -0.124304086, -0.014933208 );
	target2 = float4(dot((a1), float4(0.06138475, 0.1439015, 0.06993285, 0.095201865)), dot((a1), float4(0.120526604, -0.5261169, 0.1210301, 0.50708395)), dot((a1), float4(0.22381006, 0.25294203, -0.10087704, 0.17403544)), dot((a1), float4(0.12570442, 0.04825834, 0.038996983, -0.17137507))) + (target2);
	target2 = float4(dot((b1), float4(0.09580414, -0.02090535, -0.03217946, -0.115907624)), dot((b1), float4(-0.17387998, 0.2655171, -0.12866813, 0.032473654)), dot((b1), float4(0.10757996, -0.38653868, -0.049665075, 0.36145476)), dot((b1), float4(0.15188572, -0.014376933, -0.048535764, 0.3830508))) + (target2);
	target2 = float4(dot((c1), float4(-0.19303346, -0.063043006, 0.037174225, 0.17105488)), dot((c1), float4(-0.30462784, -0.10658377, 0.13507952, 0.07546837)), dot((c1), float4(-0.21706793, 0.08729471, -0.06391928, 0.36270198)), dot((c1), float4(-0.0123182135, -0.27184415, -0.035610817, 0.13315013))) + (target2);
	target2 = float4(dot((d1), float4(-0.1559421, -0.008261901, 0.20574443, -0.045140598)), dot((d1), float4(0.03859168, 0.17584307, -0.09199424, 0.026080446)), dot((d1), float4(0.058586795, 0.07892688, -0.2572033, 0.30986732)), dot((d1), float4(0.1457787, 0.16024348, -0.06435325, -0.02853244))) + (target2);
	target2 = float4(dot((e1), float4(0.06647865, 0.22215, -0.10444975, 0.1533982)), dot((e1), float4(-0.13637248, 0.0282581, 0.039713558, 0.115156986)), dot((e1), float4(-0.2077229, -0.124256276, 0.031975772, 0.14176169)), dot((e1), float4(-0.18015774, -0.18235172, -0.14737205, -0.12018837))) + (target2);
	target2 = float4(dot((f1), float4(-0.24000446, 0.19062491, -0.20497306, -0.09002585)), dot((f1), float4(0.08672003, -0.04505737, 0.0068228757, -0.019980771)), dot((f1), float4(-0.209317, -0.097432695, -0.07930878, -0.13450326)), dot((f1), float4(0.1853504, -0.12218054, -0.045916412, 0.08838858))) + (target2);
	target2 = float4(dot((g1), float4(-0.005804602, -0.3263357, 0.034840938, -0.049774483)), dot((g1), float4(0.05149589, -0.048428953, -0.12834811, -0.07062978)), dot((g1), float4(0.18930501, -0.0062948675, -0.19660017, 0.18116258)), dot((g1), float4(-0.07475797, -0.12957661, 0.13469964, -0.2945365))) + (target2);
	target2 = float4(dot((h1), float4(0.021823233, 0.101564035, -0.08054271, 0.005698307)), dot((h1), float4(0.17687339, -0.058118407, 0.07140431, 0.0925754)), dot((h1), float4(0.035116684, 0.035971403, -0.24807848, -0.16337888)), dot((h1), float4(-0.14888434, 0.304605, -0.014870848, -0.072692335))) + (target2);
	target2 = float4(dot((i1), float4(0.15357393, 0.26516896, 0.21697883, -0.073649734)), dot((i1), float4(0.05702486, 0.08939279, -0.011976994, -0.063365534)), dot((i1), float4(0.1838928, 0.040435348, -0.10517768, 0.07981437)), dot((i1), float4(-0.052683312, 0.035939544, 0.1004424, -0.13724971))) + (target2);
	target2 = float4(dot((a2), float4(0.06887319, -0.0530729, -0.15481988, 0.0665599)), dot((a2), float4(-0.031427335, -0.27738956, -0.22141118, 0.13679637)), dot((a2), float4(-0.05686962, -0.22601964, -0.19417213, -0.09932399)), dot((a2), float4(0.031254467, -0.16733547, 0.052291542, -0.021917146))) + (target2);
	target2 = float4(dot((b2), float4(0.0043880343, -0.05736109, 0.09653438, -0.04347404)), dot((b2), float4(-0.03320605, -0.015415265, -0.30665413, -0.26863584)), dot((b2), float4(-0.09556491, -0.12861155, 0.12456121, -0.12057121)), dot((b2), float4(0.064986005, 0.07442758, -0.015494559, -0.12873033))) + (target2);
	target2 = float4(dot((c2), float4(0.43038133, -0.08742217, -0.17349729, -0.062275372)), dot((c2), float4(0.117590204, -0.077595286, -0.02995379, 0.18847479)), dot((c2), float4(-0.012805269, 0.01795713, 0.01733494, -0.014758355)), dot((c2), float4(0.06656798, -0.010100221, 0.012438303, -0.13591917))) + (target2);
	target2 = float4(dot((d2), float4(-0.20219825, 0.10264473, 0.04169048, 0.09925883)), dot((d2), float4(0.33157164, 0.13553555, 0.031988595, -0.15372548)), dot((d2), float4(-0.036087956, 0.057454523, -0.20171835, -0.14060175)), dot((d2), float4(0.078742586, 0.09034125, -0.018051006, -0.012530946))) + (target2);
	target2 = float4(dot((e2), float4(-0.20762882, 0.027042268, 0.012678151, 0.026435647)), dot((e2), float4(-0.23219623, 0.068265386, -0.09496996, 0.040384647)), dot((e2), float4(0.044476848, -0.053666174, -0.073195405, -0.15589063)), dot((e2), float4(-0.080212615, 0.051648133, 0.23230731, -0.17085052))) + (target2);
	target2 = float4(dot((f2), float4(0.06897319, -0.22830063, -0.05995797, -0.008890125)), dot((f2), float4(-0.06360793, -0.12295911, -0.04077969, 0.005834341)), dot((f2), float4(-0.12517554, 0.20943281, 0.029862454, -0.038162317)), dot((f2), float4(-0.106191345, 0.11263121, 0.12051529, 0.05707114))) + (target2);
	target2 = float4(dot((g2), float4(0.091504954, 0.14714013, -0.17375562, 0.12345911)), dot((g2), float4(-0.054357428, 0.14976494, 0.024148121, 0.120711684)), dot((g2), float4(0.18441072, 0.119183995, 0.08745399, -0.23350039)), dot((g2), float4(0.16866787, 0.11771104, 0.175893, -0.035989728))) + (target2);
	target2 = float4(dot((h2), float4(-0.30777606, 0.049725976, 0.26913685, 0.014296343)), dot((h2), float4(0.028484846, 0.02831735, 0.005740985, 0.15206927)), dot((h2), float4(0.19993277, 0.09492996, 0.025957806, 0.035486884)), dot((h2), float4(-0.12934783, 0.28220424, 0.047272105, 0.09940966))) + (target2);
	target2 = float4(dot((i2), float4(-0.11630714, -0.21128473, 0.04961249, -0.0021338738)), dot((i2), float4(-0.034275923, -0.043662123, -0.03669543, -0.095983095)), dot((i2), float4(0.26804927, 0.24287297, -0.11308307, 0.12524886)), dot((i2), float4(0.1088897, 0.1738188, 0.007536927, 0.091356605))) + (target2);
	target2 = float4(dot((na1), float4(0.21231711, -0.268304, -0.12023363, -0.11473893)), dot((na1), float4(0.19442785, -0.377306, 0.20652951, 0.22179964)), dot((na1), float4(0.047695257, 0.21314003, -0.027571363, -0.21924159)), dot((na1), float4(-0.058896706, -0.09257493, 0.36026677, 0.14666505))) + (target2);
	target2 = float4(dot((nb1), float4(0.04660883, -0.11054424, -0.16950387, 0.1014651)), dot((nb1), float4(-0.22199874, -0.2047386, 0.2577728, -0.09075356)), dot((nb1), float4(-0.2171105, 0.18756013, 0.048406947, -0.21746674)), dot((nb1), float4(0.32090327, 0.08749142, 0.1380687, -0.2651618))) + (target2);
	target2 = float4(dot((nc1), float4(-0.1928378, 0.100953236, -0.046625864, -0.10984389)), dot((nc1), float4(0.11190454, -0.008598421, -0.051161833, -0.040151004)), dot((nc1), float4(0.32514498, 0.02124068, 0.13504188, -0.08592605)), dot((nc1), float4(0.32336533, 0.0043789423, -0.049233675, 0.13862692))) + (target2);
	target2 = float4(dot((nd1), float4(0.057035644, 0.13528337, 0.088931166, 0.066797465)), dot((nd1), float4(-0.086490445, -0.10338058, 0.19410637, 0.09427754)), dot((nd1), float4(0.17654544, -0.08174943, 0.19873992, -0.17926928)), dot((nd1), float4(-0.096670695, -0.11349738, 0.01418258, -0.12299086))) + (target2);
	target2 = float4(dot((ne1), float4(-0.010706926, 0.08166401, 0.09370084, -0.13244434)), dot((ne1), float4(0.040176257, 0.103450865, -0.022440543, -0.18850644)), dot((ne1), float4(-0.12350328, -0.062155697, 0.036917962, -0.069766395)), dot((ne1), float4(-0.11089934, -0.10264778, -0.20901524, -0.042853933))) + (target2);
	target2 = float4(dot((nf1), float4(0.0064649805, -0.21635285, 0.26282236, 0.0797657)), dot((nf1), float4(0.09057663, -0.0064749196, -0.057637256, 0.050011456)), dot((nf1), float4(0.042877126, 0.04875745, -0.037890673, 0.07423098)), dot((nf1), float4(-0.22078879, -1.3261495e-05, 0.0102023715, -0.055722862))) + (target2);
	target2 = float4(dot((ng1), float4(-0.21198633, 0.12338858, -0.046889607, -0.069868185)), dot((ng1), float4(-0.16919948, -0.037561033, -0.005447934, -0.014526121)), dot((ng1), float4(-0.12337323, -0.013671757, -0.043364853, -0.14131337)), dot((ng1), float4(-0.06970269, 0.12396114, -0.2882593, 0.12157274))) + (target2);
	target2 = float4(dot((nh1), float4(-0.07510719, -0.034031168, -0.014431461, -0.07422713)), dot((nh1), float4(0.024486735, 0.025101706, -0.12288865, 0.0011266146)), dot((nh1), float4(0.056790795, -0.05993126, 0.11686025, -0.06630191)), dot((nh1), float4(0.12515159, -0.053233545, -0.22278062, 0.077075236))) + (target2);
	target2 = float4(dot((ni1), float4(0.15784621, -0.0764334, 0.005342607, 0.09241874)), dot((ni1), float4(-0.0009692987, 0.036327295, -0.17614163, -0.02230073)), dot((ni1), float4(0.057809148, -0.107915476, 0.017190281, 0.015017511)), dot((ni1), float4(-0.17506301, 0.41731307, -0.17021762, 0.1081785))) + (target2);
	target2 = float4(dot((na2), float4(-0.04213655, -0.0071511404, 0.17119752, 0.019918554)), dot((na2), float4(0.07620985, 0.026105708, -0.1083619, -0.21432641)), dot((na2), float4(-0.24124615, 0.35026863, -0.011338781, 0.045009304)), dot((na2), float4(-0.0389524, 0.0391313, -0.13909689, -0.2289899))) + (target2);
	target2 = float4(dot((nb2), float4(-0.003247703, -0.16778667, -0.06569662, 0.09470385)), dot((nb2), float4(0.13921799, 0.05676625, 0.18568343, 0.20842068)), dot((nb2), float4(0.23126572, 0.17198953, -0.13698709, 0.22716486)), dot((nb2), float4(-0.11244338, 0.2891844, 0.014525318, -0.044944298))) + (target2);
	target2 = float4(dot((nc2), float4(-0.036239535, -0.15562424, 0.17654738, 0.29869553)), dot((nc2), float4(0.21613471, -0.030107146, -0.16532254, -0.19921502)), dot((nc2), float4(0.0571368, -0.0881642, -0.19526796, -0.10570262)), dot((nc2), float4(0.0133618545, -0.3056589, -0.09598035, 0.12562469))) + (target2);
	target2 = float4(dot((nd2), float4(0.139326, 0.019128725, -0.063348524, -0.20621236)), dot((nd2), float4(-0.18395935, 0.06724899, 0.034003522, 0.20389429)), dot((nd2), float4(-0.14525263, 0.18320693, 0.1160608, 0.008165468)), dot((nd2), float4(-0.1019923, -0.15844813, 0.16281077, -0.3147023))) + (target2);
	target2 = float4(dot((ne2), float4(0.0031874597, 0.014905972, -0.34928575, -0.06541263)), dot((ne2), float4(-0.17282559, -0.115991496, -0.41152355, 0.09083862)), dot((ne2), float4(-0.19517206, -0.17772576, 0.15671544, 0.12386179)), dot((ne2), float4(-0.057723213, 0.10005784, 0.16953272, -0.17146301))) + (target2);
	target2 = float4(dot((nf2), float4(0.024222312, -0.038439997, -0.1334096, 0.09314227)), dot((nf2), float4(0.06139789, 0.04822463, -0.10939595, -0.018837357)), dot((nf2), float4(0.13585247, -0.31542218, -0.20957507, -0.09913242)), dot((nf2), float4(0.048212904, 0.12828648, 0.14276013, -0.0690483))) + (target2);
	target2 = float4(dot((ng2), float4(-0.059516154, 0.35043675, 0.10024693, -0.22365399)), dot((ng2), float4(0.03142432, -0.17421962, -0.044191923, -0.011058562)), dot((ng2), float4(-0.08262814, 0.034954365, 0.18297553, 0.1576469)), dot((ng2), float4(0.12844399, -0.0052628545, -0.045441866, -0.22479026))) + (target2);
	target2 = float4(dot((nh2), float4(0.11010148, -0.12474922, -0.21814698, -0.019019049)), dot((nh2), float4(-0.109644935, 0.20629437, -0.2983182, -0.11332389)), dot((nh2), float4(-0.06213465, -0.03891448, 0.16088112, 0.04115874)), dot((nh2), float4(0.06469803, -0.032074396, 0.02542415, -0.15403947))) + (target2);
	target2 = float4(dot((ni2), float4(-0.07334427, 0.10194824, -0.069830835, 0.15190491)), dot((ni2), float4(0.065546006, -0.0076101148, 0.2215555, 0.12348823)), dot((ni2), float4(-0.059299644, -0.26384652, 0.41080138, -0.16904834)), dot((ni2), float4(0.1712592, -0.012047153, 0.051534526, -0.20517784))) + (target2);
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
	float4 target1 = float4( -0.15367588, -0.07928099, 0.063567765, 0.108769014 );
	target1 = float4(dot((a1), float4(-0.20542079, 0.03036114, -0.13495351, -0.09928467)), dot((a1), float4(0.26111016, 0.04244865, 0.14393657, 0.0038359873)), dot((a1), float4(0.0036034626, -0.20747331, 0.050192088, -0.026470508)), dot((a1), float4(-0.16608916, 0.06865131, 0.13718198, 0.012319453))) + (target1);
	target1 = float4(dot((b1), float4(0.019964145, 0.06856654, 0.030265702, -0.29398966)), dot((b1), float4(0.038375776, -0.08331041, -0.12478692, -0.14264)), dot((b1), float4(0.003130048, -0.049974114, -0.009842687, -0.08436449)), dot((b1), float4(-0.07945381, -0.011174098, 0.028310193, 0.18336426))) + (target1);
	target1 = float4(dot((c1), float4(0.07453813, -0.19164173, 0.27373666, 0.033324502)), dot((c1), float4(0.018200234, -0.15623717, -0.08550347, -0.086211175)), dot((c1), float4(-0.1406476, -0.057000756, -0.05088059, -0.010092321)), dot((c1), float4(0.027974837, 0.029960351, -0.10246706, -0.11165423))) + (target1);
	target1 = float4(dot((d1), float4(-0.17666292, -0.1336137, 0.09373522, 0.10959183)), dot((d1), float4(0.26951888, 0.13550404, -0.032812368, 0.0164411)), dot((d1), float4(0.24166632, -0.19008428, -0.018434448, -0.17436402)), dot((d1), float4(-0.118283056, 0.0041048722, -0.008766052, 0.11861692))) + (target1);
	target1 = float4(dot((e1), float4(0.059816767, 0.11052112, 0.036759567, 0.34936142)), dot((e1), float4(0.0632236, -0.0630564, -0.10445141, -0.091659166)), dot((e1), float4(-0.18595679, 0.32736167, -0.16695334, 0.25245044)), dot((e1), float4(-0.10951594, 0.016436215, -0.09536692, 0.064123355))) + (target1);
	target1 = float4(dot((f1), float4(0.23698406, 0.10176531, 0.20899844, -0.22031465)), dot((f1), float4(-0.030446773, -0.091048814, -0.026074586, 0.09148875)), dot((f1), float4(0.20418753, 0.06913646, 0.031215316, -0.058892634)), dot((f1), float4(0.030977655, 0.070524976, -0.14815283, -0.042353395))) + (target1);
	target1 = float4(dot((g1), float4(-0.022295577, -0.05808369, 0.14538866, -0.1457713)), dot((g1), float4(0.23975989, -0.005154714, -0.13725305, -0.043883465)), dot((g1), float4(-0.03795945, 0.02775734, 0.079675056, -0.11575635)), dot((g1), float4(-0.13689965, -0.06821517, 0.015865099, 0.092833005))) + (target1);
	target1 = float4(dot((h1), float4(0.008460874, 0.04562443, 0.16193573, -0.042831287)), dot((h1), float4(0.09447306, 0.12490515, 0.03871189, 0.047627136)), dot((h1), float4(0.14322506, 0.19263941, 0.0042382013, -0.18002886)), dot((h1), float4(-0.0063166656, 0.07084753, -0.026311405, 0.03910702))) + (target1);
	target1 = float4(dot((i1), float4(0.08485893, -0.2406554, 0.018253349, 0.12692702)), dot((i1), float4(0.099010445, 0.11303921, 0.018407846, -0.22019249)), dot((i1), float4(0.1808653, 0.03609519, 0.04515686, 0.17978671)), dot((i1), float4(0.098906465, 0.102015704, -0.1044267, -0.11714096))) + (target1);
	target1 = float4(dot((a2), float4(0.37482956, -0.3257375, 0.19455267, 0.1208413)), dot((a2), float4(0.037982, 0.026353687, -0.20558092, -0.022922885)), dot((a2), float4(-0.2527836, -0.42709586, 0.040543195, -0.0527519)), dot((a2), float4(-0.07246249, 0.15230247, 0.30100232, -0.2754452))) + (target1);
	target1 = float4(dot((b2), float4(-0.39697862, -0.042094186, -0.2315796, 0.11569712)), dot((b2), float4(0.59894156, -0.11699173, 0.1926384, 0.080500975)), dot((b2), float4(-0.14519346, -0.3065778, 0.19640557, -0.24562629)), dot((b2), float4(-0.21375597, 0.045603614, 0.023360144, -0.11990825))) + (target1);
	target1 = float4(dot((c2), float4(0.030446287, -0.04726904, 0.074864194, 0.23434684)), dot((c2), float4(-0.2191283, -0.06145154, 0.048508577, -0.1291551)), dot((c2), float4(-0.020313436, -0.10886858, -0.024673669, -0.04299077)), dot((c2), float4(0.12092218, -0.016195009, 0.10286324, -0.12459363))) + (target1);
	target1 = float4(dot((d2), float4(0.064445384, -0.15216815, 0.42238462, -0.10399166)), dot((d2), float4(0.16708861, 0.12578042, -0.4330836, 0.1914047)), dot((d2), float4(0.10306973, -0.575184, -0.26651257, 0.15641387)), dot((d2), float4(-0.13419592, -0.46423253, 0.57413465, 0.07064538))) + (target1);
	target1 = float4(dot((e2), float4(0.04809328, -0.12840022, -0.31553897, 0.029389234)), dot((e2), float4(-0.12349369, 0.022170544, -0.07833276, -0.017229239)), dot((e2), float4(0.1853755, -0.26412117, -0.17104533, -0.052230056)), dot((e2), float4(-0.013703159, -0.30681273, 0.03156802, -0.04573632))) + (target1);
	target1 = float4(dot((f2), float4(-0.1380467, 0.24012493, 0.16879074, 0.19021708)), dot((f2), float4(0.31759852, -0.04863545, 0.10763089, -0.099481724)), dot((f2), float4(0.06532168, -0.21709125, 0.22363038, -0.0073404606)), dot((f2), float4(0.19637011, -0.21216264, -0.14004646, 0.04956918))) + (target1);
	target1 = float4(dot((g2), float4(-0.068974994, 0.035919234, 0.17026006, -0.0074473396)), dot((g2), float4(0.5005385, 0.039779782, -0.17971572, 0.119821966)), dot((g2), float4(-0.12780246, 0.0028248294, -0.20932221, 0.28552157)), dot((g2), float4(0.05813948, -0.21344285, -0.0862113, -0.027787263))) + (target1);
	target1 = float4(dot((h2), float4(0.20083936, 0.09285405, 0.098670855, -0.13034628)), dot((h2), float4(-0.08729008, 0.074680895, -0.31036818, 0.07905559)), dot((h2), float4(-0.01474545, -0.11493401, 0.01269914, 0.0018419055)), dot((h2), float4(0.061849594, -0.35524356, -0.06409305, -0.047743056))) + (target1);
	target1 = float4(dot((i2), float4(-0.0008763842, 0.11757835, -0.036117654, 0.18442062)), dot((i2), float4(0.16266613, -0.01075886, -0.016920915, -0.0119510535)), dot((i2), float4(-0.13819253, 0.13635348, -0.003860492, 0.1574026)), dot((i2), float4(0.04136551, 0.14200751, -0.14361666, 0.11443297))) + (target1);
	target1 = float4(dot((na1), float4(-0.26120907, 0.094762795, -0.012533703, 0.060918808)), dot((na1), float4(0.0040505654, -0.27338502, 0.17356302, -0.10248847)), dot((na1), float4(-0.01111041, 0.18852817, -0.2594928, 0.12710676)), dot((na1), float4(-0.028482055, -0.15605745, -0.04016552, 0.1503744))) + (target1);
	target1 = float4(dot((nb1), float4(0.24577981, 0.09629815, -0.13252918, -0.104840726)), dot((nb1), float4(-0.047384363, -0.042157363, 0.0941419, 0.11820465)), dot((nb1), float4(-0.13740875, 0.17206886, -0.048901185, 0.17454259)), dot((nb1), float4(0.058981817, 0.06895825, 0.052710008, 0.05037063))) + (target1);
	target1 = float4(dot((nc1), float4(-0.2239817, -0.21029685, 0.18478145, -0.11439347)), dot((nc1), float4(0.4553206, -0.032555267, -0.09538145, 0.17596558)), dot((nc1), float4(-0.017824922, -0.08916583, 0.052327603, 0.054506473)), dot((nc1), float4(-0.050273463, 0.10736202, 0.12728482, -0.017638389))) + (target1);
	target1 = float4(dot((nd1), float4(-0.072854675, 0.1548192, 0.033900462, 0.12673119)), dot((nd1), float4(0.015542916, -0.22573462, 0.23870395, 0.08014363)), dot((nd1), float4(-0.1950096, -0.20828351, 0.11434291, 0.022457503)), dot((nd1), float4(0.06664522, 0.16661869, 0.21813981, 0.20910633))) + (target1);
	target1 = float4(dot((ne1), float4(0.2652937, -0.21500582, -0.29559842, -0.41371983)), dot((ne1), float4(0.17511544, -0.036195952, 0.25977176, -0.14120851)), dot((ne1), float4(-0.10850216, -0.04102979, 0.24641588, 0.109116435)), dot((ne1), float4(0.081340194, -0.15212043, 0.13869548, 0.22358306))) + (target1);
	target1 = float4(dot((nf1), float4(-0.108154014, -0.24589789, -0.0045436365, -0.033278447)), dot((nf1), float4(0.35006878, -0.06516491, -0.17755373, -0.10501602)), dot((nf1), float4(-0.055340957, -0.03474703, -0.039802775, -0.089266)), dot((nf1), float4(-0.23728919, -0.047869515, 0.21740748, -0.04061338))) + (target1);
	target1 = float4(dot((ng1), float4(0.028205335, -0.052365907, 0.05030947, 0.0021801728)), dot((ng1), float4(0.003054092, -0.13063054, 0.21224388, -0.12858267)), dot((ng1), float4(0.14546792, -0.08356806, 0.45320153, -0.10686808)), dot((ng1), float4(-0.10006339, 0.20927623, 0.0051093665, 0.21674173))) + (target1);
	target1 = float4(dot((nh1), float4(0.10200768, -0.22834082, -0.13871242, -0.11108624)), dot((nh1), float4(0.13099737, 0.055208363, -0.06423964, -0.17557982)), dot((nh1), float4(0.13514566, -0.20808199, 0.3320781, -0.12519105)), dot((nh1), float4(-0.17343043, -0.0015957861, 0.051521134, 0.067071475))) + (target1);
	target1 = float4(dot((ni1), float4(0.20798117, -0.06927812, 0.10575524, -0.16368344)), dot((ni1), float4(-0.046690967, 0.072701424, -0.063635424, 0.2196707)), dot((ni1), float4(0.17071529, -0.30537283, -0.044293836, -0.29370767)), dot((ni1), float4(-0.29893485, -0.16406195, 0.08667325, 0.16401167))) + (target1);
	target1 = float4(dot((na2), float4(-0.04009042, -0.09724303, -0.061678827, -0.12645799)), dot((na2), float4(-0.034136664, 0.13140567, -0.19032978, -0.27027693)), dot((na2), float4(0.15880232, -0.15769257, 0.11843628, -0.19899485)), dot((na2), float4(-0.058544576, 0.05637733, -0.25161943, 0.2231074))) + (target1);
	target1 = float4(dot((nb2), float4(0.07176237, -0.1705716, 0.24187793, 0.19674404)), dot((nb2), float4(-0.12067612, -0.039632697, 0.015815722, -0.040387046)), dot((nb2), float4(-0.070081174, -0.22599341, -0.03722175, 0.03916034)), dot((nb2), float4(0.10180745, -0.12012279, 0.098794326, 0.013947429))) + (target1);
	target1 = float4(dot((nc2), float4(-0.06389604, 0.08498287, -0.17497064, -0.17787372)), dot((nc2), float4(0.04532417, -0.0912261, 0.12473174, 0.21546759)), dot((nc2), float4(-0.20961155, -0.17840882, 0.025784912, -0.081276976)), dot((nc2), float4(-0.22151196, -0.13550358, -0.060957976, -0.0057096705))) + (target1);
	target1 = float4(dot((nd2), float4(-0.09308164, -0.07466555, 0.043592792, 0.07106228)), dot((nd2), float4(-0.036254935, 0.18080021, -0.15068708, -0.15757518)), dot((nd2), float4(0.07291895, -0.012473155, 0.19074705, -0.19600157)), dot((nd2), float4(-0.010599356, 0.24264692, -0.1608174, 0.21481107))) + (target1);
	target1 = float4(dot((ne2), float4(0.10340095, -0.018766372, -0.11288012, -0.015592831)), dot((ne2), float4(0.14977756, -0.0006462305, -0.10881946, 0.088430114)), dot((ne2), float4(-0.18035571, 0.12609644, 0.016426437, -0.019637503)), dot((ne2), float4(-0.00454613, -0.022229725, 0.047212575, -0.15445113))) + (target1);
	target1 = float4(dot((nf2), float4(0.13125896, 0.016590014, 0.059466217, 0.02189435)), dot((nf2), float4(-0.05610665, -0.14247346, 0.10401916, 0.016297683)), dot((nf2), float4(0.04579115, -0.045108374, -0.114898264, -0.11828137)), dot((nf2), float4(-0.20584439, -0.07701804, 0.15725806, -0.07996226))) + (target1);
	target1 = float4(dot((ng2), float4(-0.038534615, -0.08618927, -0.08664565, 0.120940305)), dot((ng2), float4(0.046327326, 0.1135833, 0.068627, -0.106959745)), dot((ng2), float4(0.04947746, -0.008643036, -0.06325347, 0.022951378)), dot((ng2), float4(0.07890686, -0.019718027, 0.04222515, 0.14290553))) + (target1);
	target1 = float4(dot((nh2), float4(0.06408585, 0.26087278, -0.12800066, 0.23841377)), dot((nh2), float4(0.19215317, -0.124888204, 0.12517492, 0.1347636)), dot((nh2), float4(0.05731193, -0.15473562, -0.06680967, 0.17279463)), dot((nh2), float4(0.09329293, -0.037721, 0.09497935, 0.0038290594))) + (target1);
	target1 = float4(dot((ni2), float4(0.08006353, 0.13953096, 0.11157642, -0.08118929)), dot((ni2), float4(-0.07942165, -0.14270853, -0.12486184, -0.04684391)), dot((ni2), float4(0.14611697, -0.009859328, -0.0709194, 0.049433514)), dot((ni2), float4(0.053477652, -0.21148224, 0.16277598, -0.28911993))) + (target1);
	float4 target2 = float4( -0.038157728, 0.01904009, 0.07848918, -0.04052424 );
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
	float4 target1 = float4( -0.15367588, -0.07928099, 0.063567765, 0.108769014 );
	float4 target2 = float4( -0.038157728, 0.01904009, 0.07848918, -0.04052424 );
	target2 = float4(dot((a1), float4(0.13100185, -0.00046575023, -0.028316915, -0.178982)), dot((a1), float4(0.028466834, -0.08175499, -0.037371337, 0.06893543)), dot((a1), float4(0.21762301, -0.07715949, -0.16343145, -0.12027178)), dot((a1), float4(0.07392093, 0.056365166, -0.078509934, 0.06993414))) + (target2);
	target2 = float4(dot((b1), float4(0.07834248, -0.04749886, -0.07693013, -0.30249342)), dot((b1), float4(0.046873976, -0.101967975, 0.016892025, -0.08455913)), dot((b1), float4(0.23983683, -0.082395144, -0.08877053, 0.09002741)), dot((b1), float4(-0.06646688, -0.015339724, 0.14534354, -0.12472986))) + (target2);
	target2 = float4(dot((c1), float4(-0.039911453, -0.013332275, 0.23202884, -0.046906233)), dot((c1), float4(0.11150177, -0.119128324, 0.06459362, -0.07916646)), dot((c1), float4(-0.009199328, -0.09285867, 0.071042486, -0.07528521)), dot((c1), float4(0.043733858, 0.007959111, 0.09901959, 0.05652529))) + (target2);
	target2 = float4(dot((d1), float4(0.12189273, -0.1058494, 0.08731556, 0.0825902)), dot((d1), float4(-0.07608036, -0.045247663, -0.07916306, 0.21166702)), dot((d1), float4(-0.09632985, 0.016788295, -0.17591585, -0.14786263)), dot((d1), float4(-0.03643418, 0.046447262, 0.070336945, 0.012765127))) + (target2);
	target2 = float4(dot((e1), float4(-0.15099311, 0.22785337, -0.022553608, 0.0862727)), dot((e1), float4(-0.082614996, -0.0015175309, -0.120723926, -0.02351105)), dot((e1), float4(-0.010447922, 0.21255092, 0.0561124, 0.037588555)), dot((e1), float4(-0.2116295, 0.058660604, 0.018720774, -0.013596472))) + (target2);
	target2 = float4(dot((f1), float4(-0.17424586, -0.08027999, -0.03548984, 0.061380606)), dot((f1), float4(-0.091873385, -0.07241797, -0.047187436, 0.13889132)), dot((f1), float4(0.20892383, 0.035928074, 0.17053668, -0.041030813)), dot((f1), float4(0.3079469, -0.031040983, 0.39115313, -0.022435248))) + (target2);
	target2 = float4(dot((g1), float4(-0.0037971158, 0.05087685, 0.18993643, 0.078527555)), dot((g1), float4(-0.19398233, 0.114212446, -0.025265925, -0.13106133)), dot((g1), float4(-0.041492697, 0.09395637, -0.17716514, 0.09158833)), dot((g1), float4(-0.08632908, -0.12073027, -0.062493253, -0.08067098))) + (target2);
	target2 = float4(dot((h1), float4(0.11454478, 0.10180192, 0.25377235, 0.13214986)), dot((h1), float4(-0.053314645, -0.05165681, -0.16350931, 0.056609593)), dot((h1), float4(0.02932442, 0.1415095, -0.07908212, -0.029691117)), dot((h1), float4(-0.052710265, -0.0886421, 0.081858, -0.1963397))) + (target2);
	target2 = float4(dot((i1), float4(0.13833676, -0.13303484, -0.037423257, 0.12330872)), dot((i1), float4(0.024542026, -0.0951515, -0.1693348, -0.15478514)), dot((i1), float4(-0.07700002, -0.031009076, 0.015715523, 0.14523397)), dot((i1), float4(-0.016948726, 0.055997517, 0.053379383, 0.18046756))) + (target2);
	target2 = float4(dot((a2), float4(0.20786218, -0.34138504, -0.002008598, 0.13962908)), dot((a2), float4(0.14361653, -0.0025990994, 0.23800024, 0.089462794)), dot((a2), float4(0.49472246, -0.43033788, 0.04231959, -0.14335507)), dot((a2), float4(0.09881262, -0.00039400125, 0.028620182, 0.008409915))) + (target2);
	target2 = float4(dot((b2), float4(-0.12720335, -0.20555046, 0.44234744, -0.014688707)), dot((b2), float4(-0.3409636, -0.027020821, -0.07148167, 0.21288827)), dot((b2), float4(-0.023997113, -0.235406, 0.00064560794, 0.17666213)), dot((b2), float4(0.026997993, 0.09561914, -0.1726457, -0.11264844))) + (target2);
	target2 = float4(dot((c2), float4(-0.38011166, -0.14633556, -0.25248998, -0.048109)), dot((c2), float4(0.014146791, 0.11139822, 0.12499596, -0.006033096)), dot((c2), float4(0.03394759, -0.25683075, -0.004184047, 0.028591031)), dot((c2), float4(0.08368928, 0.07368074, 0.192279, 0.15288617))) + (target2);
	target2 = float4(dot((d2), float4(0.10880278, 0.10378925, -0.30380723, -0.049251713)), dot((d2), float4(-0.02255051, -0.22322227, 0.3183636, 0.12848853)), dot((d2), float4(0.21004406, -0.11731474, 0.18248428, 0.012738647)), dot((d2), float4(-0.034776326, -0.11443079, -0.10215758, 0.03222829))) + (target2);
	target2 = float4(dot((e2), float4(0.54890627, -0.07293127, -0.41021585, 0.11343489)), dot((e2), float4(0.20614935, -0.004283575, -0.050092876, 0.21473971)), dot((e2), float4(-0.019661043, -0.036939718, 0.023610009, -0.06997083)), dot((e2), float4(-0.07782363, 0.19752185, -0.23783271, -0.10420534))) + (target2);
	target2 = float4(dot((f2), float4(-0.08103626, 0.08222839, 0.069200024, 0.029297108)), dot((f2), float4(0.091647685, 0.12299736, 0.0005504728, 0.17425247)), dot((f2), float4(-0.17259495, -0.12480139, 0.01590888, 0.055239804)), dot((f2), float4(-0.24478562, 0.08303869, -0.029884247, -0.06290667))) + (target2);
	target2 = float4(dot((g2), float4(-0.25949356, 0.14846909, -0.1748046, 0.09585216)), dot((g2), float4(-0.049375266, 0.07249825, 0.1839563, 0.07619667)), dot((g2), float4(-0.19764636, -0.038826656, -0.015786756, 0.010932837)), dot((g2), float4(0.04848412, -0.15756363, 0.012645979, 0.06530666))) + (target2);
	target2 = float4(dot((h2), float4(-0.0592303, 0.22237164, 0.034741532, 0.1708352)), dot((h2), float4(0.34068975, 0.041179545, 0.06565189, 0.057039484)), dot((h2), float4(-0.0043445593, -0.046396293, 0.13475078, 0.037506044)), dot((h2), float4(0.25165552, 0.22462137, 0.08480505, -0.34036627))) + (target2);
	target2 = float4(dot((i2), float4(-0.10844713, 0.031758603, 0.094929375, 0.007969798)), dot((i2), float4(0.113506734, -0.06955974, 0.18194464, -0.0590313)), dot((i2), float4(-0.14367405, -0.068098925, -0.045276128, 0.05033309)), dot((i2), float4(0.111787796, 0.14282043, -0.0032632013, 0.06328967))) + (target2);
	target2 = float4(dot((na1), float4(-0.08094655, -0.017061448, 0.25499284, 0.022350369)), dot((na1), float4(-0.08266014, 0.26350877, -0.3347594, -0.08235582)), dot((na1), float4(-0.31147677, 0.10840224, 0.25973678, 0.29226762)), dot((na1), float4(-0.062742665, -0.16414656, 0.15623575, -0.14951667))) + (target2);
	target2 = float4(dot((nb1), float4(0.16715927, 0.07248268, 0.19906871, 0.09488815)), dot((nb1), float4(0.31846005, -0.1295353, 0.06366751, -0.09006814)), dot((nb1), float4(-0.007528655, 0.119970314, -0.055744495, -0.1341)), dot((nb1), float4(-0.04655408, 0.00721155, 0.11151067, -0.12335882))) + (target2);
	target2 = float4(dot((nc1), float4(-0.18715191, -0.20222618, 0.31153843, 0.12800919)), dot((nc1), float4(-0.06641214, -0.08882262, 0.10280565, 0.059373695)), dot((nc1), float4(-0.24086717, 0.09281967, -0.06487702, 0.108098336)), dot((nc1), float4(-0.13160741, -0.14381158, -0.0030142434, -0.025091475))) + (target2);
	target2 = float4(dot((nd1), float4(-0.26941344, 0.057776485, 0.198899, 0.0801663)), dot((nd1), float4(-0.010607985, 0.032416668, -0.12861459, -0.2101018)), dot((nd1), float4(-0.059500597, -0.0014182271, 0.1999814, 0.110617965)), dot((nd1), float4(-0.087650314, -0.053006213, 0.053311568, -0.02017489))) + (target2);
	target2 = float4(dot((ne1), float4(-0.0888614, -0.17749546, -0.14922594, 0.18076904)), dot((ne1), float4(-0.07155236, 0.041163083, -0.11169263, 0.084879614)), dot((ne1), float4(-0.019973263, 0.07273392, -0.069319114, -0.04125808)), dot((ne1), float4(-0.12744384, -0.09820898, -0.04354858, 0.068733074))) + (target2);
	target2 = float4(dot((nf1), float4(0.025723739, 0.040670983, -0.21262506, 0.03154805)), dot((nf1), float4(-0.3071993, 0.29252282, -0.026296655, 0.07315552)), dot((nf1), float4(-0.26200652, -0.14551005, 0.16694368, 0.13088223)), dot((nf1), float4(-0.24551399, 0.111219764, 0.0041154358, -0.10842478))) + (target2);
	target2 = float4(dot((ng1), float4(0.070245974, -0.09198143, 0.18428285, -0.40322223)), dot((ng1), float4(0.110039465, 0.07932312, -0.026307642, 0.18879798)), dot((ng1), float4(0.19028768, 0.09101255, 0.099789225, 0.010587032)), dot((ng1), float4(-0.042884093, 0.046001278, -0.12612925, 0.055332247))) + (target2);
	target2 = float4(dot((nh1), float4(-0.057069883, -0.19471937, -0.14167733, -0.06429918)), dot((nh1), float4(-0.032890134, 0.18182398, 0.25903046, 0.02668084)), dot((nh1), float4(-0.0513947, -0.2119559, 0.18162172, 0.077179454)), dot((nh1), float4(-0.074211985, 0.2439066, -0.007826057, 0.023550559))) + (target2);
	target2 = float4(dot((ni1), float4(0.14551505, 0.016579725, -0.060423456, -0.1003253)), dot((ni1), float4(0.11689716, 0.03988999, 0.39282638, -0.0412654)), dot((ni1), float4(0.28027633, 0.074107096, -0.005255287, -0.117815144)), dot((ni1), float4(-0.18079606, -0.15190484, 0.09286323, -0.22671913))) + (target2);
	target2 = float4(dot((na2), float4(-0.26655, 0.038483843, -0.13007571, -0.11957963)), dot((na2), float4(0.02524124, -0.18752888, 0.11942783, -0.061313108)), dot((na2), float4(-0.15780295, 0.12708266, 0.1515452, 0.18422426)), dot((na2), float4(0.010378331, 0.020122316, 0.068273015, -0.16399868))) + (target2);
	target2 = float4(dot((nb2), float4(-0.17614686, -0.027063683, -0.15957421, 0.1611069)), dot((nb2), float4(0.12740774, 0.004154653, 0.103997365, -0.017016938)), dot((nb2), float4(-0.12034426, -0.1892024, 0.12231665, 0.03224853)), dot((nb2), float4(0.00811552, -0.051516473, -0.082051665, 0.16816284))) + (target2);
	target2 = float4(dot((nc2), float4(-0.15254295, -0.060000043, 0.033083163, 0.05829016)), dot((nc2), float4(-0.011885901, 0.020979656, -0.016063845, 0.055933036)), dot((nc2), float4(-0.03317691, -0.11068878, -0.03998401, 0.0152959)), dot((nc2), float4(0.076534435, 0.17345367, -0.14917895, -0.11680771))) + (target2);
	target2 = float4(dot((nd2), float4(-0.22236426, 0.017353376, 0.20352198, -0.09962889)), dot((nd2), float4(0.093723886, -0.0092351325, 0.060595278, -0.014900563)), dot((nd2), float4(0.004360134, -0.16306834, 0.08691345, -0.15118423)), dot((nd2), float4(0.05051143, 0.031693168, 0.25801733, -0.096163675))) + (target2);
	target2 = float4(dot((ne2), float4(-0.19981825, 0.005621798, 0.30247143, -0.21744101)), dot((ne2), float4(-0.21788603, 0.0943901, 0.06899553, -0.015869575)), dot((ne2), float4(0.20982541, -0.17422888, -0.16009268, 0.095568515)), dot((ne2), float4(-0.113621205, -0.18507147, 0.067299575, -0.036854178))) + (target2);
	target2 = float4(dot((nf2), float4(0.06810536, -0.12038678, 0.09067457, -0.37008765)), dot((nf2), float4(0.11014666, 0.015001737, 0.11136803, 0.07137436)), dot((nf2), float4(0.24017857, -0.17134188, 0.024367718, 0.122724056)), dot((nf2), float4(0.12042336, 0.10343175, -0.13199149, 0.06668219))) + (target2);
	target2 = float4(dot((ng2), float4(0.28085753, -0.15860316, 0.06810539, -0.025948122)), dot((ng2), float4(-0.14428541, -0.06101108, -0.07249347, 0.0910616)), dot((ng2), float4(0.08978648, -0.18904316, -0.10909362, -0.17025243)), dot((ng2), float4(0.05202615, 0.104275696, 0.019484319, -0.035804044))) + (target2);
	target2 = float4(dot((nh2), float4(0.10040864, 0.050312318, -0.16425262, 0.0024454365)), dot((nh2), float4(-0.27650854, 0.14849235, -0.14445016, -0.009127519)), dot((nh2), float4(-0.029030709, -0.059385244, -0.22415695, -0.24255885)), dot((nh2), float4(-0.0531634, -0.13935417, 0.04330054, -0.06303984))) + (target2);
	target2 = float4(dot((ni2), float4(0.054911103, 0.041680478, -0.15814131, -0.22732499)), dot((ni2), float4(-0.2811866, 0.1959676, -0.15958795, -0.082894124)), dot((ni2), float4(-0.049883213, -0.15021674, 0.15639575, 0.06674789)), dot((ni2), float4(0.09221324, -0.006908881, -0.10088554, -0.10491449))) + (target2);
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
	float4 target1 = float4( 0.046519246, -0.00879819, -0.044789877, -0.07887647 );
	target1 = float4(dot((a1), float4(0.044146776, 0.02972265, -0.13192074, 0.097702436)), dot((a1), float4(-0.026106803, -0.05223942, 0.12351806, 0.10298012)), dot((a1), float4(-0.15219912, 0.06760582, 0.0855665, -0.03555207)), dot((a1), float4(-0.15929134, 0.04324784, -0.11861024, 0.06544868))) + (target1);
	target1 = float4(dot((b1), float4(0.05458123, 0.057214983, -0.029938918, -0.0037866347)), dot((b1), float4(0.014500078, -0.06896361, -0.013474177, -0.06600103)), dot((b1), float4(0.048824716, -0.052671798, 0.10448471, -0.19298725)), dot((b1), float4(0.14172198, 0.10043398, 0.29896173, -0.119502924))) + (target1);
	target1 = float4(dot((c1), float4(-0.07483799, -0.047863305, 0.019309495, 0.1447018)), dot((c1), float4(0.0757225, -0.08091319, 0.13153689, -0.09976335)), dot((c1), float4(-0.07432271, -0.13640103, 0.14757608, -0.06094595)), dot((c1), float4(-0.02994328, -0.16553412, 0.041081686, -0.019380448))) + (target1);
	target1 = float4(dot((d1), float4(-0.116722435, -0.10093022, -0.17313154, -0.025453486)), dot((d1), float4(0.018069802, 0.15039717, 0.072606385, -0.0014705429)), dot((d1), float4(0.082960755, 0.16740529, 0.1134366, 0.073060215)), dot((d1), float4(0.25008422, 0.08372216, 0.09108986, -0.0786531))) + (target1);
	target1 = float4(dot((e1), float4(-0.22601452, -0.008671738, -0.26501563, 0.1170102)), dot((e1), float4(0.5512376, -0.058479775, -0.030529302, -0.25060177)), dot((e1), float4(-0.11920107, -0.268992, -0.04196243, 0.060350843)), dot((e1), float4(-0.12763597, -0.06614402, 0.13161187, -0.1524947))) + (target1);
	target1 = float4(dot((f1), float4(-0.1648866, 0.21542753, -0.05141525, -0.22469969)), dot((f1), float4(0.05652559, -0.116541564, -0.039133884, 0.09842997)), dot((f1), float4(-0.040925294, -0.08021358, -0.1124311, 0.10967242)), dot((f1), float4(-0.11008188, -0.13785587, 0.17472316, -0.020226078))) + (target1);
	target1 = float4(dot((g1), float4(-0.12250246, 0.07088387, -0.1497167, 0.022598455)), dot((g1), float4(0.10348344, 0.27629474, 0.048863184, 0.08864282)), dot((g1), float4(-0.018174428, 0.049727917, 0.00309108, -0.048928354)), dot((g1), float4(0.037790317, -0.0011699499, 0.12177124, 0.088068075))) + (target1);
	target1 = float4(dot((h1), float4(0.043115202, 0.008603091, -0.15786794, 0.04094072)), dot((h1), float4(0.24277024, -0.36454508, -0.008746184, 0.042499837)), dot((h1), float4(0.17749861, 0.09997063, 0.06689776, -0.05387774)), dot((h1), float4(0.10550521, 0.11979698, -0.20002088, -0.10426778))) + (target1);
	target1 = float4(dot((i1), float4(0.06600674, -0.08001964, -0.124739006, 0.17875427)), dot((i1), float4(0.07645438, -0.09341582, -0.007209568, 0.0779068)), dot((i1), float4(0.015209062, 0.008619914, -0.06492457, -0.09997953)), dot((i1), float4(0.23262201, 0.093308866, 0.22863889, -0.021379821))) + (target1);
	target1 = float4(dot((a2), float4(-0.043263335, 0.13361873, -0.02345517, -0.11997134)), dot((a2), float4(0.1548246, -0.10850825, 0.030159235, 0.0948639)), dot((a2), float4(0.09254137, 0.09901608, -0.0043304237, -0.09261292)), dot((a2), float4(0.16256322, -0.0753444, 0.19805421, 0.1167355))) + (target1);
	target1 = float4(dot((b2), float4(0.1042119, -0.02642236, 0.04868224, -0.2364328)), dot((b2), float4(-0.08793884, -0.032897346, 0.04438529, -0.039592575)), dot((b2), float4(-0.15884337, -0.07664125, -0.083366744, -0.15421078)), dot((b2), float4(-0.08414226, 0.064429455, -0.06398503, 0.17369357))) + (target1);
	target1 = float4(dot((c2), float4(0.20374978, 0.053481918, -0.07322327, 0.030998409)), dot((c2), float4(-0.09289948, -0.062769525, 0.071623735, -0.0572314)), dot((c2), float4(-0.25493136, -0.052148513, -0.05846495, -0.30425155)), dot((c2), float4(0.028119517, -0.20336467, 0.23537324, 0.17616381))) + (target1);
	target1 = float4(dot((d2), float4(-0.008999034, 0.005153292, 0.07379054, 0.090993404)), dot((d2), float4(0.19063166, 0.17091888, 0.0416411, -0.17546643)), dot((d2), float4(-0.16384077, 0.05193965, 0.007373337, -0.14595066)), dot((d2), float4(0.08840229, -0.09363918, -0.002444226, 0.19029109))) + (target1);
	target1 = float4(dot((e2), float4(-0.07473051, 0.014621785, 0.024686797, -0.11145659)), dot((e2), float4(0.022953797, -0.029232977, -0.0376939, -0.23659907)), dot((e2), float4(0.3694185, -0.0163784, 0.106044516, 0.11254082)), dot((e2), float4(-0.000816042, 0.30796757, 0.10191429, 0.078495234))) + (target1);
	target1 = float4(dot((f2), float4(0.05722472, 0.0063364087, -0.069067486, -0.25257275)), dot((f2), float4(0.014075986, 0.07042797, -0.07245758, -0.19943956)), dot((f2), float4(0.077577166, 0.013867829, 0.059568863, -0.19534364)), dot((f2), float4(-0.1319451, -0.01543331, 0.06195517, -0.1566254))) + (target1);
	target1 = float4(dot((g2), float4(0.10666801, 0.07621112, 0.09204845, 0.007946626)), dot((g2), float4(0.19854072, 0.103370175, 0.04930996, -0.09155877)), dot((g2), float4(-0.14524002, 0.003522481, -0.009533781, -0.18856467)), dot((g2), float4(0.21727695, -0.03526533, 0.071561396, 0.11516717))) + (target1);
	target1 = float4(dot((h2), float4(0.15758498, -0.09860034, 0.20083027, 0.11064689)), dot((h2), float4(0.25284624, -0.35015398, -0.0026045898, -0.0707055)), dot((h2), float4(-0.03834856, 0.08133997, -0.23627196, -0.18984218)), dot((h2), float4(-0.16141246, 0.05046502, 0.07382544, -0.09250848))) + (target1);
	target1 = float4(dot((i2), float4(0.05949194, 0.06522392, 0.08078033, 0.053579852)), dot((i2), float4(0.00070572464, -0.0023800225, 0.10827174, -0.11658711)), dot((i2), float4(0.10784266, -0.01614215, 0.11440369, -0.052344058)), dot((i2), float4(-0.008810496, -0.015862722, 0.014041329, -0.03857412))) + (target1);
	target1 = float4(dot((na1), float4(-0.054652497, -0.08197539, 0.03934494, -0.08371904)), dot((na1), float4(0.072690494, 0.089851685, -0.09728057, -0.02848036)), dot((na1), float4(0.11310003, 0.039466213, 0.07211633, -0.020263305)), dot((na1), float4(0.09839347, -0.059131484, 0.14545459, -0.12366355))) + (target1);
	target1 = float4(dot((nb1), float4(-0.13024135, -0.067031406, -0.048706584, 0.1541496)), dot((nb1), float4(0.10256835, -0.03591957, 0.10135636, -0.09246093)), dot((nb1), float4(-0.088607304, 0.034701034, -0.13818035, 0.11827978)), dot((nb1), float4(-0.08425782, -0.0573039, -0.09554917, -0.02703279))) + (target1);
	target1 = float4(dot((nc1), float4(-0.057035744, 0.00924603, -0.03189199, 0.2809697)), dot((nc1), float4(0.063911796, -0.03657417, -0.049402498, -0.1264563)), dot((nc1), float4(0.12805207, 0.08100167, -0.046219792, 0.02382632)), dot((nc1), float4(0.13411741, -0.031264946, 0.12624107, -0.16174819))) + (target1);
	target1 = float4(dot((nd1), float4(0.032658063, -0.20003095, -0.17617643, -0.012660543)), dot((nd1), float4(0.029207656, 0.09240136, 0.21443488, -0.038343526)), dot((nd1), float4(-0.020362824, 0.004393565, -0.06436653, -0.087761596)), dot((nd1), float4(-0.18823773, 0.28016117, 0.09426579, -0.06952474))) + (target1);
	target1 = float4(dot((ne1), float4(0.013616554, -0.0138902385, -0.12818764, 0.019264435)), dot((ne1), float4(-0.16468868, -0.04434069, 0.1970344, -0.13713486)), dot((ne1), float4(0.1281466, 0.12031286, 0.042898823, -0.027062744)), dot((ne1), float4(0.08476041, -0.07590152, 0.018936606, 0.26364017))) + (target1);
	target1 = float4(dot((nf1), float4(-0.03121837, 0.04006531, 0.0590789, -0.10438067)), dot((nf1), float4(-0.040610187, 0.089258075, -0.0127886515, 0.088400334)), dot((nf1), float4(0.0023387137, 0.038287688, 0.16618161, 0.115820415)), dot((nf1), float4(0.11021297, 0.19519399, -0.11148632, 0.23558354))) + (target1);
	target1 = float4(dot((ng1), float4(-0.14781238, -0.04531296, 0.019912932, -0.14531589)), dot((ng1), float4(-0.020881698, 0.121813886, 0.029554896, -0.20826598)), dot((ng1), float4(0.040218577, -0.12156261, -0.032324113, 0.1945815)), dot((ng1), float4(0.090248026, -0.02640371, 0.060553055, -0.18510781))) + (target1);
	target1 = float4(dot((nh1), float4(-0.24151343, -0.21133694, 0.07981589, -0.21040778)), dot((nh1), float4(0.08096261, 0.25925165, -0.06247693, -0.051243544)), dot((nh1), float4(-0.08314715, 0.037419003, -0.07793235, 0.021130228)), dot((nh1), float4(0.121899664, 0.0027491911, -0.050702088, -0.16032514))) + (target1);
	target1 = float4(dot((ni1), float4(-0.1940846, -0.01720877, 0.11248759, -0.15776572)), dot((ni1), float4(0.005878943, 0.11209827, -0.070436165, 0.041433014)), dot((ni1), float4(0.09001744, -0.045714185, 0.059041988, 0.06852976)), dot((ni1), float4(0.00996283, 0.017633213, -0.117122024, -0.32530108))) + (target1);
	target1 = float4(dot((na2), float4(-0.018681401, -0.14728728, -0.24664684, 0.031106282)), dot((na2), float4(0.07524977, 0.17958179, 0.2350485, -0.024857467)), dot((na2), float4(-0.09961975, 0.05077947, 0.043190528, 0.026871338)), dot((na2), float4(-0.025000824, 0.09839162, 0.123329654, 0.03363785))) + (target1);
	target1 = float4(dot((nb2), float4(0.090937026, 0.040868916, -0.21267591, 0.0462934)), dot((nb2), float4(0.113483965, -0.14394417, 0.079470165, 0.02001686)), dot((nb2), float4(0.10115868, 0.13920946, 0.35935298, 0.01959559)), dot((nb2), float4(0.09630846, -0.09652194, -0.029055713, 0.0067710667))) + (target1);
	target1 = float4(dot((nc2), float4(0.025194263, 0.07437093, -0.16161191, -0.01877911)), dot((nc2), float4(0.087321565, -0.024633797, -0.33736497, 0.006173125)), dot((nc2), float4(-0.008157793, -0.13163073, -0.16600001, -0.21867354)), dot((nc2), float4(-0.12381555, 0.053631987, -0.16064753, -0.11551306))) + (target1);
	target1 = float4(dot((nd2), float4(0.016227739, 0.16001828, 0.059712093, -0.112888224)), dot((nd2), float4(0.041133694, -0.07284954, 0.18617383, 0.025455667)), dot((nd2), float4(0.12241288, -0.0840258, -0.004344732, 0.06032809)), dot((nd2), float4(0.1840938, 0.10275262, 0.04759032, -0.24498977))) + (target1);
	target1 = float4(dot((ne2), float4(0.07140021, 0.07784012, 0.1719011, -0.115330435)), dot((ne2), float4(0.24720372, 0.04233614, -0.16173883, 0.2787821)), dot((ne2), float4(-0.12715518, 0.030195842, 0.082427144, -0.15274885)), dot((ne2), float4(0.13462298, -0.095302135, -0.03078554, -0.016630588))) + (target1);
	target1 = float4(dot((nf2), float4(0.08701172, 0.014872742, 0.20793833, -0.08431449)), dot((nf2), float4(0.021434337, -0.0068805423, -0.2901109, -0.05297424)), dot((nf2), float4(-0.15877618, -0.051181257, -0.057449028, -0.05526057)), dot((nf2), float4(0.22535062, -0.38192979, -0.044476006, -0.06096434))) + (target1);
	target1 = float4(dot((ng2), float4(0.12446916, -0.040306002, 0.07284438, -0.10640366)), dot((ng2), float4(-0.010789559, 0.062063884, 0.03938155, -0.11455711)), dot((ng2), float4(0.18910398, 0.14885572, 0.27486423, 0.018501248)), dot((ng2), float4(-0.14184885, 0.0050085005, -0.079940364, -0.05743762))) + (target1);
	target1 = float4(dot((nh2), float4(0.26359692, 0.09281598, 0.025533125, -0.16949633)), dot((nh2), float4(0.014875724, 0.2449208, -0.29744807, -0.097010635)), dot((nh2), float4(0.043625355, -0.07954478, 0.1810463, 0.04885873)), dot((nh2), float4(0.0974379, -0.20232148, -0.09866862, 0.08639066))) + (target1);
	target1 = float4(dot((ni2), float4(0.10937537, 0.08169718, -0.008280292, -0.16302314)), dot((ni2), float4(0.024320884, 0.038608517, -0.026776202, -0.15479733)), dot((ni2), float4(-0.084123306, 0.2250605, -0.14776887, -0.10982676)), dot((ni2), float4(0.045726787, -0.031330425, 0.3436263, 0.12014077))) + (target1);
	float4 target2 = float4( -0.031883862, -0.0151373055, -0.026020631, 0.062551804 );
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
	float4 target1 = float4( 0.046519246, -0.00879819, -0.044789877, -0.07887647 );
	float4 target2 = float4( -0.031883862, -0.0151373055, -0.026020631, 0.062551804 );
	target2 = float4(dot((a1), float4(-0.10340159, 0.06388945, 0.06422952, 0.025289888)), dot((a1), float4(0.03126175, 0.08303292, -0.029731093, 0.08642119)), dot((a1), float4(0.008010763, -0.052860666, -0.021047806, 0.06883434)), dot((a1), float4(-0.014703102, 0.1492984, 0.0012385565, 0.023763692))) + (target2);
	target2 = float4(dot((b1), float4(0.0748618, 0.077536225, -0.0054087904, 0.108363576)), dot((b1), float4(-0.048646145, -0.29863936, 0.05985848, 0.09904134)), dot((b1), float4(0.07845818, 0.24418406, -0.017639449, -0.00050070864)), dot((b1), float4(-0.24385995, 0.07232939, 0.12629768, -0.11790627))) + (target2);
	target2 = float4(dot((c1), float4(0.05239057, 0.046355467, 0.04779384, 0.12222037)), dot((c1), float4(0.15894121, -0.1368222, -0.19793929, 0.06162786)), dot((c1), float4(-0.07164557, 0.10285978, 0.06193576, 0.12215435)), dot((c1), float4(-0.32539955, 0.0981996, -0.061980426, 0.045095358))) + (target2);
	target2 = float4(dot((d1), float4(0.11633697, 0.050120354, 0.06922371, -0.040668465)), dot((d1), float4(-0.07783625, -0.039917693, 0.07441101, 0.11270888)), dot((d1), float4(0.038284954, -0.05126379, 0.04355437, -0.056610428)), dot((d1), float4(-0.1077604, 0.020723915, -0.0009652994, 0.018002095))) + (target2);
	target2 = float4(dot((e1), float4(0.1991713, 0.0118651325, -0.0597255, -0.09711957)), dot((e1), float4(-0.12291669, -0.15347931, -0.056213673, 0.19384801)), dot((e1), float4(0.007297408, -0.02881685, -0.16497411, -0.09268538)), dot((e1), float4(-0.22448927, -0.13971193, -0.087855674, 0.0010212396))) + (target2);
	target2 = float4(dot((f1), float4(0.13538352, -0.11396954, 0.07317906, -0.008961551)), dot((f1), float4(0.20081995, -0.06537804, 0.053597126, -0.030892484)), dot((f1), float4(0.05765413, 0.1840262, 0.14733106, -0.10815004)), dot((f1), float4(0.08507135, 0.13141033, -0.027857138, 0.07787356))) + (target2);
	target2 = float4(dot((g1), float4(0.14028777, 0.08193435, 0.091099024, 0.073163316)), dot((g1), float4(0.20683727, 0.06776529, -0.04523496, -0.050716147)), dot((g1), float4(-0.1973804, 0.15067616, -0.025365459, 0.03645591)), dot((g1), float4(-0.14879352, -0.005689123, 0.046144743, 0.08450625))) + (target2);
	target2 = float4(dot((h1), float4(0.05377605, -0.07375765, -0.15838358, -0.05655316)), dot((h1), float4(0.29956514, 0.07590657, -0.18164106, 0.06374977)), dot((h1), float4(-0.05203467, -0.1648796, 0.048942942, 0.03486325)), dot((h1), float4(-0.12395672, 0.016921869, 0.08723644, -0.17268877))) + (target2);
	target2 = float4(dot((i1), float4(0.067100935, 0.15253417, 0.027790325, 0.100093335)), dot((i1), float4(0.116894506, -0.043991808, -0.13292582, 0.044676002)), dot((i1), float4(-0.12316177, -0.07732363, 0.06508008, 0.1450233)), dot((i1), float4(-0.28647798, 0.12502535, 0.033653572, 0.108926095))) + (target2);
	target2 = float4(dot((a2), float4(-0.25443476, -0.009865199, 0.09569463, 0.012850613)), dot((a2), float4(0.0075249635, 0.028503535, 0.042022802, 0.08729362)), dot((a2), float4(0.09893316, 0.04932893, -0.0056093778, 0.088493116)), dot((a2), float4(0.13884877, -0.021844162, -0.044183288, -0.035626948))) + (target2);
	target2 = float4(dot((b2), float4(-0.28942817, -0.13334653, 0.070113055, 0.058714498)), dot((b2), float4(-0.2278143, -0.061389446, 0.052939575, 0.0618404)), dot((b2), float4(-0.124107786, 0.09170535, -0.027512128, 0.07549026)), dot((b2), float4(0.18914355, 0.1529043, 0.043993592, 0.27376285))) + (target2);
	target2 = float4(dot((c2), float4(-0.17169511, -0.062608786, -0.002827855, 0.05598507)), dot((c2), float4(0.18338326, -0.06097738, -0.08297087, 0.08318512)), dot((c2), float4(0.09645834, -0.052246977, 0.2045053, -0.020142859)), dot((c2), float4(-0.19721629, 0.11313908, 0.027751451, -0.07377832))) + (target2);
	target2 = float4(dot((d2), float4(0.024627045, -0.16444866, 0.05522183, 0.058282085)), dot((d2), float4(-0.065384455, -0.0068647224, -0.12074867, 0.16593929)), dot((d2), float4(-0.04648491, -0.20919928, 0.04628794, -0.1396821)), dot((d2), float4(-0.32704023, -0.18135908, 0.025948782, -0.36740735))) + (target2);
	target2 = float4(dot((e2), float4(0.16715747, 0.051240716, -0.06944291, 0.3914519)), dot((e2), float4(-0.03793736, 0.090182334, -0.05119481, -0.0677236)), dot((e2), float4(0.08576081, -0.046501555, -0.15820025, 0.076883785)), dot((e2), float4(0.23338848, -0.0894777, -0.17854515, -0.16959))) + (target2);
	target2 = float4(dot((f2), float4(-0.16410258, -0.09785154, 0.016656177, 0.001371565)), dot((f2), float4(0.11443157, 0.14995028, -0.16498508, -0.031823646)), dot((f2), float4(0.048126943, 0.093302995, -0.16739717, -0.02444281)), dot((f2), float4(0.17386216, 0.09777354, 0.11313578, 0.13747996))) + (target2);
	target2 = float4(dot((g2), float4(0.023110714, -0.007988987, -0.017114861, -0.17292719)), dot((g2), float4(-0.04154956, 0.0035799788, -0.018651277, -0.03441201)), dot((g2), float4(-0.030491728, 0.16974539, 0.00242705, 0.057909735)), dot((g2), float4(-0.4158937, -0.014700064, -0.011389802, 0.17829509))) + (target2);
	target2 = float4(dot((h2), float4(0.014969421, -0.094369836, -0.053518526, -0.017418144)), dot((h2), float4(0.21926679, 0.083293505, 0.11042086, -0.024013298)), dot((h2), float4(0.14203273, -0.080706924, 0.02499214, -0.07151083)), dot((h2), float4(-0.15120554, 0.16517772, -0.05298825, -0.22398451))) + (target2);
	target2 = float4(dot((i2), float4(0.052312143, -0.019157652, 0.05605271, -0.069604576)), dot((i2), float4(-0.09576563, -0.019879084, -0.07413262, -0.16840592)), dot((i2), float4(-0.073171586, 0.083495006, -0.09352249, 0.103903025)), dot((i2), float4(0.13949135, -0.14749153, 0.0042679785, 0.2889917))) + (target2);
	target2 = float4(dot((na1), float4(0.059331086, 0.051230803, 0.059449084, 0.024327401)), dot((na1), float4(-0.033961378, -0.018020583, -0.052372735, 0.012832041)), dot((na1), float4(0.0041064387, -0.12681223, -0.05540911, -0.022239655)), dot((na1), float4(-0.08705166, -0.23725896, 0.10343921, -0.13162766))) + (target2);
	target2 = float4(dot((nb1), float4(-0.00208763, -0.005976271, -0.075597085, -0.22840965)), dot((nb1), float4(0.06829585, 0.009429676, -0.026020885, -0.15389588)), dot((nb1), float4(-0.050976753, -0.04865572, 0.03421109, -0.111958645)), dot((nb1), float4(-0.05621949, -0.09551031, -0.1937313, 0.10905485))) + (target2);
	target2 = float4(dot((nc1), float4(0.081813, 0.08934535, 0.1303318, -0.3092255)), dot((nc1), float4(-0.065287165, 0.09954615, -0.08212296, 0.045021445)), dot((nc1), float4(-0.045189142, -0.07451004, -0.07734046, -0.1223635)), dot((nc1), float4(-0.047831066, 0.033529207, -0.014592582, -0.026269957))) + (target2);
	target2 = float4(dot((nd1), float4(-0.113570146, 0.008468439, 0.105439186, -0.121361785)), dot((nd1), float4(0.036414642, -0.029858474, 0.17247854, 0.04879374)), dot((nd1), float4(0.015502351, 0.03321966, -0.040744863, -0.23203504)), dot((nd1), float4(0.15432163, -0.14513937, -0.054444846, 0.0054753935))) + (target2);
	target2 = float4(dot((ne1), float4(-0.015762426, 0.04703402, 0.0109151825, -0.1720017)), dot((ne1), float4(0.27844664, 0.11293326, 0.051353704, -0.41253135)), dot((ne1), float4(-0.023570599, -0.22021124, 0.01387703, 0.13271171)), dot((ne1), float4(0.004403549, -0.022294452, -0.25460902, 0.24472673))) + (target2);
	target2 = float4(dot((nf1), float4(-0.06729634, -0.010024118, 0.0026236945, -0.0758896)), dot((nf1), float4(-0.08928969, 0.09617992, -0.17291804, -0.11379615)), dot((nf1), float4(0.044666067, -0.03422752, -0.18756893, 0.2614097)), dot((nf1), float4(-0.080033734, -0.24341615, -0.011092629, 0.2968493))) + (target2);
	target2 = float4(dot((ng1), float4(0.037218813, 0.07814149, 0.11074332, -0.06771369)), dot((ng1), float4(-0.08741755, -0.117306635, 0.007141896, 0.08425538)), dot((ng1), float4(-0.047161646, 0.27880162, -0.061060436, -0.13826483)), dot((ng1), float4(-0.075184174, -0.20831196, -0.07465655, 0.1951752))) + (target2);
	target2 = float4(dot((nh1), float4(-0.09369145, 0.072324485, 0.18332602, 0.0018734589)), dot((nh1), float4(0.05128452, -0.103766605, 0.24476874, -0.22071646)), dot((nh1), float4(-0.0045741517, 0.04346825, -0.23600607, 0.2122217)), dot((nh1), float4(-0.08464627, -0.084247194, -0.105699316, -0.1247409))) + (target2);
	target2 = float4(dot((ni1), float4(0.024415143, 0.06804177, 0.008934872, 0.15305461)), dot((ni1), float4(-0.1883563, 0.072834484, -0.065206386, -0.043311838)), dot((ni1), float4(-0.08757719, 0.062976, -0.02180933, -0.13565755)), dot((ni1), float4(0.038815416, -0.043060035, 0.18650985, -0.15254296))) + (target2);
	target2 = float4(dot((na2), float4(0.027255, -0.093578346, -0.01451532, -0.05686128)), dot((na2), float4(0.13145106, -0.043811, 0.20293784, -0.032981467)), dot((na2), float4(0.08066033, -0.03499714, -0.15014489, 0.009303513)), dot((na2), float4(0.05240541, 0.08510107, 0.010262514, -0.14119668))) + (target2);
	target2 = float4(dot((nb2), float4(0.056040764, -0.045012027, 0.048326198, 0.058837466)), dot((nb2), float4(0.1030456, 0.036512565, -0.08448881, 0.21072935)), dot((nb2), float4(0.19483311, -0.073540024, 0.009611186, -0.18430287)), dot((nb2), float4(-0.035117295, 0.07976307, 0.21209192, -0.022488063))) + (target2);
	target2 = float4(dot((nc2), float4(-0.047507305, -0.07350365, 0.0874119, -0.06907221)), dot((nc2), float4(-0.0024985473, -0.04659239, 0.0491421, -0.02995977)), dot((nc2), float4(0.16436942, 0.055649634, -0.20165893, -0.076965876)), dot((nc2), float4(0.11034998, -0.24239732, -0.16950199, -0.019354858))) + (target2);
	target2 = float4(dot((nd2), float4(0.16029131, 0.09299235, 0.25251085, 0.10027847)), dot((nd2), float4(0.13571973, 0.10025083, -0.06967862, -0.1572137)), dot((nd2), float4(-0.0066582616, 0.17720564, 0.09031549, 0.075934134)), dot((nd2), float4(-0.12420045, 0.09894699, 0.014147361, 0.041270934))) + (target2);
	target2 = float4(dot((ne2), float4(-0.05063072, -0.20619605, 0.28783736, -0.14137621)), dot((ne2), float4(-0.049268696, -0.3068155, -0.22305936, -0.033278886)), dot((ne2), float4(-0.018284608, 0.17608485, 0.12421118, -0.08361161)), dot((ne2), float4(-0.13692653, 0.09949, 0.22138284, -0.030769518))) + (target2);
	target2 = float4(dot((nf2), float4(0.108629055, -0.1501807, 0.0030185424, -0.015479773)), dot((nf2), float4(0.0015808924, 0.029018851, 0.23096606, 0.3498214)), dot((nf2), float4(0.20601004, 0.21033502, 0.03001235, -0.25188166)), dot((nf2), float4(-0.026752226, -0.027005566, -0.37719792, -0.09796651))) + (target2);
	target2 = float4(dot((ng2), float4(-0.17263511, -0.09580756, -0.032703403, 0.029069535)), dot((ng2), float4(0.09929037, -0.02628204, -0.04550097, 0.077399485)), dot((ng2), float4(-0.057462707, -0.18671957, -0.17387073, -0.09688172)), dot((ng2), float4(0.03969186, -0.114821374, -0.06422339, -0.04977373))) + (target2);
	target2 = float4(dot((nh2), float4(-0.08245095, -0.21334353, -0.18857501, 0.01507326)), dot((nh2), float4(0.025046779, 0.13298917, 0.16555329, 0.11679941)), dot((nh2), float4(0.15254857, 0.019746812, 0.08286123, 0.029952176)), dot((nh2), float4(-0.20083354, 0.037977856, -0.07782444, 0.20679134))) + (target2);
	target2 = float4(dot((ni2), float4(-0.08486794, -0.12877122, -0.062880024, 0.08025148)), dot((ni2), float4(0.010211643, 0.0017102316, 0.17439415, -0.06425451)), dot((ni2), float4(0.22983155, -0.079031415, 0.2649001, 0.028244738)), dot((ni2), float4(-0.16577461, -0.08309121, -0.46177015, -0.047507387))) + (target2);
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
	float3 result = float3( -0.0096404655, 0.0022038757, 0.0035988842 );
	result = float3(dot((max(a1, 0)), float4(0.012102164, -0.017435113, 0.01267727, 0.012681183)), dot((max(a1, 0)), float4(0.01385959, -0.04530735, 0.01400136, 0.035241637)), dot((max(a1, 0)), float4(0.018815203, -0.051318135, 0.017735276, 0.03990959))) + (result);
	result = float3(dot((max(b1, 0)), float4(0.16069227, 0.081593364, 0.014732323, 0.0048171813)), dot((max(b1, 0)), float4(0.098007366, 0.017831434, 0.02229113, 0.051809076)), dot((max(b1, 0)), float4(0.076831706, 0.010174303, 0.029828338, 0.055740006))) + (result);
	result = float3(dot((max(c1, 0)), float4(0.0347963, 0.003463003, 0.082851514, -0.038950548)), dot((max(c1, 0)), float4(-0.014327445, -0.050532356, 0.10950989, -0.015094648)), dot((max(c1, 0)), float4(-0.024176419, -0.06565927, 0.12022889, -0.0119305095))) + (result);
	result = float3(dot((max(d1, 0)), float4(-0.11845135, 0.00058037776, -0.0374349, 0.017439643)), dot((max(d1, 0)), float4(-0.08067485, 0.01160575, -0.052966926, 0.005496974)), dot((max(d1, 0)), float4(-0.06981454, 0.014900963, -0.044557698, -0.0024181441))) + (result);
	result = float3(dot((max(e1, 0)), float4(-0.1084345, 0.110637866, -0.19889367, -0.03789556)), dot((max(e1, 0)), float4(-0.18271221, 0.08913364, -0.17172937, -0.028977778)), dot((max(e1, 0)), float4(-0.18795776, 0.09161146, -0.1600661, -0.029903485))) + (result);
	result = float3(dot((max(f1, 0)), float4(0.017774954, 0.022389695, 0.051979035, -0.047462203)), dot((max(f1, 0)), float4(-0.048732057, -0.013317256, 0.08774837, -0.033091765)), dot((max(f1, 0)), float4(-0.061161697, -0.019972157, 0.09633588, -0.028352588))) + (result);
	result = float3(dot((max(g1, 0)), float4(0.022178177, -0.027539665, 0.0019531948, 0.024253767)), dot((max(g1, 0)), float4(0.05031684, -0.020904189, 0.00019749763, -0.00058503833)), dot((max(g1, 0)), float4(0.05802219, -0.01800042, -0.0013961957, 0.0006474611))) + (result);
	result = float3(dot((max(h1, 0)), float4(0.06707921, -0.04157211, 0.0031168605, 0.0029530525)), dot((max(h1, 0)), float4(0.0817431, -0.006174012, 0.02320992, -0.004939263)), dot((max(h1, 0)), float4(0.07561426, -0.003754037, 0.026471246, -0.0070194793))) + (result);
	result = float3(dot((max(i1, 0)), float4(0.03383418, -0.043634403, -0.050008457, -0.00016610099)), dot((max(i1, 0)), float4(0.042321067, -0.0182769, -0.003527757, 0.019936454)), dot((max(i1, 0)), float4(0.04266926, -0.011314871, 0.0035165092, 0.022199173))) + (result);
	result = float3(dot((max(a2, 0)), float4(-0.055203374, 0.027640847, -0.026225597, 0.031545334)), dot((max(a2, 0)), float4(-0.03910439, 0.019469904, 0.04481541, 0.019874612)), dot((max(a2, 0)), float4(-0.03778927, 0.0277834, 0.047454204, 0.011878432))) + (result);
	result = float3(dot((max(b2, 0)), float4(0.016088601, -0.009834776, 0.031265914, 0.039120086)), dot((max(b2, 0)), float4(-0.045959134, 0.0077799167, 0.09698676, 0.0005542848)), dot((max(b2, 0)), float4(-0.048793618, 0.00873151, 0.10005417, -0.0049420255))) + (result);
	result = float3(dot((max(c2, 0)), float4(0.028432969, -0.00586326, -0.013559131, -0.09087544)), dot((max(c2, 0)), float4(-0.014792921, 0.013427183, 0.017704675, -0.104627624)), dot((max(c2, 0)), float4(-0.026881924, 0.018215714, 0.024854776, -0.0921747))) + (result);
	result = float3(dot((max(d2, 0)), float4(-0.022899037, -0.008008749, -0.02490554, 0.031494617)), dot((max(d2, 0)), float4(0.026374351, -0.0013132087, 0.0020362549, 0.049864545)), dot((max(d2, 0)), float4(0.03145993, -0.003957525, 0.006453752, 0.04702567))) + (result);
	result = float3(dot((max(e2, 0)), float4(-0.12318068, -0.1321696, -0.072339885, 0.10844834)), dot((max(e2, 0)), float4(-0.121377476, -0.078085914, 0.0012095685, 0.10038668)), dot((max(e2, 0)), float4(-0.11615006, -0.07868927, 0.010923645, 0.09919817))) + (result);
	result = float3(dot((max(f2, 0)), float4(0.058991943, -0.041878223, -0.010507848, -0.1193022)), dot((max(f2, 0)), float4(0.018824834, 0.013176531, 0.02042605, -0.10676289)), dot((max(f2, 0)), float4(0.01659209, 0.023566704, 0.028884022, -0.096668206))) + (result);
	result = float3(dot((max(g2, 0)), float4(0.023510003, 0.02304783, -0.01060811, -0.022243036)), dot((max(g2, 0)), float4(0.06057355, 0.031745855, -0.043136407, 0.014206766)), dot((max(g2, 0)), float4(0.052194174, 0.025863871, -0.03569961, 0.0032128936))) + (result);
	result = float3(dot((max(h2, 0)), float4(0.025120225, -0.020202598, -0.043466344, 0.006438127)), dot((max(h2, 0)), float4(0.07386707, 0.010854587, -0.049230598, 0.041072655)), dot((max(h2, 0)), float4(0.07916389, 0.009825397, -0.038344223, 0.036958262))) + (result);
	result = float3(dot((max(i2, 0)), float4(0.027640026, -0.002110394, -0.020238828, -0.029621653)), dot((max(i2, 0)), float4(0.04239058, 0.040088017, -0.01711292, -0.007380026)), dot((max(i2, 0)), float4(0.055017423, 0.045239322, -0.014726791, -0.002073584))) + (result);
	result = float3(dot((max(-a1, 0)), float4(0.008071638, 0.044838928, 0.0006324625, 0.043963037)), dot((max(-a1, 0)), float4(0.0034274645, 0.06936641, -0.02223834, 0.047561962)), dot((max(-a1, 0)), float4(-0.0016181463, 0.072150804, -0.021122342, 0.026419055))) + (result);
	result = float3(dot((max(-b1, 0)), float4(-0.06605246, -0.09256232, 0.032296494, 0.05214882)), dot((max(-b1, 0)), float4(-0.011649812, -0.06281528, -0.011113339, 0.022887057)), dot((max(-b1, 0)), float4(-0.0022502556, -0.055003755, -0.015790787, 0.013746634))) + (result);
	result = float3(dot((max(-c1, 0)), float4(-0.03587372, 0.008917248, 0.01872278, 0.030770298)), dot((max(-c1, 0)), float4(0.018986767, 0.050303612, -0.011048741, 0.0063107815)), dot((max(-c1, 0)), float4(0.03229596, 0.06147115, -0.017369485, 0.003187433))) + (result);
	result = float3(dot((max(-d1, 0)), float4(0.087662674, 0.0043635606, -0.023863237, 0.06292237)), dot((max(-d1, 0)), float4(0.048391398, 0.02438183, -0.0051179314, 0.05821987)), dot((max(-d1, 0)), float4(0.042332277, 0.020213395, -0.0060627074, 0.051667042))) + (result);
	result = float3(dot((max(-e1, 0)), float4(-0.048478693, -0.19261299, 0.112302095, 0.024626324)), dot((max(-e1, 0)), float4(0.008368922, -0.1848583, 0.061518673, 0.0058449907)), dot((max(-e1, 0)), float4(0.016874269, -0.18258469, 0.058282077, 0.006936535))) + (result);
	result = float3(dot((max(-f1, 0)), float4(-0.04468695, 0.05447911, -0.0007933787, -0.028044306)), dot((max(-f1, 0)), float4(0.0099176075, 0.08220857, -0.03090106, -0.050590593)), dot((max(-f1, 0)), float4(0.025094027, 0.08161316, -0.040217776, -0.05027328))) + (result);
	result = float3(dot((max(-g1, 0)), float4(0.029733973, 0.01860655, -0.023667783, -0.01960303)), dot((max(-g1, 0)), float4(-0.0129855955, 0.017793713, -0.0013290358, -0.012806444)), dot((max(-g1, 0)), float4(-0.019776886, 0.020113358, -0.004159268, -0.016549494))) + (result);
	result = float3(dot((max(-h1, 0)), float4(-0.00952229, 0.04292393, -0.016540393, -0.06652295)), dot((max(-h1, 0)), float4(-0.007181503, 0.01510459, -0.023619318, -0.06933143)), dot((max(-h1, 0)), float4(-0.0061082463, 0.0062862537, -0.02633423, -0.063913494))) + (result);
	result = float3(dot((max(-i1, 0)), float4(-0.015281855, 0.045862548, 0.032412887, -0.027728679)), dot((max(-i1, 0)), float4(-0.012470513, 0.023707546, -0.0038218168, -0.04009727)), dot((max(-i1, 0)), float4(-0.008184894, 0.014719574, -0.0065955487, -0.018856067))) + (result);
	result = float3(dot((max(-a2, 0)), float4(0.042844415, -0.031152235, 0.005666899, -0.0007617308)), dot((max(-a2, 0)), float4(0.00673587, -0.06649269, -0.015819343, 0.021531299)), dot((max(-a2, 0)), float4(0.0038338478, -0.065986395, -0.012795757, 0.026071105))) + (result);
	result = float3(dot((max(-b2, 0)), float4(-0.118266046, 0.02361942, 0.077196896, -0.03160996)), dot((max(-b2, 0)), float4(-0.07211513, 0.012819485, 0.003424893, -0.0034473129)), dot((max(-b2, 0)), float4(-0.058381762, 0.010511434, 0.001927401, -0.00444674))) + (result);
	result = float3(dot((max(-c2, 0)), float4(-0.06548674, -0.006173449, 0.021622533, -0.011835129)), dot((max(-c2, 0)), float4(-0.018152835, 0.008357867, -0.03722321, 0.0109178)), dot((max(-c2, 0)), float4(0.0034779215, -0.0033986098, -0.045832597, 0.010480887))) + (result);
	result = float3(dot((max(-d2, 0)), float4(0.041682176, -0.054624356, -0.0060466817, -0.015683241)), dot((max(-d2, 0)), float4(-0.008985459, -0.09495616, -0.017551763, -0.012590141)), dot((max(-d2, 0)), float4(-0.018538723, -0.090484254, -0.014151624, -0.014278323))) + (result);
	result = float3(dot((max(-e2, 0)), float4(0.073194094, 0.18175459, 0.14047755, 0.0068531767)), dot((max(-e2, 0)), float4(0.055347454, 0.13776664, 0.061971992, -0.011873265)), dot((max(-e2, 0)), float4(0.060976587, 0.13139476, 0.056503728, -0.016871026))) + (result);
	result = float3(dot((max(-f2, 0)), float4(-0.041848205, 0.044274334, 0.009403278, 0.04548978)), dot((max(-f2, 0)), float4(-0.009582, 0.04011985, -0.03346772, 0.014613167)), dot((max(-f2, 0)), float4(-0.0076929387, 0.03085897, -0.04463548, 0.0055232802))) + (result);
	result = float3(dot((max(-g2, 0)), float4(0.019901669, -0.053240675, -0.01892976, 0.01228504)), dot((max(-g2, 0)), float4(-0.0011372451, -0.07105105, -0.019795185, -0.005040437)), dot((max(-g2, 0)), float4(-0.007423424, -0.07122227, -0.019204788, -0.0010069044))) + (result);
	result = float3(dot((max(-h2, 0)), float4(0.032843515, -0.0006476342, -0.015617971, 0.037908908)), dot((max(-h2, 0)), float4(0.014947385, -0.020907652, -0.029182931, -0.018132487)), dot((max(-h2, 0)), float4(0.007550199, -0.030297596, -0.038677275, -0.020226713))) + (result);
	result = float3(dot((max(-i2, 0)), float4(0.03232915, 0.016676396, 0.0076904814, 0.03459369)), dot((max(-i2, 0)), float4(0.02915194, 0.004807404, 0.00541351, -0.012969539)), dot((max(-i2, 0)), float4(0.014929652, -0.0008906752, -0.0048240838, -0.024712864))) + (result);
	result += tex2Dlod(SampInput, float4(pos, 0, 0)).rgb;
	Out9 = float4(result, 1.0);
}

technique Anime4K_Restore_L
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
