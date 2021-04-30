我完成了作业中所有基础部分和Diffuse Inter-reflection(bonus)提高部分
image文件夹说明
PRT_Shadowed目录和PRT_Unshadowed目录，PRT_InterRef目录是利用nori C++预计算出来的结果图片
WebGL中的PRT_Shadowed,PRT_InterRef目录是实时实时球谐光照计算的截图



改动的文件

prt.cpp

完成了TODO部分，并添加getInterReflection函数（Interreflection部分）



WebGL部分

添加了PRTMaterial.js->PRT材质 src\materials\PRTMaterial.js

添加了PRT shader src\shaders\PRTShader

更改loadOBJ.js TODO *Add your PRTmaterial here* 将PRT材质加入，同时引入precomputeL

