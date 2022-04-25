void CustomPOM_float(
	Texture2D heightmap, SamplerState heightmapSS, float amplitude, float2 uvs, float3 viewDirWS, float3 normalWS, float3 tangentWS, float3 biTangentWS, float viewZScale, int maxSteps,
	out float2 parallaxUVs, out float steps, out float4 debugVector
)
{
	maxSteps = min(maxSteps, 256);

	parallaxUVs = uvs;
	steps = 0;
	debugVector = float4(0, 0, 0, 0);

	viewDirWS = normalize(viewDirWS);
	viewDirWS /= viewZScale;
	normalWS = normalize(normalWS);
	tangentWS = normalize(tangentWS);
	biTangentWS = normalize(biTangentWS);

	steps = 0;

	float viewDirN = dot(viewDirWS, -normalWS);
	float viewDirT = dot(viewDirWS, tangentWS);
	float viewDirB = dot(viewDirWS, biTangentWS);

	float scale = amplitude/ viewDirN;
	scale /= maxSteps;

	float2 uvStep = float2(viewDirT, viewDirB);
	uvStep *= scale;
	float hStep = 1.0 / maxSteps;
	float h = 0;

	debugVector.rgb = scale;

	[loop]
	for (int i = 0; i < maxSteps; i++)
	{
		float t = 1.0 - heightmap.Sample(heightmapSS, parallaxUVs).r;

		if (h > t)
		{
			float s = (h - t) / hStep;
			//parallaxUVs -= uvStep * s;
			debugVector.rgb = s;
			break;
		}

		h += hStep;
		parallaxUVs += uvStep;
		steps++;
	}
}