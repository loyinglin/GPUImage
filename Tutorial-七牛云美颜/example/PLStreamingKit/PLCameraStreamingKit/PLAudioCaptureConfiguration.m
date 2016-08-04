//
//  PLAudioCaptureConfiguration.m
//  PLCaptureKit
//
//  Created by WangSiyu on 5/5/16.
//  Copyright © 2016 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "PLAudioCaptureConfiguration.h"
#import <AVFoundation/AVFoundation.h>

@interface PLAudioCaptureConfiguration ()

@end

@implementation PLAudioCaptureConfiguration

+ (instancetype)defaultConfiguration {
    PLAudioCaptureConfiguration *config = [[PLAudioCaptureConfiguration alloc] init];
    config.channelsPerFrame = 1;
    return config;
}

- (id)copyWithZone:(NSZone *)zone {
    PLAudioCaptureConfiguration *config = [[PLAudioCaptureConfiguration alloc] init];
    config.channelsPerFrame = self.channelsPerFrame;
    return config;
}

- (BOOL)isEqualToAudioCaptureConfiguration:(PLAudioCaptureConfiguration *)other {
    return (self.channelsPerFrame == other.channelsPerFrame);
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }
    
    return [self isEqualToAudioCaptureConfiguration:other];
}

@end
