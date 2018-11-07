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
#import "LYAssetReader.h"

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray<GPUImageView *> *gpuImageViewArray;
@property (nonatomic, strong) NSMutableArray<GPUImageMovie *> *gpuImageMovieArray;

@property (nonatomic, strong) NSMutableArray<LYAssetReader *> *lyReaderArray;


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
    self.lyReaderArray = [[NSMutableArray<LYAssetReader *> alloc] init];
    NSArray *fileNamesArray = @[@"abc", @"qwe", @"abc", @"qwe", @"abc", @"qwe"];
    
    self.lyMultiTextureFilter = [[LYMultiTextureFilter alloc] initWithMaxFilter:MaxRow * MaxColumn];
    for (int indexRow = 0; indexRow < MaxRow; ++indexRow) {
        for (int indexColumn = 0; indexColumn < MaxColumn; ++indexColumn) {
            CGRect frame = CGRectMake(indexColumn * 1.0 / MaxColumn,
                                      indexRow * 1.0 / MaxRow,
                                      1.0 / MaxColumn,
                                      1.0 / MaxRow);
            NSURL *videoUrl = [[NSBundle mainBundle] URLForResource:fileNamesArray[indexRow * MaxColumn + indexColumn] withExtension:@"mp4"];
            GPUImageMovie *movie = [[GPUImageMovie alloc] initWithURL:videoUrl];
            [self buildGPUImageViewWithFrame:frame imageMovie:movie];
            [self.gpuImageMovieArray addObject:movie];
            
            LYAssetReader *reader = [[LYAssetReader alloc] initWithUrl:videoUrl];
            [self.lyReaderArray addObject:reader];
        }
    }
    GPUImageView *imageView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 100, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds) / MaxColumn * MaxRow)];
    imageView.fillMode = kGPUImageFillModeStretch;
    
    [self.lyMultiTextureFilter addTarget:imageView];
    [self.lyMultiTextureFilter setMainIndex:MaxRow * MaxColumn - 1];
    [self.view addSubview:imageView];
    
}


- (IBAction)onClick:(id)sender {
    if (!self.mDisplayLink) {
        self.mDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displaylink:)];
        self.mDisplayLink.frameInterval = 2;
        [self.mDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
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
    
    NSInteger index = [self.lyMultiTextureFilter nextAvailableTextureIndex];
    [tmpFilter addTarget:self.lyMultiTextureFilter atTextureLocation:index];
    [self.lyMultiTextureFilter setDrawRect:frame atIndex:index];
    
    return ;
}

- (void)displaylink:(CADisplayLink *)displaylink {
    for (int index = 0; index < MaxRow * MaxColumn; ++index) {
        GPUImageMovie *imageMovie = self.gpuImageMovieArray[index];
        LYAssetReader *reader = self.lyReaderArray[index];
        
        CMSampleBufferRef sampleBufferRef = [reader readBuffer];
        if (sampleBufferRef)
        {
            runSynchronouslyOnVideoProcessingQueue(^{
                [imageMovie processMovieFrame:sampleBufferRef];
                CMSampleBufferInvalidate(sampleBufferRef);
                CFRelease(sampleBufferRef);
            });
        }
    }
}




@end
