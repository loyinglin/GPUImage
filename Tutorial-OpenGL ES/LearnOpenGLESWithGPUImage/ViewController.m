//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by 林伟池 on 16/5/10.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "ViewController.h"
#import "LYOpenGLView.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/ALAssetsLibrary.h>

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic , strong) UILabel  *mLabel;
@property (nonatomic , strong) AVCaptureSession *mCaptureSession; //负责输入和输出设备之间的数据传递
@property (nonatomic , strong) AVCaptureDeviceInput *mCaptureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (nonatomic , strong) AVCaptureVideoDataOutput *mCaptureDeviceOutput; //

// OpenGL ES
@property (nonatomic , strong)  LYOpenGLView *mGLView;

@end


@implementation ViewController
{
    dispatch_queue_t mProcessQueue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mGLView = (LYOpenGLView *)self.view;
    [self.mGLView setupGL];
    
    self.mCaptureSession = [[AVCaptureSession alloc] init];
    self.mCaptureSession.sessionPreset = AVCaptureSessionPreset640x480;
    
    mProcessQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    AVCaptureDevice *inputCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == AVCaptureDevicePositionFront)
        {
            inputCamera = device;
        }
    }
    
    self.mCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];
    
    if ([self.mCaptureSession canAddInput:self.mCaptureDeviceInput]) {
        [self.mCaptureSession addInput:self.mCaptureDeviceInput];
    }

    
    self.mCaptureDeviceOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.mCaptureDeviceOutput setAlwaysDiscardsLateVideoFrames:NO];
    
    [self.mCaptureDeviceOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.mCaptureDeviceOutput setSampleBufferDelegate:self queue:mProcessQueue];
    if ([self.mCaptureSession canAddOutput:self.mCaptureDeviceOutput]) {
        [self.mCaptureSession addOutput:self.mCaptureDeviceOutput];
    }
    
    AVCaptureConnection *connection = [self.mCaptureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
    [connection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
    
    
    [self.mCaptureSession startRunning];
    

    self.mLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 100, 100)];
    self.mLabel.textColor = [UIColor redColor];
    [self.view addSubview:self.mLabel];
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    static long frameID = 0;
    ++frameID;
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.mGLView displayPixelBuffer:pixelBuffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mLabel.text = [NSString stringWithFormat:@"%ld", frameID];
    });
}


#pragma mark - Simple Editor

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
