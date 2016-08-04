//
//  PLCameraFilter.h
//  PLProcessingKit
//
//  Created by WangSiyu on 5/7/16.
//  Copyright © 2016 Pili. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"

@interface PLCameraFilter : NSObject

@property (nonatomic, strong) GPUImageOutput *output;

- (void)setSource:(GPUImageOutput *)source;

@end
