###前言
一个群友用琨君的美颜录制和讯飞离线人脸识别SDK做了一个demo，功能是录制视频，要求有美颜，并且能识别人脸并放置贴图。但是遇到一个问题：  
**录制过程能过进行人脸识别，也有美颜效果；  
但是录制的视频，有美颜效果，但没有贴图；**  
在帮忙查找bug的过程中，发现代码写得略复杂，不便于学习。  
于是，抽空把核心代码抽离出来，做成了本次的[demo](https://github.com/loyinglin/GPUImage/tree/master/Tutorial-11)。  
  
**效果如下**  
![](http://upload-images.jianshu.io/upload_images/1049769-35d8b60899e4a2e6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

###正文
####核心逻辑
demo的流程图如下    
![](http://upload-images.jianshu.io/upload_images/1049769-6840385d199c667c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
在[GPUImage详细解析（三）- 实时美颜滤镜](http://www.jianshu.com/p/2ce9b63ecfef)的基础上，引入了IFlyFaceDetector类，用GPUImageUIElement来绘制人脸识别后的贴图，并用GPUImageAddBlendFilter把美颜后的图像（GPUImageBeautifyFilter）和贴图（GPUImageUIElement）合并，传给GPUImageMovieWriter写入文件。

####人脸识别相关
**IFlyFaceDetector**   
IFlyFaceDetector是讯飞提供的本地人脸检测类，可以人脸检测、视频流检测功能。  
初始化代码如下  
```
    self.faceDetector = [IFlyFaceDetector sharedInstance];
    if(self.faceDetector){
        [self.faceDetector setParameter:@"1" forKey:@"detect"];
        [self.faceDetector setParameter:@"1" forKey:@"align"];
    }
```
demo会用到IFlyFaceDetector对NSData的识别接口  
```

/**
 *  检测frame视频帧中的人脸
 *
 *  @param frame   视频帧数据
 *  @param width  视频帧图像宽
 *  @param height 视频帧图像高
 *  @param dir    图像的方向
 *
 *  @return json格式人脸数组，没有检测到人脸则返回空
 */
- (NSString*)trackFrame:(NSData*)frame withWidth:(int)width height:(int)height direction:(int)dir;
```

**CanvasView**  
CanvasView是群友提供demo中的绘制贴图类，可以对头部、眼睛、鼻子、嘴巴、面部进行贴图，本demo会用到headMap头部贴图。  
```
//头部贴图
@property (nonatomic,strong) UIImage *  headMap;
//眼睛贴图
@property (nonatomic,strong) UIImage * eyesMap;
//鼻子贴图
@property (nonatomic,strong) UIImage * noseMap;
//嘴巴贴图
@property (nonatomic,strong) UIImage * mouthMap;
//面部贴图
@property (nonatomic,strong) UIImage * facialTextureMap;
```

####GPUImage相关
**GPUImageAddBlendFilter**  
继承类GPUImageTwoInputFilter用于合并两个图像，公式如下：  
```
    float r; // 颜色的红色分量
     if (overlay.r * base.a + base.r * overlay.a >= overlay.a * base.a) {
         r = overlay.a * base.a + overlay.r * (1.0 - base.a) + base.r * (1.0 - overlay.a);
     } else {
         r = overlay.r + base.r;
     }
```

**GPUImageUIElement**  
GPUImageUIElement继承GPUImageOutput类，作为响应链的源头。  
通过CoreGraphics把UIView渲染到图像，并通过glTexImage2D绑定到outputFramebuffer指定的纹理，最后通知targets纹理就绪。  
>demo中的作用是把CanvasView转成纹理，并传递给GPUImageAddBlendFilter。

###遇到的问题
####1、贴图无法出现在录制的视频中
启动群友提供的demo，预览正常，录制的视频确实没有贴图；  
检查响应链代码，发现代码的实现存在一个问题：  
**预览的帧和写入视频的帧不是相同的**，GPUImageUIElement的输出的结果是直接指向合并的filter，合并后的图像直接输给writer写入文件；屏幕的贴图预览效果是因为canvasView直接被addsubview到视图层中。    
怀疑是GPUImageUIElement绘制的纹理的为空。通过**检查GPU的纹理**，GPUImageUIElement对应纹理id的纹理预览为正常，排除这个问题。    
检查美颜filter的输出，同样正常。  
检查合并filter的输出，发现贴图消失。  
定位到是合并filter的问题，**检查着色器代码**，正常。  
检查初始化代码，找到问题所在：  
>群友把合并的filter的`mix=0.0；`导致合并的filter只取第一个的图像。  
  
**小结**，在查找bug的过程，因为demo较为复杂，花费了较多时间熟悉代码；通过Xcode的工具，可以较快定位大多数GPUImage 的问题。  

####2、贴图没有随着脸移动
测试本demo的过程中，出现过贴图固定住不动的情况。  
通过检查人脸识别的输出结果，确定人脸识别的输出是正常；  
检查canvasView的更新，发现问题：  
**canvasView没有更新**。  
>解决方案是把canvasView添加到视图层。  
但不知道是否为`[self.viewCanvas setNeedsDisplay];`造成的影响。  

###总结
[demo](https://github.com/loyinglin/GPUImage/tree/master/Tutorial-11)在这里，代码较短。  
因为是每帧识别，所以CPU的消耗较高。  
如果是实际应用，可以考虑3~5帧左右做一次人脸识别。  
还有另外一个简单的思路：**把输入从摄像头变成视频，对视频进行逐帧人脸识别并吧贴图合并到视频中。**  
