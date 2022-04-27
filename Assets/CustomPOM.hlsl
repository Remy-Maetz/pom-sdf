void CustomPOM_float(
	Texture2D heightmap, SamplerState heightmapSS, float amplitude, float2 uvs, float3 viewDirWS, float3 normalWS, float3 tangentWS, float3 biTangentWS, float viewZScale, int maxSteps, bool useSDF,
	out float2 parallaxUVs, out float steps, out float4 debugVector
)
{
	maxSteps = min(maxSteps, 256);

	viewDirWS = normalize(viewDirWS);
	viewDirWS /= viewZScale;
	normalWS = normalize(normalWS);
	tangentWS = normalize(tangentWS);
	biTangentWS = normalize(biTangentWS);

	float viewDirN = dot(viewDirWS, -normalWS);
	float viewDirT = dot(viewDirWS, tangentWS);
	float viewDirB = dot(viewDirWS, biTangentWS);

	float origSDF = heightmap.Sample(heightmapSS, uvs).g;
	float origDistance = origSDF * amplitude;

	parallaxUVs = uvs;
	steps = 0;
	debugVector = float4(0, 0, 0, 0);

	float scale = amplitude/ viewDirN;
	scale /= maxSteps;

	float2 uvStep = float2(viewDirT, viewDirB);
	uvStep *= scale;
	float hStep = 1.0 / maxSteps;
	float h = 0;

	float traveledDistance = 0;

	if (useSDF)
	{
		parallaxUVs = uvs + float2(viewDirT, viewDirB) * origDistance;
		h += origSDF * abs(viewDirN);
		traveledDistance += origDistance;
		/*
		float amplitudeDiff = amplitude - origDistance;
		scale = amplitudeDiff / viewDirN;
		scale /= maxSteps;
		uvStep = float2(viewDirT, viewDirB) * scale;
		hStep = (1.0 - origSDF) / maxSteps;
		*/
	}

	[loop]
	for (int i = 0; i < maxSteps; i++)
	{
		float t = 1.0 - heightmap.Sample(heightmapSS, parallaxUVs).r;

		if (h >= t)
		{
			float s = (h - t) / hStep;
			//parallaxUVs -= uvStep * s;
			//debugVector.rgb = s;
			break;
		}

		h += hStep;
		parallaxUVs += uvStep;
		traveledDistance += scale;
		steps++;
	}

	debugVector.rgb = traveledDistance - origDistance;
}