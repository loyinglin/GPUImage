//
//  PLMicrophoneSource.m
//  PLCameraStreamingKit
//
//  Created by 0day on 15/3/26.
//  Copyright (c) 2015年 qgenius. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import "PLMicrophoneSource.h"
#import "PLCameraStreamingSession.h"

#define kPLMaxTryRestartCount   3
#define kPLTryRestartInterval   0.5

NSString *const PLTryRestartAudioDomain = @"pili.error.restart.audio";
NSString *PLAudioComponentFailedToCreateNotification = @"PLAudioComponentFailedToCreateNotification";

static BOOL CheckStatus(OSStatus status, NSString *message, BOOL fatal)
{
    if(status != noErr)
    {
        char fourCC[16];
        *(UInt32 *)fourCC = CFSwapInt32HostToBig(status);
        fourCC[4] = '\0';
        
        if(isprint(fourCC[0]) && isprint(fourCC[1]) && isprint(fourCC[2]) && isprint(fourCC[3]))
            NSLog(@"%@: %s", message, fourCC);
        else
            NSLog(@"%@: %d", message, (int)status);
        
        if(fatal)
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:message
                                         userInfo:nil];
        return NO;
    } else {
        return YES;
    }
}

@interface PLMicrophoneSource ()

@property (nonatomic, assign) AudioComponentInstance    componetInstance;
@property (nonatomic, assign) AudioComponent            component;
@property (nonatomic, assign) uint64_t tsBase;
@property (nonatomic, strong) dispatch_queue_t       taskQueue;
@property (nonatomic, assign) NSInteger channelsPerFrame;   // rewrite
@property (nonatomic, assign) BOOL isRunning;   // rewrite
@property (nonatomic, assign, readwrite) PLAudioCaptureConfiguration *audioCaptureConfiguration;
@property (nonatomic, assign) NSUInteger tryRestartCount;

@end

static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        PLMicrophoneSource *source = (__bridge PLMicrophoneSource *)inRefCon;
        __block OSStatus status = noErr;
        AudioBuffer buffer;
        
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 1;
        
        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;
        
        status = AudioUnitRender(source.componetInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &buffers);
        if (!CheckStatus(status, @"error AudioUnitRender", NO)) {
            return status;
        }
        
        if (!source.isRunning) {
            dispatch_async(source.taskQueue, ^{
                NSLog(@"MicrophoneSource: stopRunning");
                status = AudioOutputUnitStop(source.componetInstance);
                CheckStatus(status, @"error AudioUnitRender", NO);
            });
            
            return status;
        }
        if (source.isMuted) {
            for (int i = 0; i < buffers.mNumberBuffers; i++) {
                AudioBuffer ab = buffers.mBuffers[i];
                memset(ab.mData, 0, ab.mDataByteSize);
            }
        }
        
        if(!status) {
            AudioBuffer audioBuffer = buffers.mBuffers[0];
            if ([source.delegate respondsToSelector:@selector(microphoneSource:didGetAudioBuffer:)]) {
                [source.delegate microphoneSource:source didGetAudioBuffer:&audioBuffer];
            }
        }
        return status;
    }
}

@implementation PLMicrophoneSource
@synthesize captureASBD = _captureASBD, inputGain = _inputGain;

+ (AVAudioSession *)sharedSession {
    static dispatch_once_t t;
    static AVAudioSession *session;
    dispatch_once(&t, ^{
        session = [[AVAudioSession alloc] init];
    });
    return session;
}

- (instancetype)initWithAudioCaptureConfiguration:(PLAudioCaptureConfiguration *)audioCaptureConfiguration {
    self = [super init];
    if (self) {
        self.audioCaptureConfiguration = audioCaptureConfiguration;
        self.channelsPerFrame = audioCaptureConfiguration.channelsPerFrame;
        self.isRunning = NO;
        self.muted = NO;
        self.taskQueue = dispatch_queue_create("microphone_queue", NULL);
        self.tsBase = 0;
        _inputGain = 0;
        _tryRestartCount = 0;
        
        [self setupAudioSession];
        
        [self setupCaptureASBD];
        
        [self addObservers];
        
        [self setupAudioComponent];
    }
    return self;
}

- (void)dealloc {
    __block OSStatus status = noErr;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self stopRunning];
    
    if (_captureASBD) {
        free(_captureASBD);
        _captureASBD = NULL;
    }
    
    dispatch_sync(self.taskQueue, ^{
        status = AudioComponentInstanceDispose(self.componetInstance);
        CheckStatus(status, @"error AudioComponentInstanceDispose", NO);
        
        self.componetInstance = nil;
        self.component = nil;
        NSError *sessionError = nil;
        [[PLMicrophoneSource sharedSession] setActive:NO error:&sessionError];
        if (sessionError) {
            NSLog(@"%ld, deactivate session error : %@",sessionError.code, sessionError.localizedDescription);
        }
    });
}

- (void)startRunning {
    if (self.isRunning) {
        return;
    }
    dispatch_async(self.taskQueue, ^{
        if ([self resetAudioSession] && [self checkSampleRate]) {
            OSStatus status = AudioOutputUnitStart(self.componetInstance);
            if (CheckStatus(status, @"error AudioOutputUnitStart", NO)) {
                NSLog(@"MicrophoneSource: startRunning");
            }
            self.isRunning = YES;
        }
    });
}

- (void)stopRunning {
    if (!self.isRunning) {
        return;
    }
    __block OSStatus status = noErr;
    if (dispatch_get_current_queue() == self.taskQueue) {
        status = AudioOutputUnitStop(self.componetInstance);
        if (CheckStatus(status, @"error AudioOutputUnitStop", NO)) {
            NSLog(@"MicrophoneSource: stopRunning");
        }
        self.isRunning = NO;
    } else {
        dispatch_sync(self.taskQueue, ^{
            status = AudioOutputUnitStop(self.componetInstance);
            if (CheckStatus(status, @"error AudioOutputUnitStop", NO)) {
                NSLog(@"MicrophoneSource: stopRunning");
            }
            self.isRunning = NO;
        });
    }
}

#pragma mark - setters and getters

- (void)setInputGain:(float)inputGain {
    if ([PLMicrophoneSource sharedSession].inputGainSettable) {
        _inputGain = inputGain;
        NSError *sessionError = nil;
        [[PLMicrophoneSource sharedSession] setInputGain:inputGain error:&sessionError];
        if (sessionError) {
            NSLog(@"%ld, set input gain error : %@", sessionError.code, sessionError.localizedDescription);
        } else {
            NSLog(@"input gain has been set to : %.2f", inputGain);
        }
    } else {
        NSLog(@"input gain not settable");
    }
}

#pragma mark -

- (void)handleAudioComponentCreationFailure {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PLAudioComponentFailedToCreateNotification object:nil];
    });
}

- (void)handleMediaServicesWereReset:(NSNotification *)notification {
    //  If the media server resets for any reason, handle this notification to reconfigure audio or do any housekeeping, if necessary
    //    • No userInfo dictionary for this notification
    //      • Audio streaming objects are invalidated (zombies)
    //      • Handle this notification by fully reconfiguring audio
    if ([self.delegate respondsToSelector:@selector(microphoneSourceMediaServicesWereReset:)]) {
        [self.delegate microphoneSourceMediaServicesWereReset:self];
    }
    NSLog(@"handleMediaServicesWereReset: %@ ",[notification name]);
}

- (void)handleApplicationActive:(NSNotification *)notification {
    // use this notification to handle session interruption end
    NSLog(@"session active");
    if (self.isRunning) {
        dispatch_async(self.taskQueue, ^{
            [self tryRestartCapture];
        });
    }
}

- (void)tryRestartCapture {
    if ([self resetAudioSession] && [self checkSampleRate])  {
        _tryRestartCount = 0;
        NSLog(@"MicrophoneSource: startRunning");
        AudioOutputUnitStart(self.componetInstance);
    } else if (_tryRestartCount < kPLMaxTryRestartCount){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPLTryRestartInterval * NSEC_PER_SEC)), self.taskQueue, ^{
            _tryRestartCount ++;
            [self tryRestartCapture];
        });
    } else {
        _tryRestartCount = 0;
        NSError *error = [NSError errorWithDomain:PLTryRestartAudioDomain code:PLCameraErroRestartAudioFailed userInfo:nil];
        [self.delegate microphoneSource:self tryRestartCaptureError:error];
    }
}


- (void)handleInterruption:(NSNotification *)notification {
    NSInteger reason = 0;
    NSString* reasonStr=@"";
    __block OSStatus status = noErr;
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        //Posted when an audio interruption occurs.
        reason = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan) {
            //       Audio has stopped, already inactive
            //       Change state of UI, etc., to reflect non-playing state
            reasonStr = @"AVAudioSessionInterruptionTypeBegan";
            if (self.isRunning) {
                dispatch_async(self.taskQueue, ^{
                    status = AudioOutputUnitStop(self.componetInstance);
                    if (CheckStatus(status, @"error AudioOutputUnitStop", NO)) {
                        NSLog(@"MicrophoneSource: stopRunning");
                    }
                });
            }
        }
        
        if (reason == AVAudioSessionInterruptionTypeEnded) {
            //       Make session active
            //       Update user interface
            //       AVAudioSessionInterruptionOptionShouldResume option
            reasonStr = @"AVAudioSessionInterruptionTypeEnded";
            if (self.isRunning) {
                dispatch_async(self.taskQueue, ^{
                    if ([self resetAudioSession] && [self checkSampleRate]) {
                        status = AudioOutputUnitStart(self.componetInstance);
                        if (CheckStatus(status, @"error AudioOutputUnitStart", NO)) {
                            NSLog(@"MicrophoneSource: startRunning");
                        }
                    }
                });
            }
            // not use this for interruption ended, use become active instead
        }
        NSLog(@"handleInterruption: %@ reason %@",[notification name], reasonStr);
    };
}

- (void)handleRouteChange:(NSNotification *)notification {
    NSString* seccReason = @"";
    NSInteger  reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (reason) {
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            if ([self resetAudioSession]) {
                [self checkSampleRate];
            }
            seccReason = @"The route changed because no suitable route is now available for the specified category.";
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            if ([self resetAudioSession]) {
                [self checkSampleRate];
            }
            seccReason = @"The route changed when the device woke up from sleep.";
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            if ([self resetAudioSession]) {
                [self checkSampleRate];
            }
            seccReason = @"The output route was overridden by the app.";
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            seccReason = @"The category of the session object changed.";
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            if ([self resetAudioSession]) {
                [self checkSampleRate];
            }
            seccReason = @"The previous audio output path is no longer available.";
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            if ([self resetAudioSession]) {
                [self checkSampleRate];
            }
            seccReason = @"A preferred new audio output path is now available.";
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
        default:
            seccReason = @"The reason for the change is unknown.";
            break;
    }
    NSLog(@"handleRouteChange: %@ reason %@",[notification name], seccReason);
}

- (BOOL)checkSampleRate {
    AVAudioSession *session = [PLMicrophoneSource sharedSession];
    if (session.sampleRate != session.preferredSampleRate) {
        NSLog(@"set preferredSampleRate to : %.2f", session.sampleRate);
        NSError *sessionError = nil;
        [session setPreferredSampleRate:session.sampleRate error:&sessionError];
        if (sessionError) {
            NSLog(@"%ld, set preferred sample rate error : %@", sessionError.code, sessionError.localizedDescription);
        }
        if ([self.delegate respondsToSelector:@selector(microphoneSourceHardwareSamplerateChanged:)]) {
            [self.delegate microphoneSourceHardwareSamplerateChanged:self];
        }
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)resetAudioSession {
    NSError *sessionError = nil;
    AVAudioSession *session = [PLMicrophoneSource sharedSession];
    
    [session setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation error:&sessionError];
    if (sessionError) {
        NSLog(@"%ld, set session active error : %@", sessionError.code, sessionError.localizedDescription);
        return NO;
    }
    
    // use bottom microphone for capture by default
    if (AVAudioSessionOrientationBottom != session.inputDataSource.orientation) {
        for (AVAudioSessionDataSourceDescription *dataSource in session.inputDataSources) {
            if (AVAudioSessionOrientationBottom == dataSource.orientation) {
                [session setInputDataSource:dataSource error:&sessionError];
                if (sessionError) {
                    NSLog(@"%ld, set input data source error : %@", sessionError.code, sessionError.localizedDescription);
                }
            }
        }
    }
    
    if (_inputGain) {
        if (session.inputGainSettable) {
            NSError *sessionError = nil;
            [session setInputGain:_inputGain error:&sessionError];
            if (sessionError) {
                NSLog(@"%ld, set input gain error : %@", sessionError.code, sessionError.localizedDescription);
            }
        }
    }
    return YES;
}

- (void)setupAudioSession {
    NSError *sessionError = nil;
    AVAudioSession *session = [PLMicrophoneSource sharedSession];
    
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth error:&sessionError];
    if (sessionError) {
        NSLog(@"%ld, set session category error : %@", sessionError.code, sessionError.localizedDescription);
        return;
    }
    
    [session setMode:AVAudioSessionModeVideoRecording error:&sessionError];
    if (sessionError) {
        NSLog(@"%ld, set session mode error : %@", sessionError.code, sessionError.localizedDescription);
        return;
    }
    
    [session setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation error:&sessionError];
    if (sessionError) {
        NSLog(@"%ld, set session active error : %@", sessionError.code, sessionError.localizedDescription);
        return;
    }
    
    [session setPreferredSampleRate:session.sampleRate error:&sessionError];
    if (sessionError) {
        NSLog(@"%ld, set preferred sample rate error : %@", sessionError.code, sessionError.localizedDescription);
        return;
    }
    
    // use bottom microphone for capture by default
    if (AVAudioSessionOrientationBottom != session.inputDataSource.orientation) {
        for (AVAudioSessionDataSourceDescription *dataSource in session.inputDataSources) {
            if (AVAudioSessionOrientationBottom == dataSource.orientation) {
                [session setInputDataSource:dataSource error:&sessionError];
                if (sessionError) {
                    NSLog(@"%ld, set input data source error : %@", sessionError.code, sessionError.localizedDescription);
                }
            }
        }
    }
    
    if (_inputGain) {
        if (session.inputGainSettable) {
            NSError *sessionError = nil;
            [session setInputGain:_inputGain error:&sessionError];
            if (sessionError) {
                NSLog(@"%ld, set input gain error : %@", sessionError.code, sessionError.localizedDescription);
            }
        }
    }
    return;
}

- (void)setupCaptureASBD {
    _captureASBD = calloc(1, sizeof(AudioStreamBasicDescription));
    _captureASBD->mSampleRate = [PLMicrophoneSource sharedSession].sampleRate;
    NSLog(@"set captured asbd to : %f", _captureASBD->mSampleRate);
    _captureASBD->mFormatID = kAudioFormatLinearPCM;
    _captureASBD->mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    _captureASBD->mChannelsPerFrame = (UInt32)self.channelsPerFrame;
    _captureASBD->mFramesPerPacket = 1;
    _captureASBD->mBitsPerChannel = 16;
    _captureASBD->mBytesPerFrame = _captureASBD->mBitsPerChannel / 8 * _captureASBD->mChannelsPerFrame;
    _captureASBD->mBytesPerPacket = _captureASBD->mBytesPerFrame * _captureASBD->mFramesPerPacket;
}

- (void)addObservers {
    AVAudioSession *session = [PLMicrophoneSource sharedSession];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleRouteChange:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: session];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleInterruption:)
                                                 name: AVAudioSessionInterruptionNotification
                                               object: session];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleMediaServicesWereReset:)
                                                 name: AVAudioSessionMediaServicesWereResetNotification
                                               object: session];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)setupAudioComponent {
    dispatch_async(self.taskQueue, ^{
        AudioComponentDescription acd;
        acd.componentType = kAudioUnitType_Output;
        acd.componentSubType = kAudioUnitSubType_RemoteIO;
        acd.componentManufacturer = kAudioUnitManufacturer_Apple;
        acd.componentFlags = 0;
        acd.componentFlagsMask = 0;
        
        self.component = AudioComponentFindNext(NULL, &acd);
        
        OSStatus status = noErr;
        status = AudioComponentInstanceNew(self.component, &_componetInstance);
        
        if (!CheckStatus(status, @"error AudioComponentInstanceNew", NO)) {
            [self handleAudioComponentCreationFailure];
            return;
        }
        
        UInt32 flagOne = 1;
        
        status = AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flagOne, sizeof(flagOne));
        CheckStatus(status, @"error set kAudioOutputUnitProperty_EnableIO", NO);
        
        AURenderCallbackStruct cb;
        cb.inputProcRefCon = (__bridge void *)(self);
        cb.inputProc = handleInputBuffer;
        status = AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &cb, sizeof(cb));
        CheckStatus(status, @"error set kAudioOutputUnitProperty_SetInputCallback", NO);
        
        status = AudioUnitSetProperty(self.componetInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1,_captureASBD, sizeof(AudioStreamBasicDescription));
        CheckStatus(status, @"error set kAudioUnitProperty_StreamFormat", NO);
        
        status = AudioUnitInitialize(self.componetInstance);
        CheckStatus(status, @"error AudioUnitInitialize", NO);
        
        if (noErr != status) {
            [self handleAudioComponentCreationFailure];
        }
    });
}

#pragma mark - <PLSourceAccessProtocol>

+ (PLAuthorizationStatus)deviceAuthorizationStatus {
    return (PLAuthorizationStatus)[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
}

+ (void)requestDeviceAccessWithCompletionHandler:(void (^)(BOOL granted))handler {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (handler) {
            handler(granted);
        }
    }];
}

@end
