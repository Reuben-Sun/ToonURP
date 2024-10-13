# ToonURP（刚刚开始）

## Unity版本

 - Unity 2022.3
 - URP14

## 安装使用

在Unity项目的Packages文件夹下运行

```
git clone https://github.com/Reuben-Sun/ToonURP.git
```

并拉新submodule

```
cd ToonURP
git submodule update --init --recursive
```

替换Render Pipeline Assets，使用Setting文件夹下的URP-HighFidelity.asset

![替换资产](Documentation~/image/replace_assets.png)

## 开发计划

- [ ] 基础卡通材质
  - [x] 二值CellShading
  - [x] 多光源
  - [x] 色散
  - [x] SRP batcher
- [x] 边缘检测描边 
- [ ] 人物
  - [ ] 眼睛
  - [ ] 头发
  - [ ] 黑丝
  - [x] 脸
    - [x] SDF阴影
- [ ] 卡通面片草
  - [x] 几何着色器草
  - [ ] HiZ剔除+Instance
  
- [x] 卡通石头
  - [x] 顶部覆盖植被
- [ ] 卡通水
  - [x] 深度采样颜色渐变与法线扰动波纹
  - [ ] 焦散
  - [ ] 反射水面物体
  - [ ] 近海水花
  - [ ] 物体交互
- [ ] 卡通树

## Shader 设计

> 可以参考ToonUnlit.shader的实现

每次当我写shader时，都会想一些问题：

 - 我为什么要写 LitInput.hlsl？
 - 我为什么要反复写 vertex 函数？
 - 我能不能只定义一个`.shader`文件，就能使用URP中各种功能？

### 新增材质

> 参考 ToonRock.shader

### 新增 ShadingMode

> 参考 ToonWetPlane.shader

你想基于ToonStandard.shader新增一个材质Shader，首先要在`_EnumShadingMode`添加新的模式，并将默认值指向你新增的模式

```hlsl
[Main(ShadingMode, _, off, off)] _ShadingModeGroup("ShadingMode", float) = 0
[KWEnum(ShadingMode, CelShading, _CELLSHADING, PBRShading, _PBRSHADING)] _EnumShadingMode ("Mode", float) = 0
```

```hlsl
[Main(ShadingMode, _, off, off)] _ShadingModeGroup("ShadingMode", float) = 0
[KWEnum(ShadingMode, CelShading, _CELLSHADING, PBRShading, _PBRSHADING, WetPlane, _CUSTOMSHADING)] _EnumShadingMode ("Mode", float) = 2
```

并在宏中添加你的模式，注意新模式的宏名称必须为`_CUSTOMSHADING`
```hlsl
#pragma shader_feature_local _CELLSHADING _PBRSHADING
```

```hlsl
#pragma shader_feature_local _CELLSHADING _PBRSHADING _CUSTOMSHADING
```

除了编写`PreProcessMaterial`外，你需要额外定义一个`CustomFragment`函数，当你的模式为`_CUSTOMSHADING`时，会调用这个函数

```hlsl
float4 CustomFragment(InputData inputData, ToonSurfaceData toonSurfaceData, float4 uv){}
```

#### 维持 SRP Batcher

> 有没有办法优化这部分？

为了维持SRP batcher，你需要管理`CBUFFER_START(UnityPerMaterial)`内的信息

有时（尤其是增加一个LightingMode时，比如SDF）你需要在ToonStandardInput.hlsl的`CBUFFER_START(UnityPerMaterial)`中添加一些参数，放心添加吧，你定义了不用也不会有太大的损失

你可以在FrameDebugger中验证你是否维持了其他材质是否维持了SRP batcher

## 参考 

[FernRP](https://github.com/FernRP/FernRPExample)

[UnityURP-MobileScreenSpacePlanarReflection](https://github.com/ColinLeung-NiloCat/UnityURP-MobileScreenSpacePlanarReflection)