Shader "ToonURP/GenshinWater"
{
    Properties
    {
        [Header(shading)]
        _DepthMaxDistance("Depth Max Distance", Float) = 1
        _DepthGradientShore("Depth Gradient Shore", Float) = 0.2

        _SkyboxTexture ("Skybox Texture", Cube) = "_Skybox" {}
        _SurfaceNoise("Surface Noise", 2D) = "white" {}

        _WaveDensity("Wave Density", Float) = 0.03
        _WaveHeight("Wave Height", Float) = 0.5
        _WaveSpeed("Wave Speed", Vector) = (1,1,1,1)
        _NormalScale("Normal Scale", Float) = 1
        _NormalStrength("Normal Strength", Float) = 1

        [Header(lighting)]
        _Smoothness("Smoothness", Range(1,0)) = 1
        _specularColor("Specular Color", Color) = (1,1,1,1)
        _fresnelPow("fresnel Pow",Range(0.1,20)) = 5
        _SpecularAtten("Specular Attenuation", Float) = 1
        _Gloss("Gloss", Float) = 100

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        // ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma target 4.6
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _SHADOWS_SOFT
            #define UNITY_PI 3.14159265

            #include "Packages/com.reubensun.toonurp/ShaderLibrary/ToonLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent: TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 posCS : SV_POSITION;
                float3 posWS : TEXCOORD0;
                float3 viewNormal : NORMAL;
                float2 uv : TEXCOORD1;
                float4 screenPosition: TEXCOORD2;
                float3 worldNormal: TEXCOORD3;
                float4 bumpUV1: TEXCOORD4;
                float3 tangentWS:TEXCOORD5;
                float3 bitangentDir:TEXCOORD6;
            };
            
            SAMPLER(sampler_linear_clamp);

            float _DepthMaxDistance;
            float4 _DepthGradientShallow;
            float4 _DepthGradientDeep;
            float _DepthGradientShore;

            samplerCUBE _SkyboxTexture;
            sampler2D _SurfaceNoise;

            float _WaveDensity;
            float _WaveHeight;
            float4 _WaveSpeed;
            float _NormalScale;
            float _NormalStrength;
            
            float _Smoothness;
            float4 _specularColor;
            float _fresnelPow;
            float _SpecularAtten;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.posCS = TransformObjectToHClip(v.vertex);
                o.posWS = TransformObjectToWorld(v.vertex);
                o.uv = v.uv;
                o.viewNormal = mul(UNITY_MATRIX_IT_MV, v.normal);
                o.screenPosition = ComputeScreenPos(o.posCS);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);

                o.bumpUV1.xy = v.uv + float2(_SinTime.x * _WaveSpeed.x, _SinTime.x * _WaveSpeed.y);
                o.bumpUV1.zw = v.uv + float2(_CosTime.y * 1.2 * _WaveSpeed.z, _SinTime.y*0.5* _WaveSpeed.w);
                o.tangentWS = TransformObjectToWorldDir(v.tangent.xyz);

                o.bitangentDir = normalize(cross(o.worldNormal, o.tangentWS) * v.tangent.w);
                return o;
            }

            float SampleSceneDepth(float2 uv, TEXTURE2D_X_FLOAT(_Texture), SAMPLER(sampler_Texture))
            {
                return SAMPLE_TEXTURE2D_X(_Texture, sampler_Texture, UnityStereoTransformScreenSpaceTex(uv)).r;
            }

            float SampleSceneNormals(float2 uv, TEXTURE2D_X_FLOAT(_Texture), SAMPLER(sampler_Texture))
            {
                return SAMPLE_TEXTURE2D_X(_Texture, sampler_Texture, UnityStereoTransformScreenSpaceTex(uv)).r;
            }

            float4 afterBlend(float4 waterColor, float waterDepth) {
                float3 color = waterColor.rgb;
                float alpha = waterColor.a * waterDepth;
                return float4(color, alpha);
            }

            float4 cosine_gradient(float x,  float4 phase, float4 amp, float4 freq, float4 offset) 
            {
                const float TAU = 2. * 3.14159265;
                phase *= TAU;
                x *= TAU;
              
                return float4(
                  offset.r + amp.r * 0.5 * cos(x * freq.r + phase.r) + 0.5,
                  offset.g + amp.g * 0.5 * cos(x * freq.g + phase.g) + 0.5,
                  offset.b + amp.b * 0.5 * cos(x * freq.b + phase.b) + 0.5,
                  offset.a + amp.a * 0.5 * cos(x * freq.a + phase.a) + 0.5
                );
            }

            float3 toRGB(float4 grad){
                return grad.rgb;
            }

            float2 rand(float2 st, int seed)
			{
				float2 s = float2(dot(st, float2(127.1, 311.7)) + seed, dot(st, float2(269.5, 183.3)) + seed);
				return -1 + 2 * frac(sin(s) * 43758.5453123);
			}

            half BRDF_DTerm(float NdotH, float i_roughness) {
                //DGGX =  a^2 / π((a^2 – 1) (n · h)^2 + 1)^2
                float a2 = i_roughness * i_roughness;
                float val = ((a2 - 1) * (NdotH * NdotH) + 1);
                return a2 / (UNITY_PI * (val * val));
            }
            half BRDF_GTerm(float NdotL, float NdotV, float i_roughness) {
                //G(l,v,h)=1/(((n·l)(1-k)+k)*((n·v)(1-k)+k))
                float k = i_roughness * i_roughness / 2;
                return 0.5 / ((NdotL * (1 - k) + k) + (NdotV * (1 - k) + k));
            }

            float BRDF_FresnelTerm(float F0, float NdotV) {
                //F(l,h) = F0+(1-F0)(1-l·h)^5
                return F0 + (1 - F0) * pow(1 - NdotV, 5);
            }
            half3 custom_FresnelLerp(half3 F0, half3 F90, half cosA)
            {
                half t = pow(1 - cosA, _fresnelPow);   // ala Schlick interpoliation
                return lerp(F0, F90, t);
            }

            float4 frag (v2f i) : SV_Target
            {
                // color variation
                const float4 phases = float4(0.28, 0.50, 0.07, 0.);
				const float4 amplitudes = float4(4.02, 0.34, 0.65, 0.);
				const float4 frequencies = float4(0.00, 0.48, 0.08, 0.);
				const float4 offsets = float4(0.00, 0.16, 0.00, 0.);

                // calculate the color through depth of shadowmap
                float2 uv = i.screenPosition.xy / i.screenPosition.w;
                float shadowMapDepth = SampleSceneDepth(uv, _CameraDepthTexture, sampler_linear_clamp); 
                float existingDepthLinear = LinearEyeDepth(shadowMapDepth, _ZBufferParams);
                // calculate scene normals
                float3 existingNormal = SampleSceneNormals(uv, _CameraNormalsTexture, sampler_linear_clamp);
                float3 normalDot = saturate(dot(existingNormal, i.viewNormal));

                float depthDifference = existingDepthLinear - i.screenPosition.w;
                float waterDepthDifference = saturate(depthDifference / _DepthMaxDistance);

                // calculate water color
                float4 cos_grad = cosine_gradient(1 - waterDepthDifference, phases, amplitudes, frequencies, offsets);
                cos_grad = saturate(cos_grad);
                float4 waterColor = float4(toRGB(cos_grad), 1.0);

                float shoreDepth = saturate(depthDifference / _DepthGradientShore);
                waterColor = afterBlend(waterColor, shoreDepth);

                float3 viewDirWorld = normalize(_WorldSpaceCameraPos - i.posWS);

                float4 bump10 = (tex2D(_SurfaceNoise, i.bumpUV1.xy / _NormalScale)*2 + tex2D(_SurfaceNoise, i.bumpUV1.zw / _NormalScale)*2) -2;
                float3 offset = normalize(bump10 / 2);
                offset.xy *= _NormalStrength;
                float3 bump = normalize(offset);
                float3x3 tangentTransform = float3x3(i.tangentWS, i.bitangentDir, normalize(i.worldNormal));
                float3 bumpWorld = normalize(mul(bump, tangentTransform));

                float3 swelledNormal = normalize(bumpWorld);
                //sample skybox
                float3 reflDir = reflect(viewDirWorld, swelledNormal);
                reflDir.xyz *= -1;
                float4 skyColor = texCUBE(_SkyboxTexture, normalize(reflDir));

                // PBR lighting
                float4 SHADOW_COORDS = TransformWorldToShadowCoord(i.posWS);
                Light mainLight = GetMainLight(SHADOW_COORDS);
				half3 lightColor = mainLight.color;
				float3 lightDir = normalize(mainLight.direction.xyz);

                float NdotL = saturate(dot(swelledNormal, -lightDir));
                float NdotV = abs(saturate(dot(swelledNormal, viewDirWorld)));
                float3 halfDir = normalize(lightDir + viewDirWorld);
                float NdotH = saturate(dot(swelledNormal, halfDir));
                float LdotH = saturate(dot(-lightDir, halfDir));
                float VdotH = saturate(dot(-viewDirWorld, halfDir));

                float roughness = 1.0 - _Smoothness;
                roughness = max(roughness, 0.002);
                float roughness2 = roughness * roughness;
                // 目前只加菲涅尔项，后续再添加pbr其他项
                float dTerm = BRDF_DTerm(NdotH, roughness2);
                float gTerm = BRDF_GTerm(NdotL, NdotV, roughness2);
                
                float fTerm = saturate(BRDF_FresnelTerm(0.02 /*F0*/ , NdotV)* _fresnelPow);
                float specular = _specularColor.rgb * _SpecularAtten * pow(NdotH, _Gloss);
            
                float4 col = lerp(waterColor + specular, skyColor, fTerm);
                // float4 col = float4(specular,specular,specular,1);
                return col;
            }
            ENDHLSL
        }
    }
}
