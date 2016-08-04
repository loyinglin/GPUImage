//
//  PLCameraSource.h
//  PLCameraStreamingKit
//
//  Created by 0day on 15/3/26.
//  Copyright (c) 2015年 qgenius. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "PLSourceAccessProtocol.h"
#import "PLTypeDefines.h"
#import "PLMacroDefines.h"
#import "PLVideoCaptureConfiguration.h"
#import "GPUImage.h"
#import "PLGPUImageCameraFilter.h"

@class PLCameraSource;
@protocol PLCameraSourceDelegate <NSObject>

@optional
- (CVPixelBufferRef)cameraSource:(PLCameraSource *)source didGetPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface PLCameraSource : NSObject
<
PLSourceAccessProtocol
>

@property (nonatomic, strong, readonly) GPUImageView *previewView;
@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, assign, readonly) CGSize captureSize;
@property (nonatomic, weak) id<PLCameraSourceDelegate>   delegate;
@property (nonatomic, copy, readonly) PLVideoCaptureConfiguration   *videoCaptureConfiguration;
@property (nonatomic, assign) AVCaptureDevicePosition  cameraPosition;
@property (nonatomic, assign, getter=isTorchOn) BOOL torchOn;
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;
@property (nonatomic, assign) CGPoint   focusPointOfInterest;
@property (nonatomic, assign) BOOL  continuousAutofocusEnable;
@property (nonatomic, assign, getter=isSmoothAutoFocusEnabled) BOOL  smoothAutoFocusEnabled;
@property (nonatomic, assign) CGFloat videoZoomFactor;
@property (nonatomic, strong, readonly) NSArray<AVCaptureDeviceFormat *> *videoFormats;
@property (nonatomic, strong) AVCaptureDeviceFormat *videoActiveFormat;

+ (BOOL)hasCameraForPosition:(AVCaptureDevicePosition)position;

- (instancetype)initWithVideoCaptureConfiguration:(PLVideoCaptureConfiguration *)configuration
                            cameraPosition:(AVCaptureDevicePosition)cameraPosition
                          videoOrientation:(AVCaptureVideoOrientation)videoOrientation;

- (void)toggleCamera;

- (void)reloadVideoCaptureConfiguration:(PLVideoCaptureConfiguration *)videoCaptureConfiguration;

- (void)startRunning;
- (void)stopRunning;

- (void)addFilter:(PLCameraFilter *)filter;
- (void)removeFilter:(PLCameraFilter *)filter;

@end