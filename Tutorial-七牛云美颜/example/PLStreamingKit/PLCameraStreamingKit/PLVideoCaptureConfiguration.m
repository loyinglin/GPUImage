//
//  PLVideoCaptureConfiguration.m
//  PLCaptureKit
//
//  Created by WangSiyu on 5/5/16.
//  Copyright © 2016 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "PLVideoCaptureConfiguration.h"

@implementation PLVideoCaptureConfiguration

+ (instancetype)defaultConfiguration {
    PLVideoCaptureConfiguration *config = [[PLVideoCaptureConfiguration alloc] init];
    config.videoFrameRate = 30;
    config.sessionPreset = AVCaptureSessionPreset640x480;
    config.horizontallyMirrorFrontFacingCamera = YES;
    config.horizontallyMirrorRearFacingCamera = NO;
    config.position = AVCaptureDevicePositionBack;
    return config;
}

- (instancetype)initWithVideoFrameRate:(NSUInteger)videoFrameRate sessionPreset:(NSString *)sessionPreset horizontallyMirrorFrontFacingCamera:(BOOL)horizontallyMirrorFrontFacingCamera horizontallyMirrorRearFacingCamera:(BOOL)horizontallyMirrorRearFacingCamera cameraPosition:(AVCaptureDevicePosition)position {
    if (self = [super init]) {
        self.videoFrameRate = videoFrameRate;
        self.sessionPreset = sessionPreset;
        self.horizontallyMirrorFrontFacingCamera = horizontallyMirrorFrontFacingCamera;
        self.horizontallyMirrorRearFacingCamera = horizontallyMirrorRearFacingCamera;
        self.position = position;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    PLVideoCaptureConfiguration *config = [[PLVideoCaptureConfiguration alloc] init];
    config.videoFrameRate = self.videoFrameRate;
    config.sessionPreset = [self.sessionPreset copy];
    config.horizontallyMirrorFrontFacingCamera = self.horizontallyMirrorFrontFacingCamera;
    config.horizontallyMirrorRearFacingCamera = self.horizontallyMirrorRearFacingCamera;
    config.position = self.position;
    return config;
}

- (BOOL)isEqualToVideoCaptureConfiguration:(PLVideoCaptureConfiguration *)other {
    return (self.videoFrameRate == other.videoFrameRate
            && [self.sessionPreset isEqualToString:other.sessionPreset] && self.horizontallyMirrorFrontFacingCamera == other.horizontallyMirrorFrontFacingCamera && self.horizontallyMirrorRearFacingCamera == other.horizontallyMirrorRearFacingCamera && self.position == other.position);
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }
    
    return [self isEqualToVideoCaptureConfiguration:other];
}

@end
