//
//  Livingshowview.h
//  直播  主播端推流实现
//
//  Created by iOS on 16/8/10.
//  Copyright © 2016年 xiaoai cheng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIView+Add.h"

#import "UIControl+Add.h"

#import "LFLiveSession.h"

#define kScreenHeight [UIScreen mainScreen].bounds.size.height

#define kScreenWidth [UIScreen mainScreen].bounds.size.width

@interface Livingshowview : UIView <LFLiveSessionDelegate>
//是否美颜按钮
@property (nonatomic, strong) UIButton *beautyButton;

//切换摄像头按钮
@property (nonatomic, strong) UIButton *cameraButton;

//关闭按钮
@property (nonatomic, strong) UIButton *closeButton;

//开始直播按钮
@property (nonatomic, strong) UIButton *startLiveButton;

//按钮容器

@property (nonatomic, strong) UIView *containerView;

//调试信息

@property (nonatomic, strong) LFLiveDebug *debugInfo;

//重要的 session

@property (nonatomic, strong) LFLiveSession *session;


@end
