//
//  PLMicrophoneSource.h
//  PLCameraStreamingKit
//
//  Created by 0day on 15/3/26.
//  Copyright (c) 2015年 qgenius. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioToolbox.h>

#import "PLSourceAccessProtocol.h"
#import "PLAudioCaptureConfiguration.h"

@class PLMicrophoneSource;
@protocol PLMicrophoneSourceDelegate <NSObject>

- (void)microphoneSource:(PLMicrophoneSource *)source didGetAudioBuffer:(AudioBuffer *)buffer;
- (void)microphoneSourceHardwareSamplerateChanged:(PLMicrophoneSource *)source;
- (void)microphoneSource:(PLMicrophoneSource *)source tryRestartCaptureError:(NSError *)error;
- (void)microphoneSourceMediaServicesWereReset:(PLMicrophoneSource *)source;

@end

@interface PLMicrophoneSource : NSObject
<
PLSourceAccessProtocol
>

@property (nonatomic, assign, readonly) PLAudioCaptureConfiguration *audioCaptureConfiguration;
@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, weak) id<PLMicrophoneSourceDelegate> delegate;
@property (nonatomic, assign, getter=isMuted) BOOL muted;   // default as NO.
@property (nonatomic, readonly) AudioStreamBasicDescription *captureASBD;
@property (nonatomic, assign) float inputGain;

- (instancetype)initWithAudioCaptureConfiguration:(PLAudioCaptureConfiguration *)audioCaptureConfiguration;

- (void)startRunning;
- (void)stopRunning;

@end
