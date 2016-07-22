//
//  PLCameraStreamingViewController.m
//  PLCameraStreamingKit
//
//  Created on 01/10/2015.
//  Copyright (c) Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "PLViewController.h"
#import "Reachability.h"
#import "GPUImageBeautifyFilter.h"
#import "GPUImageSepiaFilter.h"
#import <asl.h>
#import <PLCameraStreamingKit/PLCameraStreamingKit.h>

const char *stateNames[] = {
    "Unknow",
    "Connecting",
    "Connected",
    "Disconnecting",
    "Disconnected",
    "Error"
};

const char *networkStatus[] = {
    "Not Reachable",
    "Reachable via WiFi",
    "Reachable via CELL"
};

#define kReloadConfigurationEnable  0

// 假设在 videoFPS 低于预期 50% 的情况下就触发降低推流质量的操作，这里的 40% 是一个假定数值，你可以更改数值来尝试不同的策略
#define kMaxVideoFPSPercent 0.5

// 假设当 videoFPS 在 10s 内与设定的 fps 相差都小于 5% 时，就尝试调高编码质量
#define kMinVideoFPSPercent 0.05
#define kHigherQualityTimeInterval  10

#define kBrightnessAdjustRatio  1.03
#define kSaturationAdjustRatio  1.03

@interface PLViewController ()
<
PLCameraStreamingSessionDelegate,
PLStreamingSendingBufferDelegate
>

@property (nonatomic, strong) PLCameraStreamingSession  *session;
@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) NSArray<PLVideoCaptureConfiguration *>   *videoCaptureConfigurations;
@property (nonatomic, strong) NSArray<PLVideoStreamingConfiguration *>   *videoStreamingConfigurations;
@property (nonatomic, strong) NSDate    *keyTime;
@property (nonatomic , assign) BOOL bBeautify;
@property (nonatomic , strong) UIImageView *mImageView;
@end

@implementation PLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds) / 2, CGRectGetHeight(self.view.bounds) / 2)];
    [self.view addSubview:_mImageView];
    
    /*
     我用的是七牛的sdk 其他的配置都差不多，就是加滤镜的时候比较头疼。七牛已经给出接口。我是在这个控制器的最下方实现的这个方法。大神帮忙看一下，感激不尽。只能真机运行，麻烦大神了
     
     
     而且加的滤镜只能在用户端可以看见，我自己这边手机端并没有显示出来
     */
    
    
    // 预先设定几组编码质量，之后可以切换
    CGSize videoSize = CGSizeMake(480 , 640);
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation <= AVCaptureVideoOrientationLandscapeLeft) {
        if (orientation > AVCaptureVideoOrientationPortraitUpsideDown) {
            videoSize = CGSizeMake(640 , 480);
        }
    }
    self.videoStreamingConfigurations = @[
                                 [[PLVideoStreamingConfiguration alloc] initWithVideoSize:videoSize expectedSourceVideoFrameRate:15 videoMaxKeyframeInterval:45 averageVideoBitRate:800 * 1000 videoProfileLevel:AVVideoProfileLevelH264Baseline31],
                                 [[PLVideoStreamingConfiguration alloc] initWithVideoSize:CGSizeMake(800 , 480) expectedSourceVideoFrameRate:24 videoMaxKeyframeInterval:72 averageVideoBitRate:800 * 1000 videoProfileLevel:AVVideoProfileLevelH264Baseline31],
                                 [[PLVideoStreamingConfiguration alloc] initWithVideoSize:videoSize expectedSourceVideoFrameRate:30 videoMaxKeyframeInterval:90 averageVideoBitRate:800 * 1000 videoProfileLevel:AVVideoProfileLevelH264Baseline31],
                                 ];
    self.videoCaptureConfigurations = @[
                                        [[PLVideoCaptureConfiguration alloc] initWithVideoFrameRate:15 sessionPreset:AVCaptureSessionPresetiFrame960x540 previewMirrorFrontFacing:YES previewMirrorRearFacing:NO streamMirrorFrontFacing:YES streamMirrorRearFacing:NO cameraPosition:AVCaptureDevicePositionFront videoOrientation:AVCaptureVideoOrientationPortrait],
                                        [[PLVideoCaptureConfiguration alloc] initWithVideoFrameRate:24 sessionPreset:AVCaptureSessionPresetiFrame960x540 previewMirrorFrontFacing:YES previewMirrorRearFacing:NO streamMirrorFrontFacing:YES streamMirrorRearFacing:NO cameraPosition:AVCaptureDevicePositionFront videoOrientation:AVCaptureVideoOrientationPortrait],
                                        [[PLVideoCaptureConfiguration alloc] initWithVideoFrameRate:30 sessionPreset:AVCaptureSessionPresetiFrame960x540 previewMirrorFrontFacing:YES previewMirrorRearFacing:NO streamMirrorFrontFacing:YES streamMirrorRearFacing:NO cameraPosition:AVCaptureDevicePositionFront videoOrientation:AVCaptureVideoOrientationPortrait]
                                        ];
    self.sessionQueue = dispatch_queue_create("pili.queue.streaming", DISPATCH_QUEUE_SERIAL);
    
    // 网络状态监控
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
    
    // PLCameraStreamingKit 使用开始
    //
    // streamJSON 是从服务端拿回的
    //
    // 从服务端拿回的 streamJSON 结构如下：
    //    @{@"id": @"stream_id",
    //      @"title": @"stream_title",
    //      @"hub": @"hub_name",
    //      @"publishKey": @"publish_key",
    //      @"publishSecurity": @"dynamic", // or static
    //      @"disabled": @(NO),
    //      @"profiles": @[@"480p", @"720p"],    // or empty Array []
    //      @"hosts": @{
    //              ...
    //      }
#warning 如果要运行 demo 这里应该填写服务端返回的某个流的 json 信息

//    NSString *setting=[NSString stringWithFormat:@"{\"id\": \"\",\"hub\": \"live\",\"title\": \"%@\",\"publishKey\": \"b06c7427b454762e\",\"publishSecurity\": \"dynamic\",\"hosts\" : {\"publish\" : {\"rtmp\"   : \"%@\"},\"play\"    : {\"rtmp\"   : \"%@\"}}}",@"65082911nowfc",@"192.168.1.144",@"192.168.1.144"];
//    NSError *error;
//    NSDictionary *streamJSON = [NSJSONSerialization JSONObjectWithData:[setting dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
//    
//    PLStream *stream = [PLStream streamWithJSON:streamJSON];
    PLStream *stream = nil;
    
    void (^permissionBlock)(void) = ^{
        dispatch_async(self.sessionQueue, ^{
            PLVideoCaptureConfiguration *videoCaptureConfiguration = [self.videoCaptureConfigurations lastObject];
            PLAudioCaptureConfiguration *audioCaptureConfiguration = [PLAudioCaptureConfiguration defaultConfiguration];
            // 视频编码配置
            PLVideoStreamingConfiguration *videoStreamingConfiguration = [self.videoStreamingConfigurations lastObject];
            // 音频编码配置
            PLAudioStreamingConfiguration *audioStreamingConfiguration = [PLAudioStreamingConfiguration defaultConfiguration];
            AVCaptureVideoOrientation orientation = (AVCaptureVideoOrientation)(([[UIDevice currentDevice] orientation] <= UIDeviceOrientationLandscapeRight && [[UIDevice currentDevice] orientation] != UIDeviceOrientationUnknown) ? [[UIDevice currentDevice] orientation]: UIDeviceOrientationPortrait);
            // 推流 session
            self.session = [[PLCameraStreamingSession alloc] initWithVideoCaptureConfiguration:videoCaptureConfiguration audioCaptureConfiguration:audioCaptureConfiguration videoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration stream:stream videoOrientation:orientation];
            self.session.delegate = self;
            self.session.bufferDelegate = self;
            UIImage *waterMark = [UIImage imageNamed:@"qiniu.png"];
            [self.session setWaterMarkWithImage:waterMark position:CGPointMake(100, 300)];
            dispatch_async(dispatch_get_main_queue(), ^{
                UIView *previewView = self.session.previewView;
                previewView.autoresizingMask = UIViewAutoresizingFlexibleHeight| UIViewAutoresizingFlexibleWidth;
                [self.view insertSubview:previewView atIndex:0];
                self.zoomSlider.minimumValue = 1;
                self.zoomSlider.maximumValue = MIN(5, self.session.videoActiveFormat.videoMaxZoomFactor);
                
                NSString *log = [NSString stringWithFormat:@"Zoom Range: [1..%.0f]", self.session.videoActiveFormat.videoMaxZoomFactor];
                NSLog(@"%@", log);
                self.textView.text = [NSString stringWithFormat:@"%@\%@", self.textView.text, log];
            });
        });
    };
    
    void (^noAccessBlock)(void) = ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Access", nil)
                                                            message:NSLocalizedString(@"!", nil)
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                  otherButtonTitles:nil];
        [alertView show];
    };
    
    switch ([PLCameraStreamingSession cameraAuthorizationStatus]) {
        case PLAuthorizationStatusAuthorized:
            permissionBlock();
            break;
        case PLAuthorizationStatusNotDetermined: {
            [PLCameraStreamingSession requestCameraAccessWithCompletionHandler:^(BOOL granted) {
                granted ? permissionBlock() : noAccessBlock();
            }];
        }
            break;
        default:
            noAccessBlock();
            break;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    dispatch_sync(self.sessionQueue, ^{
        [self.session destroy];
    });
    self.session = nil;
    self.sessionQueue = nil;
}

#pragma mark - Notification Handler

- (void)reachabilityChanged:(NSNotification *)notif{
    Reachability *curReach = [notif object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    NetworkStatus status = [curReach currentReachabilityStatus];
    
    if (NotReachable == status) {
        // 对断网情况做处理
        [self stopSession];
    }
    
    NSString *log = [NSString stringWithFormat:@"Networkt Status: %s", networkStatus[status]];
    NSLog(@"%@", log);
    self.textView.text = [NSString stringWithFormat:@"%@\%@", self.textView.text, log];
}

- (void)handleInterruption:(NSNotification *)notification {
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        NSLog(@"Interruption notification");
        
        if ([[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] isEqualToNumber:[NSNumber numberWithInt:AVAudioSessionInterruptionTypeBegan]]) {
            NSLog(@"InterruptionTypeBegan");
        } else {
            // the facetime iOS 9 has a bug: 1 does not send interrupt end 2 you can use application become active, and repeat set audio session acitve until success.  ref http://blog.corywiles.com/broken-facetime-audio-interruptions-in-ios-9
            NSLog(@"InterruptionTypeEnded");
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setActive:YES error:nil];
        }
    }
}

#pragma mark - <PLStreamingSendingBufferDelegate>

- (void)streamingSessionSendingBufferDidFull:(id)session {
    NSString *log = @"Buffer is full";
    NSLog(@"%@", log);
    self.textView.text = [NSString stringWithFormat:@"%@\%@", self.textView.text, log];
}

- (void)streamingSession:(id)session sendingBufferDidDropItems:(NSArray *)items {
    NSString *log = @"Frame dropped";
    NSLog(@"%@", log);
    self.textView.text = [NSString stringWithFormat:@"%@\%@", self.textView.text, log];
}

#pragma mark - <PLCameraStreamingSessionDelegate>

- (void)cameraStreamingSession:(PLCameraStreamingSession *)session streamStateDidChange:(PLStreamState)state {
    NSString *log = [NSString stringWithFormat:@"Stream State: %s", stateNames[state]];
    NSLog(@"%@", log);
    self.textView.text = [NSString stringWithFormat:@"%@\%@", self.textView.text, log];
    
    // 除 PLStreamStateError 外的其余状态会回调在这个方法
    // 这个回调会确保在主线程，所以可以直接对 UI 做操作
    if (PLStreamStateConnected == state) {
        [self.actionButton setTitle:NSLocalizedString(@"Stop", nil) forState:UIControlStateNormal];
    } else if (PLStreamStateDisconnected == state) {
        [self.actionButton setTitle:NSLocalizedString(@"Start", nil) forState:UIControlStateNormal];
    }
}

- (void)cameraStreamingSession:(PLCameraStreamingSession *)session didDisconnectWithError:(NSError *)error {
    NSString *log = [NSString stringWithFormat:@"Stream State: Error. %@", error];
    NSLog(@"%@", log);
    self.textView.text = [NSString stringWithFormat:@"%@\%@", self.textView.text, log];
    // PLStreamStateError 都会回调在这个方法
    // 尝试重连，注意这里需要你自己来处理重连尝试的次数以及重连的时间间隔
    [self.actionButton setTitle:NSLocalizedString(@"Reconnecting", nil) forState:UIControlStateNormal];
    [self startSession];
}

- (void)cameraStreamingSession:(PLCameraStreamingSession *)session streamStatusDidUpdate:(PLStreamStatus *)status {
    NSString *log = [NSString stringWithFormat:@"%@", status];
 
    NSLog(@"%@",log);
    NSLog(@"%.1f", status.totalBitrate / 1000);
    self.textView.text = [NSString stringWithFormat:@"%@\%@", self.textView.text, log];
    
#if kReloadConfigurationEnable
    NSDate *now = [NSDate date];
    if (!self.keyTime) {
        self.keyTime = now;
    }
    
    double expectedVideoFPS = (double)self.session.videoConfiguration.videoFrameRate;
    double realtimeVideoFPS = status.videoFPS;
    if (realtimeVideoFPS < expectedVideoFPS * (1 - kMaxVideoFPSPercent)) {
        // 当得到的 status 中 video fps 比设定的 fps 的 50% 还小时，触发降低推流质量的操作
        self.keyTime = now;
        
        [self lowerQuality];
    } else if (realtimeVideoFPS >= expectedVideoFPS * (1 - kMinVideoFPSPercent)) {
        if (-[self.keyTime timeIntervalSinceNow] > kHigherQualityTimeInterval) {
            self.keyTime = now;
            
            [self higherQuality];
        }
    }
#endif  // #if kReloadConfigurationEnable
}

#pragma mark -

- (void)higherQuality {
    NSUInteger idx = [self.videoStreamingConfigurations indexOfObject:self.session.videoStreamingConfiguration];
    NSAssert(idx != NSNotFound, @"Oops");
    
    if (idx >= self.videoStreamingConfigurations.count - 1) {
        return;
    }
    PLVideoStreamingConfiguration *newStreamingConfiguration = self.videoStreamingConfigurations[idx + 1];
    PLVideoCaptureConfiguration *newCaptureConfiguration = self.videoCaptureConfigurations[idx + 1];
    [self.session reloadVideoStreamingConfiguration:newStreamingConfiguration videoCaptureConfiguration:newCaptureConfiguration];
}

- (void)lowerQuality {
    NSUInteger idx = [self.videoStreamingConfigurations indexOfObject:self.session.videoStreamingConfiguration];
    NSAssert(idx != NSNotFound, @"Oops");
    
    if (0 == idx) {
        return;
    }
    PLVideoStreamingConfiguration *newStreamingConfiguration = self.videoStreamingConfigurations[idx - 1];
    PLVideoCaptureConfiguration *newCaptureConfiguration = self.videoCaptureConfigurations[idx - 1];
    [self.session reloadVideoStreamingConfiguration:newStreamingConfiguration videoCaptureConfiguration:newCaptureConfiguration];
}

#pragma mark - Operation

- (void)stopSession {
    dispatch_async(self.sessionQueue, ^{
        self.keyTime = nil;
        [self.session stop];
    });
}

- (void)startSession {
    self.keyTime = nil;
    self.actionButton.enabled = NO;
    dispatch_async(self.sessionQueue, ^{
        [self.session startWithCompleted:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.actionButton.enabled = YES;
            });
        }];
    });
}

#pragma mark - Action

- (IBAction)segmentedControlValueDidChange:(id)sender {
    PLVideoCaptureConfiguration *videoCaptureConfiguration = self.videoCaptureConfigurations[self.segementedControl.selectedSegmentIndex];

    [self.session reloadVideoStreamingConfiguration:self.session.videoStreamingConfiguration videoCaptureConfiguration:videoCaptureConfiguration];
}

- (IBAction)zoomSliderValueDidChange:(id)sender {
    self.session.videoZoomFactor = self.zoomSlider.value;
}

- (IBAction)actionButtonPressed:(id)sender {
    if (PLStreamStateConnected == self.session.streamState) {
        [self stopSession];
    } else {
        [self startSession];
    }
}

- (IBAction)toggleCameraButtonPressed:(id)sender {
    dispatch_async(self.sessionQueue, ^{
        [self.session toggleCamera];
    });
}

- (IBAction)torchButtonPressed:(id)sender {
    self.bBeautify = !self.bBeautify;
    dispatch_async(self.sessionQueue, ^{
        self.session.torchOn = !self.session.isTorchOn;
    });
}

- (IBAction)muteButtonPressed:(id)sender {
    dispatch_async(self.sessionQueue, ^{
        self.session.muted = !self.session.isMuted;
    });
}

- (IBAction)cancelButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

//#define CIImageDefine 1

#pragma mark   ---------- 加滤镜  ----------
- (CVPixelBufferRef)cameraStreamingSession:(PLCameraStreamingSession *)session cameraSourceDidGetPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    if (!self.bBeautify) {
        return pixelBuffer;
    }
    else {
#ifdef CIImageDefine
        CIContext *context = [CIContext contextWithEAGLContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
        CIImage *image = [CIImage imageWithCVImageBuffer:pixelBuffer];
        
        
//        CIFilter *filter = [CIFilter filterWithName:@"CIHueAdjust" withInputParameters:@{kCIInputImageKey: image,
//                                                                                         kCIInputAngleKey: @(15.0 / 180 * M_PI)}];
        
        CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone" keysAndValues: kCIInputImageKey,image, @"inputIntensity", @0.8, nil];
        
        CIImage *outImage = [filter valueForKey:kCIOutputImageKey];
        [self.mImageView setImage:[UIImage imageWithCIImage:outImage]];
        
        [context render:outImage
             toCVPixelBuffer:pixelBuffer];
        return pixelBuffer;
#endif
    }
    
    /*
     大体的思路就是 CVPixelBufferRef 转到 CGImageRef 再转 GPUImagePicture  然后加滤镜，再转成UIImage 然后就是 CGImageRef  再到 CVPixelBufferRef。最后return CVPixelBufferRef
     
     */
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    size_t bytePerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t bitPerCompoment = 8;
    size_t bitPerPixel = 4 * bitPerCompoment;
    size_t length = CVPixelBufferGetDataSize(pixelBuffer);
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    unsigned char *imageData = (unsigned char *)malloc(length);
    memcpy(imageData, baseAddress, length);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    [self.class convertBGRAtoRGBA:imageData withSize:length];
    CFDataRef data = CFDataCreate(NULL, imageData, length);
    free(imageData);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef image = CGImageCreate(width, height, bitPerCompoment, bitPerPixel, bytePerRow, colorSpace, bitmapInfo, provider, NULL, NULL, kCGRenderingIntentDefault);
    
    CFRelease(data);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    
    CVPixelBufferRef ret;
    GPUImagePicture *picture = [[GPUImagePicture alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    GPUImageSepiaFilter *filter = [[GPUImageSepiaFilter alloc] init];    
    [picture addTarget:filter];
    [picture processImage];
    
    [filter useNextFrameForImageCapture];
    
    UIImage *imageSecond = [filter imageFromCurrentFramebuffer];
    //  imageSecond  有时候会变成空的
    if (!imageSecond) {
        NSLog(@"error");
        return pixelBuffer;
    }
    else {
        [self.mImageView setImage:imageSecond];
    }
    
    CGImageRef imageThird = [imageSecond CGImage];
    
    
    ret = [self pixelBufferFromCGImage:imageThird];
    if (!ret) {
        ret = pixelBuffer;
    }
    else {
        CFRelease(ret);
    }
    
    
    return ret;
}

+ (void)convertBGRAtoRGBA:(unsigned char *)data withSize:(size_t)sizeOfData {
    for (unsigned char *p = data; p < data + sizeOfData; p += 4) {
        unsigned char r = *(p + 2);
        unsigned char b = *p;
        *p = r;
        *(p + 2) = b;
    }
}

- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSLog(@"%d",status);

    // 如果status返回的不是0  那么就会出错
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

@end
