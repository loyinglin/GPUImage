//
//  PLCameraStreamingSession.m
//  PLCameraStreamingKit
//
//  Created on 15/4/1.
//  Copyright (c) 2015年 Pili Engineering. All rights reserved.
//

#import "PLCameraStreamingSession.h"
#import "PLCameraSource.h"
#import "PLMicrophoneSource.h"


NSString *PLStreamStateDidChangeNotification = @"PLStream.state.didChange.notification";
NSString *PLCameraAuthorizationStatusDidGetNotificaiton = @"PLStream.camera.authorizationStatus.didGet.notification";
NSString *PLMicrophoneAuthorizationStatusDidGetNotificaiton = @"PLStream.microphone.authorizationStatus.didGet.notification";

NSString *PLCameraDidStartRunningNotificaiton = @"PLStream.camera.state.didStartRunning";
NSString *PLMicrophoneDidStartRunningNotificaiton = @"PLStream.microphone.state.didStartRunning";

static NSString *const PLReconnectErrorDomain = @"pili.error.reconnect";

@interface PLCameraStreamingSession ()
<
PLCameraSourceDelegate,
PLMicrophoneSourceDelegate,
PLStreamingSessionDelegate,
PLStreamingSendingBufferDelegate
>

@property (nonatomic, PL_STRONG) PLStreamingSession *streamingSession;

@property (nonatomic, PL_STRONG) PLCameraSource *cameraSource;
@property (nonatomic, PL_STRONG) PLMicrophoneSource *microphoneSource;

@property (nonatomic, assign, readwrite)    CGSize videoSize;   // rewrite
@property (nonatomic, assign, readwrite)    int fps;  // rewrite
@property (nonatomic, assign) int64_t bitrate;

@property (nonatomic, PL_STRONG) UITapGestureRecognizer *tapGestureRecognizer;

// Category rewrite
@property (nonatomic, PL_WEAK) id<PLStreamingSendingBufferDelegate> bufferDelegate;
@property (nonatomic, assign) CGFloat    threshold;
@property (nonatomic, assign) CGFloat    lowThreshold;
@property (nonatomic, assign) CGFloat    highThreshold;
@property (nonatomic, assign) NSTimeInterval    maxDuration;
@property (nonatomic, assign, readonly) NSTimeInterval    currentDuration;
@property (nonatomic, assign) AVCaptureDevicePosition   captureDevicePosition;
@property (nonatomic, assign, getter=isTorchOn) BOOL    torchOn;
@property (nonatomic, assign) CGPoint   focusPointOfInterest;
@property (nonatomic, assign, getter=isContinuousAutofocusEnable) BOOL  continuousAutofocusEnable;
@property (nonatomic, assign, getter=isTouchToFocusEnable) BOOL touchToFocusEnable;
@property (nonatomic, assign, getter=isMuted)   BOOL    muted;
@property (nonatomic, assign, getter=isIdleTimerDisable) BOOL  idleTimerDisable;
@property (nonatomic, assign, getter=isSmoothAutoFocusEnabled) BOOL  smoothAutoFocusEnabled;
@property (nonatomic, assign, getter=isPinchToZoomEnabled) BOOL  pinchToZoomEnabled;
@property (nonatomic, assign) CGFloat videoZoomFactor;
@property (nonatomic, PL_STRONG) AVCaptureDeviceFormat *videoActiveFormat;
@property (nonatomic, PL_STRONG) NSMutableDictionary *filters;

@property (nonatomic, copy) PLVideoCaptureConfiguration  *videoCaptureConfiguration;
@property (nonatomic,copy) PLAudioCaptureConfiguration  *audioCaptureConfiguration;
@property (nonatomic, copy) PLVideoStreamingConfiguration  *videoStreamingConfiguration;
@property (nonatomic, copy) PLAudioStreamingConfiguration  *audioStreamingConfiguration;

@end

@implementation PLCameraStreamingSession {
    // camera source
    CGPoint _focusPointOfInterest;
    BOOL    _continuousAutofocusEnable;
    AVCaptureDevicePosition _captureDevicePosition;
    
    // microphone source
    BOOL    _muted;
    
    // application
    BOOL    _idleTimerDisable;
    BOOL    _cachedIdleTimerDisable;
}

- (instancetype)initWithVideoCaptureConfiguration:(PLVideoCaptureConfiguration *)videoCaptureConfiguration
                        audioCaptureConfiguration:(PLAudioCaptureConfiguration *)audioCaptureConfiguration
                      videoStreamingConfiguration:(PLVideoStreamingConfiguration *)videoStreamingConfiguration
                      audioStreamingConfiguration:(PLAudioStreamingConfiguration *)audioStreamingConfiguration
                                           stream:(PLStream *)stream
                                 videoOrientation:(AVCaptureVideoOrientation)videoOrientation {
    self = [super init];
    if (self) {
        // default value init
        self.videoStreamingConfiguration = videoStreamingConfiguration;
        self.audioStreamingConfiguration = audioStreamingConfiguration;
        self.videoCaptureConfiguration = videoCaptureConfiguration;
        self.audioCaptureConfiguration = audioCaptureConfiguration;
        self.videoOrientation = videoOrientation;
        self.stream = stream;
        self.filters = [NSMutableDictionary new];
        self.muted = NO;
        self.torchOn = NO;
        self.focusPointOfInterest = CGPointMake(0.5, 0.5);
        self.continuousAutofocusEnable = YES;
        self.touchToFocusEnable = YES;
        self.idleTimerDisable = YES;
        if (!audioCaptureConfiguration) {
            audioStreamingConfiguration = nil;
        }
        if (!videoCaptureConfiguration) {
            videoStreamingConfiguration = nil;
        }
        if (videoCaptureConfiguration && videoStreamingConfiguration) {
            _captureDevicePosition = videoCaptureConfiguration.position;
            [self initCameraSource];
        }
        if (audioCaptureConfiguration && audioStreamingConfiguration) {
            [self initMicophoneSourceWithCompletionHandler:^(BOOL success) {
                if (success) {
                    audioStreamingConfiguration.encodedAudioSampleRate = self.microphoneSource.captureASBD->mSampleRate;
                    self.streamingSession = [[PLStreamingSession alloc] initWithVideoStreamingConfiguration:videoStreamingConfiguration
                                                                                audioStreamingConfiguration:audioStreamingConfiguration
                                                                                                     stream:stream];
                    self.streamingSession.delegate = self;
                    self.streamingSession.bufferDelegate = self;
                } else {
                    self.streamingSession = [[PLStreamingSession alloc] initWithVideoStreamingConfiguration:videoStreamingConfiguration
                                                                                audioStreamingConfiguration:nil
                                                                                                     stream:stream];
                    self.streamingSession.delegate = self;
                    self.streamingSession.bufferDelegate = self;
                }
            }];
        } else {
            self.streamingSession = [[PLStreamingSession alloc] initWithVideoStreamingConfiguration:videoStreamingConfiguration
                                                                        audioStreamingConfiguration:nil
                                                                                             stream:stream];
            self.streamingSession.delegate = self;
            self.streamingSession.bufferDelegate = self;
        }
    }
    
    return self;
}

- (void)stop {
    if (self.microphoneSource.isRunning) {
        [self.microphoneSource stopRunning];
    }
    
    [self.streamingSession stop];
}

- (void)destroy {
    if (self.microphoneSource.isRunning) {
        [self.microphoneSource stopRunning];
    }
    if (self.cameraSource.isRunning) {
        [self.cameraSource stopRunning];
    }
    
    [self.streamingSession destroy];
    
    self.cameraSource = nil;
    self.microphoneSource = nil;
}

- (void)reloadVideoStreamingConfiguration:(PLVideoStreamingConfiguration *)videoStreamingConfiguration videoCaptureConfiguration:(PLVideoCaptureConfiguration *)videoCaptureConfiguration {
    if (![self.videoStreamingConfiguration isEqual:videoStreamingConfiguration]) {
        [self.streamingSession reloadVideoStreamingConfiguration:videoStreamingConfiguration];
        self.videoStreamingConfiguration = videoStreamingConfiguration;
    }
    if (![self.videoCaptureConfiguration isEqual:videoCaptureConfiguration]) {
        [self.cameraSource reloadVideoCaptureConfiguration:videoCaptureConfiguration];
        self.videoCaptureConfiguration = videoCaptureConfiguration;
    }
}

#pragma mark - <PLStreamingSessionDelegate>

- (void)streamingSession:(PLStreamingSession *)session streamStateDidChange:(PLStreamState)state {
    if ([self.delegate respondsToSelector:@selector(cameraStreamingSession:streamStateDidChange:)]) {
        dispatch_queue_t queue = self.delegateQueue ? self.delegateQueue : dispatch_get_main_queue();
        dispatch_async(queue, ^{
            [self.delegate cameraStreamingSession:self streamStateDidChange:state];
        });
    }
}

/// @abstract 因产生了某个 error 而断开时的回调
- (void)streamingSession:(PLStreamingSession *)session didDisconnectWithError:(NSError *)error {
    if (self.microphoneSource.isRunning) {
        [self.microphoneSource stopRunning];
    }
    if ([self.delegate respondsToSelector:@selector(cameraStreamingSession:didDisconnectWithError:)]) {
        dispatch_queue_t queue = self.delegateQueue ? self.delegateQueue : dispatch_get_main_queue();
        dispatch_async(queue, ^{
            [self.delegate cameraStreamingSession:self didDisconnectWithError:error];
        });
    }
}

/// @abstract 当开始推流时，会每间隔 3s 调用该回调方法来反馈该 3s 内的流状态，包括视频帧率、音频帧率、音视频总码率
- (void)streamingSession:(PLStreamingSession *)session streamStatusDidUpdate:(PLStreamStatus *)status {
    if ([self.delegate respondsToSelector:@selector(cameraStreamingSession:streamStatusDidUpdate:)]) {
        dispatch_queue_t queue = self.delegateQueue ? self.delegateQueue : dispatch_get_main_queue();
        dispatch_async(queue, ^{
            [self.delegate cameraStreamingSession:self streamStatusDidUpdate:status];
        });
    }
}

#pragma mark - <PLStreamingSendingBufferDelegate>

- (void)streamingSessionSendingBufferDidEmpty:(id)session {
    if ([self.bufferDelegate respondsToSelector:@selector(streamingSessionSendingBufferDidEmpty:)]) {
        dispatch_queue_t queue = self.delegateQueue ? self.delegateQueue : dispatch_get_main_queue();
        dispatch_async(queue, ^{
            [self.bufferDelegate streamingSessionSendingBufferDidEmpty:self];
        });
    }
}

- (void)streamingSessionSendingBufferDidFull:(id)session {
    if ([self.bufferDelegate respondsToSelector:@selector(streamingSessionSendingBufferDidFull:)]) {
        dispatch_queue_t queue = self.delegateQueue ? self.delegateQueue : dispatch_get_main_queue();
        dispatch_async(queue, ^{
            [self.bufferDelegate streamingSessionSendingBufferDidFull:self];
        });
    }
}

#pragma mark -

- (void)initCameraSource {
    void (^permissionBlock)(void) = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PLCameraAuthorizationStatusDidGetNotificaiton object:nil userInfo:@{@"status": @(PLAuthorizationStatusAuthorized)}];
        });
        
        if ([self.delegate respondsToSelector:@selector(cameraStreamingSession:didGetCameraAuthorizationStatus:)]) {
            dispatch_queue_t queue = self.delegateQueue ? self.delegateQueue : dispatch_get_main_queue();
            dispatch_async(queue, ^{
                [self.delegate cameraStreamingSession:self didGetCameraAuthorizationStatus:PLAuthorizationStatusAuthorized];
            });
        }
        
        if (self.videoCaptureConfiguration) {
            self.cameraSource = [[PLCameraSource alloc] initWithVideoCaptureConfiguration:self.videoCaptureConfiguration
                                                                           cameraPosition:self.captureDevicePosition
                                                                         videoOrientation:self.videoOrientation];
            self.cameraSource.delegate = self;
            self.cameraSource.focusPointOfInterest = self.focusPointOfInterest;
            self.cameraSource.continuousAutofocusEnable = self.isContinuousAutofocusEnable;
            
            [self.cameraSource startRunning];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:PLCameraDidStartRunningNotificaiton object:nil userInfo:nil];
            });
        }
    };
    
    void (^noAccessBlock)(PLAuthorizationStatus status) = ^(PLAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PLCameraAuthorizationStatusDidGetNotificaiton object:nil userInfo:@{@"status": @(status)}];
        });
        if ([self.delegate respondsToSelector:@selector(cameraStreamingSession:didGetCameraAuthorizationStatus:)]) {
            dispatch_queue_t queue = self.delegateQueue ? self.delegateQueue : dispatch_get_main_queue();
            dispatch_async(queue, ^{
                [self.delegate cameraStreamingSession:self didGetCameraAuthorizationStatus:status];
            });
        }
    };
    
    PLAuthorizationStatus status = [PLCameraStreamingSession cameraAuthorizationStatus];
    switch (status) {
        case PLAuthorizationStatusAuthorized:
            permissionBlock();
            break;
        case PLAuthorizationStatusNotDetermined: {
            [PLCameraStreamingSession requestCameraAccessWithCompletionHandler:^(BOOL granted) {
                granted ? permissionBlock() : noAccessBlock(PLAuthorizationStatusDenied);
            }];
        }
            break;
        default:
            noAccessBlock(status);
            break;
    }
}

- (void)initMicophoneSourceWithCompletionHandler:(void (^)(BOOL success))completion {
    void (^permissionBlock)(void) = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PLMicrophoneAuthorizationStatusDidGetNotificaiton object:nil userInfo:@{@"status": @(PLAuthorizationStatusAuthorized)}];
        });
        if ([self.delegate respondsToSelector:@selector(cameraStreamingSession:didGetMicrophoneAuthorizationStatus:)]) {
            dispatch_queue_t queue = self.delegateQueue ? self.delegateQueue : dispatch_get_main_queue();
            dispatch_async(queue, ^{
                [self.delegate cameraStreamingSession:self didGetMicrophoneAuthorizationStatus:PLAuthorizationStatusAuthorized];
                
            });
        }
        
        
        self.microphoneSource = [[PLMicrophoneSource alloc] initWithAudioCaptureConfiguration:_audioCaptureConfiguration];
        self.microphoneSource.delegate = self;
        completion(YES);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PLMicrophoneDidStartRunningNotificaiton object:nil userInfo:nil];
        });
    };
    
    void (^noAccessBlock)(PLAuthorizationStatus status) = ^(PLAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PLMicrophoneAuthorizationStatusDidGetNotificaiton object:nil userInfo:@{@"status": @(status)}];
        });
        if ([self.delegate respondsToSelector:@selector(cameraStreamingSession:didGetMicrophoneAuthorizationStatus:)]) {
            dispatch_queue_t queue = self.delegateQueue ? self.delegateQueue : dispatch_get_main_queue();
            dispatch_async(queue, ^{
                [self.delegate cameraStreamingSession:self didGetMicrophoneAuthorizationStatus:status];
            });
        }
        completion(NO);
    };
    
    PLAuthorizationStatus status = [PLCameraStreamingSession microphoneAuthorizationStatus];
    switch (status) {
        case PLAuthorizationStatusAuthorized:
            permissionBlock();
            break;
        case PLAuthorizationStatusNotDetermined: {
            [PLCameraStreamingSession requestMicrophoneAccessWithCompletionHandler:^(BOOL granted) {
                granted ? permissionBlock() : noAccessBlock(PLAuthorizationStatusDenied);
            }];
        }
            break;
        default:
            noAccessBlock(status);
            break;
    }
}

#pragma mark - <PLCameraSourceDelegate>

- (CVPixelBufferRef)cameraSource:(PLCameraSource *)source didGetPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if ([self.delegate respondsToSelector:@selector(cameraStreamingSession:cameraSourceDidGetPixelBuffer:)]) {
        dispatch_queue_t queue = self.delegateQueue ? self.delegateQueue : dispatch_get_main_queue();
        __block CVPixelBufferRef pixel = pixelBuffer;
        dispatch_sync(queue, ^{
            pixel = [self.delegate cameraStreamingSession:self cameraSourceDidGetPixelBuffer:pixelBuffer];
        });
        pixelBuffer = pixel;
    }
    if (PLStreamStateConnected == self.streamingSession.streamState) {
        CFRetain(pixelBuffer);
        [self.streamingSession pushPixelBuffer:pixelBuffer completion:^(BOOL success) {
            CFRelease(pixelBuffer);
        }];
    }
    
    return pixelBuffer;
}

#pragma mark - <PLMicrophoneSourceDelegate>

- (void)microphoneSource:(PLMicrophoneSource *)source didGetAudioBuffer:(AudioBuffer *)buffer {
    if (PLStreamStateConnected == self.streamingSession.streamState) {
        [self.streamingSession pushAudioBuffer:buffer asbd:source.captureASBD];
    }
}

- (void)microphoneSourceHardwareSamplerateChanged:(PLMicrophoneSource *)source {
    if (self.microphoneSource.isRunning) {
        [self.microphoneSource stopRunning];
    }
    [self initMicophoneSourceWithCompletionHandler:nil];
    _audioStreamingConfiguration.encodedAudioSampleRate = self.microphoneSource.captureASBD->mSampleRate;
    
    [self.streamingSession reloadAudioStreamingConfiguration:_audioStreamingConfiguration];
    if (self.isRunning) {
        [self.microphoneSource startRunning];
    }
}

- (void)microphoneSource:(PLMicrophoneSource *)source tryRestartCaptureError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(cameraStreamingSession:didDisconnectWithError:)]) {
        [self.delegate cameraStreamingSession:self didDisconnectWithError:error];
    }
}

- (void)microphoneSourceMediaServicesWereReset:(PLMicrophoneSource *)source {
    if (self.microphoneSource.isRunning) {
        [self.microphoneSource stopRunning];
    }
    [self initMicophoneSourceWithCompletionHandler:nil];
    [self.streamingSession stop];
    if (self.isRunning) {
        [self.microphoneSource startRunning];
    }
    [self.streamingSession startWithCompleted:^(BOOL success) {
        if (!success) {
            NSError *error = [NSError errorWithDomain:PLReconnectErrorDomain code:PLCameraErroTryReconnectFailed userInfo:nil];
            if ([self.delegate respondsToSelector:@selector(cameraStreamingSession:didDisconnectWithError:)]) {
                [self.delegate cameraStreamingSession:self didDisconnectWithError:error];
            }
        }
    }];
}

#pragma mark -

- (void)previewViewTaped:(UITapGestureRecognizer *)tap {
    UIView *view = tap.view;
    CGPoint location = [tap locationInView:view];
    CGPoint focusPoint = (CGPoint){location.x / CGRectGetWidth(view.frame), location.y / CGRectGetHeight(view.frame)};
    
    self.focusPointOfInterest = focusPoint;
}

#pragma mark - Property

- (CGFloat)threshold {
    return self.streamingSession.threshold;
}

- (void)setThreshold:(CGFloat)threshold {
    [self willChangeValueForKey:@"threshold"];
    self.streamingSession.threshold = threshold;
    [self didChangeValueForKey:@"threshold"];
}

- (NSUInteger)maxCount {
    return self.streamingSession.maxCount;
}

- (void)setMaxCount:(NSUInteger)maxCount {
    [self willChangeValueForKey:@"maxCount"];
    self.streamingSession.maxCount = maxCount;
    [self didChangeValueForKey:@"maxCount"];
}

- (NSUInteger)currentCount {
    return self.streamingSession.currentCount;
}

- (PLStream *)stream {
    return self.streamingSession.stream;
}

- (void)setStream:(PLStream *)stream {
    [self willChangeValueForKey:@"stream"];
    
    self.streamingSession.stream = stream;
    
    [self didChangeValueForKey:@"stream"];
}

- (UIView *)previewView {
    if (self.isTouchToFocusEnable && !self.tapGestureRecognizer) {
        self.cameraSource.previewView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewViewTaped:)];
        [self.cameraSource.previewView addGestureRecognizer:tap];
        self.tapGestureRecognizer = tap;
    }
    return self.cameraSource.previewView;
}

- (void)setTouchToFocusEnable:(BOOL)touchToFocusEnable {
    [self willChangeValueForKey:@"touchToFocusEnable"];
    
    _touchToFocusEnable = touchToFocusEnable;
    if (touchToFocusEnable && !self.tapGestureRecognizer && self.previewView) {
        self.previewView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewViewTaped:)];
        [self.previewView addGestureRecognizer:tap];
        self.tapGestureRecognizer = tap;
    } else if (touchToFocusEnable && self.tapGestureRecognizer) {
        self.tapGestureRecognizer.enabled = YES;
    } else if (!touchToFocusEnable && self.tapGestureRecognizer) {
        self.tapGestureRecognizer.enabled = NO;
    }
    
    [self didChangeValueForKey:@"touchToFocusEnable"];
}

- (void)setCaptureDevicePosition:(AVCaptureDevicePosition)captureDevicePosition {
    [self willChangeValueForKey:@"captureDevicePosition"];
    self.cameraSource.cameraPosition = captureDevicePosition;
    _captureDevicePosition = self.cameraSource.cameraPosition;
    [self didChangeValueForKey:@"captureDevicePosition"];
}

- (BOOL)isTorchOn {
    return self.cameraSource.isTorchOn;
}

- (void)setTorchOn:(BOOL)torchOn {
    [self willChangeValueForKey:@"torchOn"];
    self.cameraSource.torchOn = torchOn;
    [self didChangeValueForKey:@"torchOn"];
}

- (void)setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation {
    [self willChangeValueForKey:@"videoOrientation"];
    _videoOrientation = videoOrientation;
    self.cameraSource.videoOrientation = videoOrientation;
    [self didChangeValueForKey:@"videoOrientation"];
}

- (void)setFocusPointOfInterest:(CGPoint)focusPointOfInterest {
    [self willChangeValueForKey:@"focusPointOfInterest"];
    _focusPointOfInterest = focusPointOfInterest;
    self.cameraSource.focusPointOfInterest = focusPointOfInterest;
    [self didChangeValueForKey:@"focusPointOfInterest"];
}

- (void)setContinuousAutofocusEnable:(BOOL)continuousAutofocusEnable {
    [self willChangeValueForKey:@"continuousAutofocusEnable"];
    _continuousAutofocusEnable = continuousAutofocusEnable;
    self.cameraSource.continuousAutofocusEnable = continuousAutofocusEnable;
    [self didChangeValueForKey:@"continuousAutofocusEnable"];
}

- (void)setMuted:(BOOL)muted {
    [self willChangeValueForKey:@"muted"];
    _muted = muted;
    self.microphoneSource.muted = muted;
    [self didChangeValueForKey:@"muted"];
}

- (void)setInputGain:(float)inputGain {
    self.microphoneSource.inputGain = inputGain;
}

- (float)inputGain {
    return self.microphoneSource.inputGain;
}

- (BOOL)isSmoothAutoFocusEnabled {
    return self.cameraSource.isSmoothAutoFocusEnabled;
}

- (void)setSmoothAutoFocusEnabled:(BOOL)smoothAutoFocusEnabled {
    self.cameraSource.smoothAutoFocusEnabled = smoothAutoFocusEnabled;
}

- (BOOL)isRunning {
    return self.streamingSession.isRunning;
}

- (PLStreamState)streamState {
    return self.streamingSession.streamState;
}

- (NSTimeInterval)statusUpdateInterval {
    return self.streamingSession.statusUpdateInterval;
}

- (void)setStatusUpdateInterval:(NSTimeInterval)statusUpdateInterval {
    [self willChangeValueForKey:@"statusUpdateInterval"];
    self.streamingSession.statusUpdateInterval = statusUpdateInterval;
    [self didChangeValueForKey:@"statusUpdateInterval"];
}

- (CGFloat)videoZoomFactor {
    return self.cameraSource.videoZoomFactor;
}

- (void)setVideoZoomFactor:(CGFloat)videoZoomFactor {
    [self willChangeValueForKey:@"videoZoomFactor"];
    self.cameraSource.videoZoomFactor = videoZoomFactor;
    [self didChangeValueForKey:@"videoZoomFactor"];
}

- (NSArray<AVCaptureDeviceFormat *> *)videoFormats {
    return self.cameraSource.videoFormats;
}

- (AVCaptureDeviceFormat *)videoActiveFormat {
    return self.cameraSource.videoActiveFormat;
}

- (void)setVideoActiveFormat:(AVCaptureDeviceFormat *)videoActiveFormat {
    [self willChangeValueForKey:@"videoActiveFormat"];
    self.cameraSource.videoActiveFormat = videoActiveFormat;
    [self didChangeValueForKey:@"videoActiveFormat"];
}

- (void)setFillMode:(PLVideoFillModeType)fillMode {
    [self willChangeValueForKey:@"fillMode"];
    self.cameraSource.previewView.fillMode = (GPUImageFillModeType)fillMode;
    [self willChangeValueForKey:@"fillMode"];
}

- (void)setIdleTimerDisable:(BOOL)idleTimerDisable {
    self.streamingSession.idleTimerDisable = idleTimerDisable;
}

- (BOOL)isIdleTimerDisable {
    return self.streamingSession.isIdleTimerDisable;
}

#pragma mark - RTMP Operations

- (void)startWithCompleted:(void (^)(BOOL success))handler {
    if (self.streamingSession.isRunning) {
        return;
    }
    
    [self.streamingSession startWithCompleted:^(BOOL success) {
        if (success) {
            [self makeIdleTimerDisableEffect];
            
            if (!self.microphoneSource.isRunning) {
                [self.microphoneSource startRunning];
            }
        }
        handler(success);
    }];
}

- (void)restartWithCompleted:(void (^)(BOOL success))handler {
    if (!self.streamingSession.isRunning) {
        return;
    }
    
    [self.streamingSession restartWithCompleted:handler];
}

#pragma mark - Category (CameraSource)

- (void)toggleCamera {
    [self.cameraSource toggleCamera];
}

- (void)startCaptureSession {
    [self.cameraSource startRunning];
}

- (void)stopCaptureSession {
    [self.cameraSource stopRunning];
}

#pragma mark - Categroy (Application)

- (void)makeIdleTimerDisableEffect {
    _cachedIdleTimerDisable = [UIApplication sharedApplication].isIdleTimerDisabled;
    [UIApplication sharedApplication].idleTimerDisabled = self.idleTimerDisable;
}

- (void)restoreIdleTimerDisable {
    [UIApplication sharedApplication].idleTimerDisabled = _cachedIdleTimerDisable;
}

#pragma mark - Category (Authorization)

+ (PLAuthorizationStatus)cameraAuthorizationStatus {
    return [PLCameraSource deviceAuthorizationStatus];
}

+ (void)requestCameraAccessWithCompletionHandler:(void (^)(BOOL granted))handler {
    [PLCameraSource requestDeviceAccessWithCompletionHandler:handler];
}

+ (PLAuthorizationStatus)microphoneAuthorizationStatus {
    return [PLMicrophoneSource deviceAuthorizationStatus];
}

+ (void)requestMicrophoneAccessWithCompletionHandler:(void (^)(BOOL granted))handler {
    [PLMicrophoneSource requestDeviceAccessWithCompletionHandler:handler];
}

#pragma mark - Category (Processing)

- (PLFilterHandler)addGPUImageFilter:(GPUImageFilter *)GPUFilter {
    PLGPUImageCameraFilter *filter = [[PLGPUImageCameraFilter alloc] initWithGPUImageFilter:GPUFilter];
    [self.cameraSource addFilter:filter];
    NSUInteger handlerNumber = 0;
    while ([self.filters objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)handlerNumber]]) {
        handlerNumber ++;
    }
    [self.filters setObject:filter forKey:[NSString stringWithFormat:@"%lu", (unsigned long)handlerNumber]];
    return [NSNumber numberWithUnsignedInteger:handlerNumber];
}

- (void)removeFilter:(PLFilterHandler)handler {
    NSUInteger handlerNumber = [handler unsignedIntegerValue];
    PLCameraFilter *filter = [self.filters objectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)handlerNumber]];
    if (filter) {
        [self.cameraSource removeFilter:filter];
        [self.filters removeObjectForKey:[NSString stringWithFormat:@"%lu", (unsigned long)handlerNumber]];
    }
}

@end
