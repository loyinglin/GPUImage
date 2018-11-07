//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by loyinglin on 16/5/10.
//  Copyright © 2016年 loyinglin. All rights reserved.
//

#import "ViewController.h"
#import <GPUImageView.h>
#import <GPUImageVideoCamera.h>
#import <GPUImageSepiaFilter.h>

@interface ViewController ()
@property (strong, nonatomic) IBOutlet GPUImageView *mGPUImageView;
@property (nonatomic , strong) GPUImageVideoCamera *mGPUVideoCamera;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.mGPUVideoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    self.mGPUImageView.fillMode = kGPUImageFillModeStretch;//kGPUImageFillModePreserveAspectRatioAndFill;
    
    GPUImageSepiaFilter* filter = [[GPUImageSepiaFilter alloc] init];
    [self.mGPUVideoCamera addTarget:filter];
    [filter addTarget:self.mGPUImageView];
    
    //[self.mGPUVideoCamera addTarget:self.mGPUImageView];

    [self.mGPUVideoCamera startCameraCapture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    UIInterfaceOrientation orientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
    self.mGPUVideoCamera.outputImageOrientation = orientation;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
