//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by loyinglin on 16/5/10.
//  Copyright © 2016年 loyinglin. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import "LYMultiTextureFilter.h"

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray<GPUImageView *> *gpuImageViewArray;
@property (nonatomic, strong) NSMutableArray<GPUImageMovie *> *gpuImageMovieArray;

@property (nonatomic, strong) CADisplayLink *mDisplayLink;

@property (nonatomic, strong) LYMultiTextureFilter *lyMultiTextureFilter;
@end


@implementation ViewController

#define MaxRow (2)
#define MaxColumn (3)


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.gpuImageViewArray = [[NSMutableArray<GPUImageView *> alloc] init];
    self.gpuImageMovieArray = [[NSMutableArray<GPUImageMovie *> alloc] init];
    NSArray *fileNamesArray = @[@"abc", @"qwe", @"abc", @"qwe", @"abc", @"qwe"];
    
    self.lyMultiTextureFilter = [[LYMultiTextureFilter alloc] initWithMaxFilter:MaxRow * MaxColumn];
    for (int indexRow = 0; indexRow < MaxRow; ++indexRow) {
        for (int indexColumn = 0; indexColumn < MaxColumn; ++indexColumn) {
            CGRect frame = CGRectMake(indexColumn * 1.0 / MaxColumn,
                                      indexRow * 1.0 / MaxRow,
                                      1.0 / MaxColumn,
                                      1.0 / MaxRow);
            GPUImageMovie *movie = [self getGPUImageMovieWithFileName:fileNamesArray[indexRow * MaxColumn + indexColumn]];
            [self buildGPUImageViewWithFrame:frame imageMovie:movie];
            [self.gpuImageMovieArray addObject:movie];
        }
    }
    GPUImageView *imageView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 100, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds) / MaxColumn * MaxRow)];
    imageView.backgroundColor = [UIColor clearColor];
    imageView.fillMode = kGPUImageFillModeStretch;
    [self.lyMultiTextureFilter addTarget:imageView];
    [self.view addSubview:imageView];
    
    self.mDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displaylink:)];
    [self.mDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (GPUImageMovie *)getGPUImageMovieWithFileName:(NSString *)fileName {
    NSURL *videoUrl = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"mp4"];
    
    GPUImageMovie *imageMovie = [[GPUImageMovie alloc] initWithURL:videoUrl];
    return imageMovie;
}

- (void)buildGPUImageViewWithFrame:(CGRect)frame imageMovie:(GPUImageMovie *)imageMovie {
    // 1080 1920，这里已知视频的尺寸。如果不清楚视频的尺寸，可以先读取视频帧CVPixelBuffer，再用CVPixelBufferGetHeight/Width
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake((1920 - 1080) / 2 / 1920, 0, 1080.0 / 1920, 1)];
    
    GPUImageTransformFilter *transformFilter = [[GPUImageTransformFilter alloc] init];
    transformFilter.affineTransform = CGAffineTransformMakeRotation(M_PI_2);
    
    GPUImageOutput *tmpFilter;
    
    tmpFilter = imageMovie;
    
    [tmpFilter addTarget:cropFilter];
    tmpFilter = cropFilter;
    
    [tmpFilter addTarget:transformFilter];
    tmpFilter = transformFilter;
//    [imageView setInputRotation:kGPUImageRotateRight atIndex:0];
    
    NSInteger index = [self.lyMultiTextureFilter nextAvailableTextureIndex];
    [tmpFilter addTarget:self.lyMultiTextureFilter atTextureLocation:index];
    [self.lyMultiTextureFilter setDrawRect:frame atIndex:index];
    
    
    imageMovie.playAtActualSpeed = YES;
    imageMovie.shouldRepeat = YES;
    
    [imageMovie startProcessing];
    
    return ;
}

- (void)displaylink:(CADisplayLink *)displaylink {
}




@end
