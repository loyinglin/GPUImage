//
//  PLGPUImageCameraFilter.m
//  PLCameraStreamingKit
//
//  Created by WangSiyu on 5/9/16.
//  Copyright © 2016 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "PLGPUImageCameraFilter.h"

@implementation PLGPUImageCameraFilter {
    GPUImageFilter * _filter;
}

- (instancetype)initWithGPUImageFilter:(GPUImageFilter *)filter {
    if (self = [super init]) {
        _filter = filter;
    }
    return self;
}

- (void)setSource:(GPUImageOutput *)source {
    [source addTarget:_filter];
}

- (GPUImageOutput *)output {
    return _filter;
}

@end
