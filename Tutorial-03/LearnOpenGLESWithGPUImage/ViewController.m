//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by 林伟池 on 16/5/10.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import "GPUImageBeautifyFilter.h"
#import <AssetsLibrary/ALAssetsLibrary.h>

@interface ViewController ()
@property (nonatomic , strong) UILabel  *mLabel;

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic , strong) GPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) GPUImageView *filterView;

@end


@implementation ViewController
{
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.filterView.center = self.view.center;
    [self.view addSubview:self.filterView];
    
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
    
    self.videoCamera.audioEncodingTarget = _movieWriter;
    _movieWriter.encodingLiveVideo = YES;
    [self.videoCamera startCameraCapture];
    GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    [self.videoCamera addTarget:beautifyFilter];
    [beautifyFilter addTarget:self.filterView];
    [beautifyFilter addTarget:_movieWriter];
    [_movieWriter startRecording];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [beautifyFilter removeTarget:_movieWriter];
        [_movieWriter finishRecording];
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
    });
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
