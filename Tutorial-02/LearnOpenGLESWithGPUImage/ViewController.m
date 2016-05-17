//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by 林伟池 on 16/5/10.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "ViewController.h"
#import <GPUImageView.h>
#import <GPUImageVideoCamera.h>
#import <GPUImageSepiaFilter.h>

@interface ViewController ()
@property (nonatomic , strong) GPUImageView *mGPUImageView;
@property (nonatomic , strong) GPUImageVideoCamera *mGPUVideoCamera;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.mGPUVideoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    self.mGPUVideoCamera.outputImageOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    self.mGPUImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    self.mGPUImageView.fillMode = kGPUImageFillModeStretch;//kGPUImageFillModePreserveAspectRatioAndFill;
    [self.view addSubview:self.mGPUImageView];
    
//    GPUImageSepiaFilter* filter = [[GPUImageSepiaFilter alloc] init];
//    [self.mGPUVideoCamera addTarget:filter];
//    [filter addTarget:self.mGPUImageView];
    
    [self.mGPUVideoCamera addTarget:self.mGPUImageView];

    [self.mGPUVideoCamera startCameraCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
