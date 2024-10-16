Shader "ToonURP/Grass"
{
    Properties
    {
        [Header(Shading)]
        _TopColor("Top Color", Color) = (1,1,1,1)
        _BottomColor("Bottom Color", Color) = (1,1,1,1)
        _TranslucentGain("Translucent Gain", Range(0,1)) = 0.5
        [Header(Shape)]
        _BendRotationRandom("Bend Rotation Random", Range(0,1)) = 0.2
        _BladeWidth("Blade Width", Float) = 5
        _BladeWidthRandom("Blade Width Random", Float) = 0.02
        _BladeHeight("Blade Height", Float) = 10
        _BladeHeightRandom("Blade Height Random", Float) = 0.3
        _TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1

        _BladeForward("Blade Forward Amount", Float) = 0.38
        _BladeCurve("Blade Curvature Amount", Range(1,4)) = 2
        [Header(Wind)]
        _WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
        _WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
        _WindStrength("Wind Strength", Float) = 0.1

    }

    HLSLINCLUDE
    #include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonLighting.hlsl"

    #define BLADE_SEGMENTS 3

    // Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
    // Extended discussion on this function can be found at the following link:
    // https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
    // Returns a number in the 0...1 range.
    float rand(float3 co)
    {
        return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
    }

    // Construct a rotation matrix that rotates around the provided axis, sourced from:
    // https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
    float3x3 AngleAxis3x3(float angle, float3 axis)
    {
        float c, s;
        sincos(angle, s, c);

        float t = 1 - c;
        float x = axis.x;
        float y = axis.y;
        float z = axis.z;

        return float3x3(
            t * x * x + c, t * x * y - s * z, t * x * z + s * y,
            t * x * y + s * z, t * y * y + c, t * y * z - s * x,
            t * x * z - s * y, t * y * z + s * x, t * z * z + c
        );
    }

    float4 _TopColor;
    float4 _BottomColor;
    float _TranslucentGain;

    float _BendRotationRandom;
    float _BladeWidth;
    float _BladeWidthRandom;
    float _BladeHeight;
    float _BladeHeightRandom;

    float _BladeForward;
    float _BladeCurve;

    sampler2D _WindDistortionMap;
    float4 _WindDistortionMap_ST;
    float2 _WindFrequency;
    float _WindStrength;

    struct vertexInput
    {
        float4 vertex: POSITION;
        float3 normal: NORMAL;
        float4 tangent: TANGENT;
    };

    struct TessellationFactors
    {
        float edge[3] : SV_TessFactor;
        float inside : SV_InsideTessFactor;
    };

    struct vertexOutput
    {
        float4 vertex: SV_POSITION;
        float3 normal: NORMAL;
        float4 tangent: TANGENT;
    };

    struct geometryOutput
    {
        float4 posCS: SV_POSITION;
        float3 posWS: TEXCOORD0;
        float3 normalWS: TEXCOORD1;
        float2 uv: TEXCOORD2;
        float4 shadowCoord: TEXCOORD3;
    };

    vertexOutput vert(vertexInput v)
    {
        vertexOutput o;
        o.vertex = v.vertex;
        o.normal = v.normal;
        o.tangent = v.tangent;
        return (o);
    }

    vertexOutput tessVert(vertexInput v)
    {
        vertexOutput o;
        o.vertex = v.vertex;
        o.normal = v.normal;
        o.tangent = v.tangent;
        return o;
    }

    float _TessellationUniform;

    TessellationFactors patchConstantFunction(InputPatch<vertexInput, 3> patch)
    {
        TessellationFactors f;
        f.edge[0] = _TessellationUniform;
        f.edge[1] = _TessellationUniform;
        f.edge[2] = _TessellationUniform;
        f.inside = _TessellationUniform;
        return f;
    }

    [domain("tri")]
    [outputcontrolpoints(3)]
    [outputtopology("triangle_cw")]
    [partitioning("integer")]
    [patchconstantfunc("patchConstantFunction")]
    vertexInput hull(InputPatch<vertexInput, 3> patch, uint id : SV_OutputControlPointID)
    {
        return patch[id];
    }

    [domain("tri")]
    vertexOutput domain(TessellationFactors factors, OutputPatch<vertexInput, 3> patch,
                                           float3 barycentricCoordinates : SV_DomainLocation)
    {
        vertexInput v;

        #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
			patch[0].fieldName * barycentricCoordinates.x + \
			patch[1].fieldName * barycentricCoordinates.y + \
			patch[2].fieldName * barycentricCoordinates.z;

            MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
            MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
            MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)

        return tessVert(v);
    }

    geometryOutput geoOutputGenerate(float3 pos, float2 uv, float3 normal)
    {
        geometryOutput o;
        o.posCS = TransformObjectToHClip(pos);
        o.posWS = TransformObjectToWorld(pos);
        o.normalWS = TransformObjectToWorldNormal(normal);
        o.uv = uv;
        o.shadowCoord = TransformWorldToShadowCoord(o.posWS);
        return o;
    }

    geometryOutput GenerateGrassVertex(float3 pos, float width, float height, float forward, float2 uv,
         float3x3 transforMatrix)
    {
        float3 tangentPoint = float3(width, forward, height);
        float3 tangentNormal = float3(0, -1, forward);
        float3 localNormal = mul(transforMatrix, tangentNormal);
        float3 localPosition = pos + mul(transforMatrix, tangentPoint);
        return geoOutputGenerate(localPosition, uv, localNormal);
    }


    [maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
    void geo(triangle vertexOutput IN[3]: SV_POSITION, inout TriangleStream<geometryOutput> triStream)
    {
        geometryOutput o;
        float3 pos = IN[0].vertex;

        float3 vNormal = IN[0].normal;
        float4 vTangent = IN[0].tangent;
        float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;

        float3x3 tangentToLocal = float3x3(
            vTangent.x, vBinormal.x, vNormal.x,
            vTangent.y, vBinormal.y, vNormal.y,
            vTangent.z, vBinormal.z, vNormal.z
        );

        float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * 2 * PI, float3(0, 0, 1));

        float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos) * _BendRotationRandom * PI * 0.5, float3(-1, 0, 0));
        float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
        float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;
        float3 wind = normalize(float3(windSample.x, windSample.y, 0));
        float3x3 windRotation = AngleAxis3x3(PI * windSample, wind);

        float3x3 transformationMatrix = mul(mul(mul(tangentToLocal, windRotation), facingRotationMatrix),
                                 bendRotationMatrix);
        float3x3 transformationMatrixFacing = mul(tangentToLocal, facingRotationMatrix);
        // to ensure that the grass are pinned to the ground.


        float height = (rand(pos.xxy) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
        float width = (rand(pos.yyz) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
        float forward = rand(pos.zzx) * _BladeForward;

        for (int i = 0; i < BLADE_SEGMENTS; i++)
        {
            float t = i / (float)BLADE_SEGMENTS;
            float segmentWidth = width * (1 - t);
            float segmentHeight = height * t;
            float segmentForward = pow(t, _BladeCurve) * forward;

            float3x3 transformMatrix = i == 0 ? transformationMatrixFacing : transformationMatrix;
            triStream.Append(GenerateGrassVertex(pos, segmentWidth, segmentHeight, segmentForward, float2(0, t),
                                                 transformMatrix));
            triStream.Append(GenerateGrassVertex(pos, -segmentWidth, segmentHeight, segmentForward, float2(1, t),
                                                 transformMatrix));
        }
        triStream.Append(GenerateGrassVertex(pos, 0, height, forward, float2(0.5, 1), transformationMatrix));
    }
    ENDHLSL

    SubShader
    {
        Cull Off

        Pass
        {
            Tags
            {
                "RenderType" = "Opaque"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geo
            #pragma hull hull
            #pragma domain domain
            #pragma target 4.6
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT


            float4 frag(geometryOutput input, float facing : VFACE) : SV_Target
            {
                float3 normal = facing > 0 ? input.normalWS : -input.normalWS;

                float4 shadowCoord = TransformWorldToShadowCoord(input.posWS);
                float shadow = MainLightRealtimeShadow(shadowCoord);

                Light mainLight = GetMainLight();
                half3 lightColor = mainLight.color;
                float3 lightDir = mainLight.direction.xyz;
                float lightNoL = saturate(saturate(dot(normal, lightDir)) + _TranslucentGain) * shadow;
                float4 lightIntensity = lightNoL * float4(lightColor, 1.0);

                float4 color = lerp(_BottomColor * float4(lightColor, 1.0), _TopColor * lightIntensity, input.uv.y);
                return color;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geo
            #pragma hull hull
            #pragma domain domain
            #pragma target 4.6
            #pragma multi_compile_shadowcaster

            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"


            float4 UnityEncodeCubeShadowDepth(float z)
            {
                #ifdef UNITY_USE_RGBA_FOR_POINT_SHADOWS
				return EncodeFloatRGBA (min(z, 0.999));
                #else
                return z;
                #endif
            }

            float4 frag(geometryOutput i): SV_Target
            {
                float3 vec;
                vec = TransformObjectToWorld(i.posCS).xyz - _MainLightPosition.xyz;

                return UnityEncodeCubeShadowDepth((length(vec) + _ShadowBias.x) * _MainLightPosition.w);
            }
            ENDHLSL
        }
    }
}