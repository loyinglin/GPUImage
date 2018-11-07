//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by loyinglin on 16/5/10.
//  Copyright © 2016年 loyinglin. All rights reserved.
//


#import "GPUImage.h"

/**
 把多个Texture渲染到同一个FrameBuffer
 
 使用时需要先绑定frameBuffer和显示区域rect
 在newFrame回调的时候，会根据index把图像绘制在绑定的rect
 特别的，会制定一个mainIndex，当此index就绪时调用newFrame通知响应链的下一个
 */
@interface LYMultiTextureFilter : GPUImageFilter

- (instancetype)initWithMaxFilter:(NSInteger)maxFilter;

/**
 设置绘制区域rect，并且绑定纹理id

 @param rect 绘制区域 origin是起始点，size是矩形大小；（取值范围是0~1，点(0,0)表示左下角，点(1,1)表示右上角, Size(1,1)表示最大区域）
 
 @param filterIndex 纹理id
 */
- (void)setDrawRect:(CGRect)rect atIndex:(NSInteger)filterIndex;

- (void)setMainIndex:(NSInteger)filterIndex;

@end
