#ifndef TOON_UNLIT_PASS_INCLUDED
#define TOON_UNLIT_PASS_INCLUDED

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    float2 uv2 : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    float3 normalWS : TEXCOORD2;
    float3 viewDirWS : TEXCOORD7;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData = (InputData)0;

    inputData.positionWS = input.positionWS;

    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);

    inputData.normalWS = input.normalWS;
    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);

    inputData.viewDirectionWS = viewDirWS;

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
}

Varyings ToonUnlitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.positionCS = vertexInput.positionCS;
    output.positionWS = vertexInput.positionWS;


    output.uv.xy = TRANSFORM_TEX(input.uv, _MainTex);

    output.normalWS = normalInput.normalWS;

    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
    output.viewDirWS = viewDirWS;

    return output;
}

void ToonUnlitPassFragment(Varyings input, out float4 outColor: SV_Target0)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    ToonSurfaceData surfaceData;
    InitializeToonMapSurfaceData(input.uv.xy, surfaceData);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    PreProcessMaterial(inputData, surfaceData, input.uv.xy);

    float4 color = float4(surfaceData.albedo, surfaceData.alpha);

    outColor = color;
}

#endif
