//
//  Livingshowview.m
//  直播  主播端推流实现
//
//  Created by iOS on 16/8/10.
//  Copyright © 2016年 xiaoai cheng. All rights reserved.
//

#import "Livingshowview.h"

@implementation Livingshowview

- (instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    
    if (self) {
        
        //背景色
        
        self.backgroundColor = [UIColor yellowColor];
        
        //准备录制音频
        
        [self requestAccessForVideo];
        
        //准备录制音频
        
        [self requestAccessForAudio];
        
        //添加容器懒加载(并添加按钮上去)
        
        [self addSubview:self.containerView];
//        
//        LFLiveStreamInfo *stream = [LFLiveStreamInfo new];
//        
//        //每一个直播都有一个推流地址
//        

//        
//        [self.session startLive:stream];
//        
        
    }
    
    return self;
    
}

- (UIView *)containerView{
    
    if (_containerView == nil) {
        
        _containerView = [[UIView alloc]initWithFrame:self.bounds];
        
        [self addSubview:_containerView];
        
        //创建几个按钮
        
        // 添加按钮
        [_containerView addSubview:self.closeButton];
        [_containerView addSubview:self.cameraButton];
        [_containerView addSubview:self.beautyButton];
        [_containerView addSubview:self.startLiveButton];

    }
    
    return _containerView;
    
}

//关闭直播

- (UIButton *)closeButton{
    
    if(_closeButton == nil){
        
        _closeButton = [[UIButton alloc]initWithFrame:CGRectMake(kScreenWidth - 100, 70, 80, 40)];
        
        [_closeButton setBackgroundColor:[UIColor cyanColor]];
        
        [_closeButton setTitle:@"关闭" forState: UIControlStateNormal];
        
        [_closeButton addTarget:self action:@selector(closeaction) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    return _closeButton;
    
}

//切换相机

- (UIButton *)cameraButton{
    
    if(_cameraButton == nil){
        
        _cameraButton = [[UIButton alloc]initWithFrame:CGRectMake(kScreenWidth - 180, 70, 70, 40)];
        
        [_cameraButton setBackgroundColor:[UIColor redColor]];
        
        [_cameraButton setTitle:@"切换" forState: UIControlStateNormal];
        
        [_cameraButton addTarget:self action:@selector(changeacamera) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    return _cameraButton;
    
}

//美颜

- (UIButton *)beautyButton{
    
    if(_beautyButton == nil){
        
        _beautyButton = [[UIButton alloc]initWithFrame:CGRectMake(50, 70, 70, 40)];
        
        [_beautyButton setBackgroundColor:[UIColor cyanColor]];
        
        [_beautyButton setTitle:@"美颜" forState: UIControlStateNormal];
        
        [_beautyButton addTarget:self action:@selector(beautyfy) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    return _beautyButton;
    
}

//暂停录制

- (UIButton *)startLiveButton{
    
    if(_startLiveButton == nil){
        
        _startLiveButton = [[UIButton alloc]initWithFrame:CGRectMake((kScreenWidth - 70) / 2, 300, 70, 40)];
        
        [_startLiveButton setBackgroundColor:[UIColor blackColor]];
        
        [_startLiveButton setTitle:@"结束直播" forState: UIControlStateNormal];
        
        [_startLiveButton addTarget:self action:@selector(pausea) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    return _startLiveButton;
    
}

//对应按钮的方法

- (void)closeaction{
    
//    [sel];
    
    //对应一个清理的状态来实现关闭后告诉服务器的???
    
}

- (void)changeacamera{
    
    //获取到当前状态
    
    AVCaptureDevicePosition devicePositon = self.session.captureDevicePosition;
    
    //判断如果是后置就使用前置 如果是前置就使用后置摄像头
    
    self.session.captureDevicePosition = (devicePositon == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    
}

- (void)beautyfy{
    
    //首先改变的是美颜
    
    self.session.beautyFace = !self.session.beautyFace;
    
    //美颜按钮被选中的状态
    
    self.beautyButton.selected = !self.session.beautyFace;
    
}

- (void)pausea{
    
    self.startLiveButton.selected = !self.startLiveButton.selected;
    
    if(self.startLiveButton.selected){
    
        [self.startLiveButton setTitle:@"结束直播" forState:UIControlStateNormal];
        
        LFLiveStreamInfo *stream = [LFLiveStreamInfo new];
        
        //每一个直播都有一个推流地址
        
        stream.url = @"rtmp://172.16.80.152:1935/rtmplive/room";
        
        [self.session startLive:stream];
        
    }else{
        
        [self.startLiveButton setTitle:@"开始直播" forState:UIControlStateNormal];
        
        [self.session stopLive];
    
    }

    
}

- (void)requestAccessForVideo{
    
//    //请求录制视频录制视屏授权
//    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    __weak Livingshowview * weakself = self;
    
    switch (status) {
            
            //授权状态没有被确定过
            
        case AVAuthorizationStatusNotDetermined:{
            
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
                if (granted) {
                    
                    [weakself.session setRunning:YES];//开始录制
                    
                }
                
            }];
            
            break;
            
        }
            
        case AVAuthorizationStatusAuthorized:{
            
            [self .session setRunning:YES];
            
            break;
        }
            
        case AVAuthorizationStatusDenied://提醒在哪里设置打开摄像头
            
        case AVAuthorizationStatusRestricted://摄像头坏了 无法访问提示
            // 用户明确地拒绝授权，或者相机设备无法访问
            
            break;
            
        default:
            break;
    }
    
//    __weak typeof(self) _self = self;
//    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
//    switch (status) {
//        case AVAuthorizationStatusNotDetermined:{
//            // 许可对话没有出现，发起授权许可
//            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
//                if (granted) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [_self.session setRunning:YES];
//                    });
//                }
//            }];
//            break;
//        }
//        case AVAuthorizationStatusAuthorized:{
//            // 已经开启授权，可继续
//            [_self.session setRunning:YES];
//            break;
//        }
//        case AVAuthorizationStatusDenied:
//        case AVAuthorizationStatusRestricted:
//            // 用户明确地拒绝授权，或者相机设备无法访问
//            
//            break;
//        default:
//            break;
//    }
    
}

- (void)requestAccessForAudio{
    
//    //请求授权访问 mic
//    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    
     __weak Livingshowview * weakself = self;
    
    switch (status) {
        case AVAuthorizationStatusNotDetermined:{
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            
//                [weakself.session setRunning:YES];
                
            }];
            
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            
            break;
            
        }
        case AVAuthorizationStatusDenied:
            
        case AVAuthorizationStatusRestricted:
            
            break;
            
        default:
            
            break;
            
    }
    
//    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
//    switch (status) {
//        case AVAuthorizationStatusNotDetermined:{
//            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
//            }];
//            break;
//        }
//        case AVAuthorizationStatusAuthorized:{
//            break;
//        }
//        case AVAuthorizationStatusDenied:
//        case AVAuthorizationStatusRestricted:
//            break;
//        default:
//            break;
//    }
    
}

#pragma mark ---- <LFStreamingSessionDelegate>

/** live status changed will callback */
- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange:(LFLiveState)state{
    
    //
    
    NSLog(@"liveStateDidChange -- ");
    
}

/** live debug info callback */
- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug*)debugInfo{
    
    NSLog(@"debugInfo -- ");
    
}

/** callback socket errorcode */
- (void)liveSession:(nullable LFLiveSession*)session errorCode:(LFLiveSocketErrorCode)errorCode{
    
    NSLog(@"errorCode -- ");
    
}

- (LFLiveSession*)session{
    if(!_session){
        _session = [[LFLiveSession alloc] initWithAudioConfiguration:[LFLiveAudioConfiguration defaultConfiguration] videoConfiguration:[LFLiveVideoConfiguration defaultConfiguration]];
        _session.running = YES;
        _session.preView = self;
    }
    return _session;
}



@end
