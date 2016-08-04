//
//  PLGPUImageCameraFilter.h
//  PLCameraStreamingKit
//
//  Created by WangSiyu on 5/9/16.
//  Copyright © 2016 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "PLCameraFilter.h"

@interface PLGPUImageCameraFilter : PLCameraFilter

- (instancetype)initWithGPUImageFilter:(GPUImageFilter *)filter;

@end
