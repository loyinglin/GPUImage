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
