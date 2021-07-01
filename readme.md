# GAMES202_HQRTR

### homework0
实现的Blinn-Phong 着色模型；

------

### homework1
主要是在Blinn-Phong 着色模型基础上实现阴影，通过shadow map实现硬阴影、PCF软阴影过滤、PCSS软硬阴影；

------

### homework2

作业2主要是在实现PRT(Precomputed Radiance Transfer)本次作业的工作主要分为两个部分：
cpp 端的通过一种预计算方法，该方法在离线渲染的 Path Tracing 工具链
预计算 lighting 以及 light transport 并将它们用球谐函数拟合后储存；
在 WebGL框架上使用预计算数据部分;
1、基于球谐函数的预计算辐射传输
2、分为有阴影与无阴影的
3、加分项旋转和间接光弹射

------

### homework3
作业三主要即考虑直接光照也考虑间接光照，最主要是实现全局光
• 实现对场景直接光照的着色 (考虑阴影)。
• 实现屏幕空间下光线的求交 (SSR)。
• 实现对场景间接光照的着色。

------

### homework4
作业四为Kulla-Conty BRDF模型，即对错误能量损失的补偿，尽量保证能量守恒
• 微表面PBR BRDF。
• 预计算Eμ。
• 预计算Eavg。
•Kulla-Conty BRDF模型 。