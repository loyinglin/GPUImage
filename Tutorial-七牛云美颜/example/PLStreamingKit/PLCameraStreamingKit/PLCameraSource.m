//
//  PLCameraSource.m
//  PLCameraStreamingKit
//
//  Created by 0day on 15/3/26.
//  Copyright (c) 2015年 qgenius. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLCameraSource.h"
#import "PLStreamingKit.h"

@interface PLCameraSource ()
<
GPUImageVideoCameraDelegate
>

@property (nonatomic, PL_STRONG) AVCaptureSession   *captureSession;
@property (nonatomic, PL_STRONG) AVCaptureDevice    *captureDevice;
@property (nonatomic, assign) BOOL  cameraToggling;

@property (nonatomic, readwrite, assign) BOOL isRunning;    // rewrite

@property (nonatomic, strong) GPUImageVideoCamera * videoCamera;

@property (nonatomic, strong) GPUImageOutput *lastOutput;

@property (nonatomic, strong) GPUImageRawDataOutput *rawOutput;

@property (nonatomic, strong) NSMutableArray *filters;

@property (nonatomic, copy, readwrite) PLVideoCaptureConfiguration   *videoCaptureConfiguration;

@end

@implementation PLCameraSource

@synthesize captureSize = _captureSize;

+ (BOOL)hasCameraForPosition:(AVCaptureDevicePosition)cameraPosition {
    AVCaptureDevice *result = nil;
    
    // find capture device
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo] && device.position == cameraPosition) {
            result = device;
            break;
        }
    }
    
    return !!result;
}

- (instancetype)initWithVideoCaptureConfiguration:(PLVideoCaptureConfiguration *)configuration
                            cameraPosition:(AVCaptureDevicePosition)cameraPosition
                          videoOrientation:(AVCaptureVideoOrientation)videoOrientation {
    self = [super init];
    if (self) {
        self.videoCaptureConfiguration = configuration;
        self.isRunning = NO;
        self.torchOn = NO;
        self.cameraToggling = NO;
        self.filters = [NSMutableArray new];
        self.cameraPosition = cameraPosition;
        self.videoOrientation = videoOrientation;
        self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:configuration.sessionPreset cameraPosition:cameraPosition];
        self.videoCamera.outputImageOrientation = (UIInterfaceOrientation)videoOrientation;
        self.videoCamera.horizontallyMirrorFrontFacingCamera = self.videoCaptureConfiguration.horizontallyMirrorFrontFacingCamera;
        self.videoCamera.horizontallyMirrorRearFacingCamera = self.videoCaptureConfiguration.horizontallyMirrorRearFacingCamera;
        self.captureSession = self.videoCamera.captureSession;
        
        self.lastOutput = self.videoCamera;
        
        [self reloadRawdataOutput];
        
        _previewView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_videoCamera addTarget:_previewView];
        
        [self refreshFPS];
        
        self.smoothAutoFocusEnabled = YES;
        
        if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        }
    }
    
    return self;
}

- (void)didEnterBackground:(NSNotification *)noty {
    [self.videoCamera pauseCameraCapture];
    runSynchronouslyOnVideoProcessingQueue(^{
        glFinish();
    });
    
}

- (void)willEnterForeground:(NSNotification *)noty {
    [self.videoCamera resumeCameraCapture];
}

- (void)dealloc {
    if (self.isRunning) {
        [self stopRunning];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshFPS {
    self.videoCamera.frameRate = (int32_t)self.videoCaptureConfiguration.videoFrameRate;
}

- (void)reloadRawdataOutput {
    [self.lastOutput removeTarget:self.rawOutput];
    
    AVCaptureVideoDataOutput *output = [[[self.videoCamera captureSession] outputs] lastObject];
    NSDictionary* outputSettings = [output videoSettings];
    
    long height  = [[outputSettings objectForKey:@"Height"]  longValue];
    long width = [[outputSettings objectForKey:@"Width"] longValue];
    if (self.videoOrientation <= AVCaptureVideoOrientationPortraitUpsideDown) {
        height  = [[outputSettings objectForKey:@"Width"]  longValue];
        width = [[outputSettings objectForKey:@"Height"] longValue];
    }
    
    CGSize outputDataSize = CGSizeMake(width, height);
    
    _captureSize = outputDataSize;
    
    self.rawOutput = [[GPUImageRawDataOutput alloc] initWithImageSize:self.captureSize resultsInBGRAFormat:YES];
    
    __weak typeof(self) wself = self;
    __weak typeof(self.rawOutput) weakOutput = self.rawOutput;
    
    
    
    [self.rawOutput setNewFrameAvailableBlock:^{
        
        
        __strong GPUImageRawDataOutput *strongOutput = weakOutput;
        __strong typeof(wself) strongSelf = wself;
        [strongOutput lockFramebufferForReading];
        GLubyte *outputBytes = [strongOutput rawBytesForImage];
        NSInteger bytesPerRow = [strongOutput bytesPerRowInOutput];
        CVPixelBufferRef pixelBuffer = NULL;
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, outputDataSize.width, outputDataSize.height, kCVPixelFormatType_32BGRA, outputBytes, bytesPerRow, nil, nil, nil, &pixelBuffer);
        [strongOutput unlockFramebufferAfterReading];
        if(pixelBuffer == NULL) {
            return ;
        }
        if ([strongSelf.delegate respondsToSelector:@selector(cameraSource:didGetPixelBuffer:)]) {
            [strongSelf.delegate cameraSource:strongSelf didGetPixelBuffer:pixelBuffer];
            
        }
        CFRelease(pixelBuffer);
         
       
    }];
    

    [self.lastOutput addTarget:self.rawOutput];
}

- (void)setCameraPosition:(AVCaptureDevicePosition)cameraPosition {
    if (cameraPosition == _cameraPosition) {
        return;
    }
    
    if ([PLCameraSource hasCameraForPosition:cameraPosition]) {
        [self toggleCamera];
        _cameraPosition = cameraPosition;
    }
}

- (void)toggleCamera {
    if(!self.captureSession)
        return;
    
    if (self.cameraToggling) {
        return;
    }
    self.cameraToggling = YES;
    [self.videoCamera rotateCamera];
    
    self.cameraToggling = NO;

}

- (void)startRunning {
    NSLog(@"CameraSource: startRunning");
    [self.videoCamera startCameraCapture];
    self.isRunning = YES;
}

- (void)stopRunning {
    NSLog(@"CameraSource: stopRunning");
    [self.videoCamera stopCameraCapture];
    self.isRunning = NO;
}
- (void)addFilter:(PLCameraFilter *)filter {
    if (!filter) {
        return;
    }
    [self.filters addObject:filter];
    [self.lastOutput removeTarget:_previewView];
    [self.lastOutput removeTarget:_rawOutput];
    [filter setSource: self.lastOutput];
    self.lastOutput = filter.output;
    [self.lastOutput addTarget:_previewView];
    [self.lastOutput addTarget:_rawOutput];
}

- (void)removeFilter:(PLCameraFilter *)filter {
    if (!filter) {
        return;
    }
    NSUInteger filterIndex = [self.filters indexOfObject:filter];
    if (NSNotFound == filterIndex) {
        return;
    }
    if (0 == filterIndex) {
        [filter.output removeAllTargets];
        [self.videoCamera removeAllTargets];
        if (self.filters.count == 1) {
            self.lastOutput = self.videoCamera;
            [self.lastOutput addTarget:_previewView];
            [self.lastOutput addTarget:_rawOutput];
        } else {
            PLCameraFilter *nextFilter = self.filters[1];
            [nextFilter setSource:self.videoCamera];
        }
    } else if (filterIndex == self.filters.count - 1) {
        [filter.output removeAllTargets];
        PLCameraFilter *lastFilter = [self.filters objectAtIndex:filterIndex - 1];
        [lastFilter.output removeAllTargets];
        self.lastOutput = lastFilter.output;
        [self.lastOutput addTarget:_previewView];
        [self.lastOutput addTarget:_rawOutput];
    } else {
        [filter.output removeAllTargets];
        PLCameraFilter *lastFilter = [self.filters objectAtIndex:filterIndex - 1];
        PLCameraFilter *nextFilter = [self.filters objectAtIndex:filterIndex + 1];
        [lastFilter.output removeAllTargets];
        self.lastOutput = lastFilter.output;
        [nextFilter setSource:self.lastOutput];
    }
    [self.filters removeObject:filter];
}

#pragma mark - Property

- (AVCaptureDevice *)captureDevice {
    return self.videoCamera.inputCamera;
}

- (void)setFocusPointOfInterest:(CGPoint)focusPointOfInterest {
    _focusPointOfInterest = focusPointOfInterest;
    
    AVCaptureDevice *device = (AVCaptureDevice *)self.captureDevice;
    bool ret = device.focusPointOfInterestSupported;
    
    if (ret) {
        NSError *err = nil;
        if ([device lockForConfiguration:&err]) {
            [device setFocusPointOfInterest:focusPointOfInterest];
            device.focusMode = device.focusMode;
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error while locking device for focus POI: %@", err);
            ret = false;
        }
    } else {
        NSLog(@"Focus POI not supported");
    }
}

- (void)setContinuousAutofocusEnable:(BOOL)continuousAutofocusEnable {
    _continuousAutofocusEnable = continuousAutofocusEnable;
    
    AVCaptureDevice *device = (AVCaptureDevice *)self.captureDevice;
    AVCaptureFocusMode newMode = continuousAutofocusEnable ?  AVCaptureFocusModeContinuousAutoFocus : AVCaptureFocusModeAutoFocus;
    bool ret = [device isFocusModeSupported:newMode];
    
    if (ret) {
        NSError *err = nil;
        if ([device lockForConfiguration:&err]) {
            device.focusMode = newMode;
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error while locking device for autofocus: %@", err);
            ret = false;
        }
    } else {
        NSLog(@"Focus mode not supported: %@", continuousAutofocusEnable ? @"AVCaptureFocusModeContinuousAutoFocus" : @"AVCaptureFocusModeAutoFocus");
    }
}

- (void)setSmoothAutoFocusEnabled:(BOOL)smoothAutoFocusEnabled {
    if (smoothAutoFocusEnabled == _smoothAutoFocusEnabled) {
        return;
    }
    _smoothAutoFocusEnabled = smoothAutoFocusEnabled;
    
    AVCaptureDevice *device = (AVCaptureDevice *)self.captureDevice;
    if (device.isSmoothAutoFocusSupported) {
        NSError *error = nil;
        [device lockForConfiguration:&error];
        device.smoothAutoFocusEnabled = smoothAutoFocusEnabled;
        [device unlockForConfiguration];
    }
}

- (void)setTorchOn:(BOOL)torchOn {
    bool ret = false;
    if (!self.captureSession || torchOn == _torchOn) {
        return ;
    }
    
    AVCaptureSession* session = (AVCaptureSession *)self.captureSession;
    
    [session beginConfiguration];
    AVCaptureDeviceInput* currentCameraInput = [session.inputs objectAtIndex:0];
    
    if(currentCameraInput.device.torchAvailable) {
        NSError* err = nil;
        if([currentCameraInput.device lockForConfiguration:&err]) {
            [currentCameraInput.device setTorchMode:( torchOn ? AVCaptureTorchModeOn : AVCaptureTorchModeOff ) ];
            [currentCameraInput.device unlockForConfiguration];
            ret = (currentCameraInput.device.torchMode == AVCaptureTorchModeOn);
        } else {
            NSLog(@"Error while locking device for torch: %@", err);
            ret = false;
        }
    } else {
        NSLog(@"Torch not available in current camera input");
    }
    [session commitConfiguration];
    
    _torchOn = ret;
}

- (CGFloat)videoZoomFactor {
    return self.captureDevice.videoZoomFactor;
}

- (void)setVideoZoomFactor:(CGFloat)videoZoomFactor {
    [self willChangeValueForKey:@"videoZoomFactor"];
    AVCaptureDevice *videoDevice = self.captureDevice;
    NSError *error = nil;
    
    if ([videoDevice lockForConfiguration:&error]) {
        // Check if desiredZoomFactor fits required range from 1.0 to activeFormat.videoMaxZoomFactor
        videoDevice.videoZoomFactor = MAX(1.0, MIN(videoZoomFactor, videoDevice.activeFormat.videoMaxZoomFactor));
        [videoDevice unlockForConfiguration];
    } else {
        NSLog(@"error: %@", error);
    }
    
    [self didChangeValueForKey:@"videoZoomFactor"];
}

- (NSArray<AVCaptureDeviceFormat *> *)videoFormats {
    return self.captureDevice.formats;
}

- (AVCaptureDeviceFormat *)videoActiveFormat {
    return self.captureDevice.activeFormat;
}

- (void)setVideoActiveFormat:(AVCaptureDeviceFormat *)videoActiveFormat {
    [self willChangeValueForKey:@"videoActiveFormat"];
    [self.captureSession beginConfiguration]; // the session to which the receiver's AVCaptureDeviceInput is added.
    NSError *error = nil;
    if ( [self.captureDevice lockForConfiguration:&error] ) {
        [self.captureDevice setActiveFormat:videoActiveFormat];
        [self.captureDevice unlockForConfiguration];
    }
    [self.captureSession commitConfiguration]; // The new format and frame rates are applied together in commitConfiguration
    [self didChangeValueForKey:@"videoActiveFormat"];
    
    [self refreshFPS];
}

- (void)setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation {
    _videoOrientation = videoOrientation;
    [self reloadRawdataOutput];
    self.videoCamera.outputImageOrientation = (UIInterfaceOrientation)videoOrientation;
}

- (void)reloadVideoCaptureConfiguration:(PLVideoCaptureConfiguration *)videoCaptureConfiguration {
    if ([videoCaptureConfiguration isEqual:self.videoCaptureConfiguration]) {
        return;
    }
    _videoCaptureConfiguration = [videoCaptureConfiguration copy];
    if ([self.captureSession canSetSessionPreset:videoCaptureConfiguration.sessionPreset]) {
        self.captureSession.sessionPreset = videoCaptureConfiguration.sessionPreset;
    }
    self.videoCamera.horizontallyMirrorFrontFacingCamera = self.videoCaptureConfiguration.horizontallyMirrorFrontFacingCamera;
    self.videoCamera.horizontallyMirrorRearFacingCamera = self.videoCaptureConfiguration.horizontallyMirrorRearFacingCamera;
    
    [self reloadRawdataOutput];
    
    [self refreshFPS];
}

#pragma mark - <PLSourceAccessProtocol>

+ (PLAuthorizationStatus)deviceAuthorizationStatus {
    return (PLAuthorizationStatus)[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
}

+ (void)requestDeviceAccessWithCompletionHandler:(void (^)(BOOL granted))handler {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (handler) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                handler(granted);
            });
        }
    }];
}

@end
