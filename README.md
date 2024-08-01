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

## 开发计划

- [ ] 基础卡通材质
  - [x] 二值CellShading
  - [x] 多光源
  - [ ] 色散
  - [ ] SRP batcher
- [x] 边缘检测描边 
- [ ] 人物
  - [ ] 眼睛
  - [ ] 头发
  - [ ] 黑丝
  - [ ] 脸
    - [ ] SDF阴影
- [ ] 卡通面片草
  - [ ] HiZ剔除+Instance
- [ ] 卡通石头
  - [ ] 顶部覆盖植被
- [ ] 卡通水
- [ ] 卡通树

## 参考

[FernRP](https://github.com/FernRP/FernRPExample)