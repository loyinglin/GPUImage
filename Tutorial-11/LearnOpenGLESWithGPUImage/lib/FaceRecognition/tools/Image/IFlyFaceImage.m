//
//  IFlyFaceImage.m
//  IFlyFaceDemo
//
//  Created by JzProl.m.Qiezi on 15/12/22.
//  Copyright © 2015年 iflytek. All rights reserved.
//

#import "IFlyFaceImage.h"
#import "UIImage+Extensions.h"
#import "iflyMSC/IFlyFaceSDK.h"
#import "CalculatorTools.h"


@implementation IFlyFaceImage

@synthesize data=_data;

-(instancetype)init{
    if (self=[super init]) {
        _data=nil;
        self.width=0;
        self.height=0;
        self.direction=IFlyFaceDirectionTypeLeft;
    }
    
    return self;
}

-(void)dealloc{
    self.data=nil;
}

@end
