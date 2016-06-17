//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by 林伟池 on 16/5/10.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import <AssetsLibrary/ALAssetsLibrary.h>

@interface ViewController ()
@property (nonatomic , strong) UILabel  *mLabel;
@end


@implementation ViewController
{
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
    GPUImageVideoCamera *videoCamera;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.view = filterView;
    
    self.mLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 100, 100)];
    self.mLabel.textColor = [UIColor redColor];
    [self.view addSubview:self.mLabel];
    
    filter = [[GPUImageDissolveBlendFilter alloc] init];
    [(GPUImageDissolveBlendFilter *)filter setMix:0.5];
    
    // 播放
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"abc" withExtension:@"mp4"];
    movieFile = [[GPUImageMovie alloc] initWithURL:sampleURL];
    movieFile.runBenchmark = YES;
    movieFile.playAtActualSpeed = YES;
    // 摄像头
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
    Boolean audioFromFile = NO;
    if (audioFromFile) {
        // 响应链
        [movieFile addTarget:filter];
        [videoCamera addTarget:filter];
        movieWriter.shouldPassthroughAudio = YES;
        movieFile.audioEncodingTarget = movieWriter;
        [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    }
    else {
        // 响应链
        [videoCamera addTarget:filter];
        [movieFile addTarget:filter];
        movieWriter.shouldPassthroughAudio = NO;
        videoCamera.audioEncodingTarget = movieWriter;
        movieWriter.encodingLiveVideo = NO;
    }
    // 显示到界面
    [filter addTarget:filterView];
    [filter addTarget:movieWriter];
    
    [videoCamera startCameraCapture];
    [movieWriter startRecording];
    [movieFile startProcessing];
    
    CADisplayLink* dlink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
    [dlink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [dlink setPaused:NO];
    
    __weak typeof(self) weakSelf = self;
    [movieWriter setCompletionBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->filter removeTarget:strongSelf->movieWriter];
        [strongSelf->movieWriter finishRecording];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToMovie))
        {
            [library writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     if (error) {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil
                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     } else {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil
                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     }
                 });
             }];
        }
        else {
            NSLog(@"error mssg)");
        }
    }];
}



- (void)updateProgress
{
    self.mLabel.text = [NSString stringWithFormat:@"Progress:%d%%", (int)(movieFile.progress * 100)];
    [self.mLabel sizeToFit];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
