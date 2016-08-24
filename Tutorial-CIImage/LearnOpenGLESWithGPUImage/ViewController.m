//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by 林伟池 on 16/5/10.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"

@interface ViewController ()
@property (nonatomic , strong) GPUImagePicture *sourcePicture;
@property (nonatomic , strong) GPUImageTiltShiftFilter *sepiaFilter;
@property (nonatomic , strong) UIImageView *mCIImageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    GPUImageView *primaryView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.view = primaryView;
    UIImage *inputImage = [UIImage imageNamed:@"face.png"];
    _sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage];
    _sepiaFilter = [[GPUImageTiltShiftFilter alloc] init];
    _sepiaFilter.blurRadiusInPixels = 40.0;
    [_sepiaFilter forceProcessingAtSize:primaryView.sizeInPixels];
    [_sourcePicture addTarget:_sepiaFilter];
    [_sepiaFilter addTarget:primaryView];
    [_sourcePicture processImage];
    
    
    // GPUImageContext相关的数据显示
    GLint size = [GPUImageContext maximumTextureSizeForThisDevice];
    GLint unit = [GPUImageContext maximumTextureUnitsForThisDevice];
    GLint vector = [GPUImageContext maximumVaryingVectorsForThisDevice];
    NSLog(@"%d %d %d", size, unit, vector);
    
    [self testCIImage];
}

- (void)testCIImage {
    UIImage *inputImage = [UIImage imageNamed:@"face.png"];
    
    _mCIImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame) / 2, CGRectGetHeight(self.view.frame) / 2)];
    [self.view addSubview:self.mCIImageView];
    
    
    /**
     CoreImage在IOS上有很高的效率，但是滤镜和渲染操作也会对主线程造成影响。应该将CoreImage滤镜渲染操作放在后台线程执行，当这些操作介绍后在返回主线程进行界面的更新。
     
     有一个CIImage，上面配置了强度为0.5的棕色滤镜，现在通过滑块将强度改为0.6，这个滤镜应该用在新的CIImage上，如果不是新的CIImage上，那么原来的CIImage中将包含强度为0.5和0.6的棕色滤镜
     **/
    
    CFAbsoluteTime elapsedTime, startTime = CFAbsoluteTimeGetCurrent();
    
    CIImage *ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];
    
    CIFilter *sepiaTone = [CIFilter filterWithName:@"CISepiaTone"
                                     keysAndValues: kCIInputImageKey, ciInputImage,
                           @"inputIntensity", [NSNumber numberWithFloat:1.0], nil];
    
    CIImage *result = [sepiaTone outputImage];
    
    //    UIImage *resultImage = [UIImage imageWithCIImage:result]; // This gives a nil image, because it doesn't render, unless I'm doing something wrong
    
    CIContext *context = [CIContext contextWithOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kCIContextUseSoftwareRenderer]];//CPU渲染
    
    CGImageRef resultRef = [context createCGImage:result fromRect:CGRectMake(0, 0, inputImage.size.width, inputImage.size.height)];
    UIImage *resultImage = [UIImage imageWithCGImage:resultRef];
    CGImageRelease(resultRef);
    elapsedTime = CFAbsoluteTimeGetCurrent() - startTime;
    NSLog(@"%f s", elapsedTime * 1000.0);
    
    self.mCIImageView.image = resultImage;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    float rate = point.y / self.view.frame.size.height;
    NSLog(@"Processing");
    [_sepiaFilter setTopFocusLevel:rate - 0.1];
    [_sepiaFilter setBottomFocusLevel:rate + 0.1];
    [_sourcePicture processImage];
    
    
    
}

@end
