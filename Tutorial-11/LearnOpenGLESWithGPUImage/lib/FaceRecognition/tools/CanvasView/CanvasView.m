//
//  CanvasView.m
//  Created by sluin on 15/7/1.
//  Copyright (c) 2015年 SunLin. All rights reserved.
//

#import "CanvasView.h"

@interface CanvasView ()

//头部贴图
@property (nonatomic,strong) UIImageView *  headMapView;
//眼睛贴图
@property (nonatomic,strong) UIImageView * eyesMapView;
//鼻子贴图
@property (nonatomic,strong) UIImageView * noseMapView;
//嘴巴贴图
@property (nonatomic,strong) UIImageView * mouthMapView;
//面部贴图
@property (nonatomic,strong) UIImageView * facialTextureMapView;

@end

@implementation CanvasView{
    CGContextRef context ;
}

-(UIImageView *) headMapView{
    if(_headMapView == nil){
        
        _headMapView = [[UIImageView alloc] init];
        [self addSubview:_headMapView];
        
    }
    return _headMapView;
}


-(void) setHeadMap:(UIImage *)headMap{
    if (_headMap != headMap) {
        _headMap = headMap;
        self.headMapView.image = _headMap;
        
    }
}

- (void)drawRect:(CGRect)rect {
    [self drawPointWithPoints:self.arrPersons] ;

}

-(void)drawPointWithPoints:(NSArray *)arrPersons{
    
    if (context) {
        CGContextClearRect(context, self.bounds) ;
    }
    context = UIGraphicsGetCurrentContext();

    double rotation = 0.0;
    //头部中点
    CGPoint midpoint = CGPointZero;
    CGFloat spacing = 60;
    
    for (NSDictionary *dicPerson in self.arrPersons) {
        
#pragma mark - 识别面部关键点
        /*
         识别面部关键点
         */
        if ([dicPerson objectForKey:POINTS_KEY]) {
#pragma mark - 取嘴角的点算头饰的旋转角度
            NSArray * strPoints = [dicPerson objectForKey:POINTS_KEY];
            //右边鼻孔
            CGPoint  strPoint1 = CGPointFromString(((NSString *)strPoints[2]));
//            CGContextAddEllipseInRect(context,CGRectMake(strPoint1.x - 1 , strPoint1.y - 1 , 2 , 2));
           //左边鼻孔
            CGPoint  strPoint2 = CGPointFromString(((NSString *)strPoints[15]));
//            CGContextAddEllipseInRect(context,CGRectMake(strPoint2.x - 1 , strPoint2.y - 1 , 2 , 2));
            
            //右边嘴角
            CGPoint  strPoint3 = CGPointFromString(((NSString *)strPoints[5]));
//            CGContextAddEllipseInRect(context,CGRectMake(strPoint3.x - 1 , strPoint3.y - 1 , 2 , 2));
            //左边嘴角
            CGPoint strPoint4 = CGPointFromString(((NSString *)strPoints[20]));
//            CGContextAddEllipseInRect(context,CGRectMake(strPoint4.x - 1 , strPoint4.y - 1 , 2 , 2));
            
           rotation = atan((strPoint3.x+strPoint4.x -strPoint1.x - strPoint2.x)/(strPoint3.y +strPoint4.y - strPoint1.y - strPoint2.y));
            
            
#pragma mark - 取眉毛的点算头部的位置
            //左边眉毛中间点
            CGPoint  eyebrowsPoint1 = CGPointFromString(((NSString *)strPoints[16]));
//            CGContextAddEllipseInRect(context,CGRectMake(eyebrowsPoint1.x - 1 , eyebrowsPoint1.y - 1 , 2 , 2));
            
            //左边眉毛1号点
            CGPoint  eyebrowsPoint2 = CGPointFromString(((NSString *)strPoints[11]));
//            CGContextAddEllipseInRect(context,CGRectMake(eyebrowsPoint2.x - 1 , eyebrowsPoint2.y - 1 , 2 , 2));
            
            //右边眉毛中间点
            CGPoint  eyebrowsPoint3 = CGPointFromString(((NSString *)strPoints[17]));
//            CGContextAddEllipseInRect(context,CGRectMake(eyebrowsPoint3.x - 1 , eyebrowsPoint3.y - 1 , 2 , 2));
            
//            //右边眉毛一号点
            CGPoint eyebrowsPoint4 = CGPointFromString(((NSString *)strPoints[18]));
//            CGContextAddEllipseInRect(context,CGRectMake(eyebrowsPoint4.x - 1 , eyebrowsPoint4.y - 1 , 2 , 2));
//
            CGFloat midpointX  = (spacing *(eyebrowsPoint4.x + eyebrowsPoint2.x - eyebrowsPoint3.x - eyebrowsPoint1.x) / (eyebrowsPoint4.y + eyebrowsPoint2.y - eyebrowsPoint3.y - eyebrowsPoint1.y) + (eyebrowsPoint1.x + eyebrowsPoint3.x)) / 2;
            CGFloat midpointY = eyebrowsPoint2.y - spacing;
            
            midpoint = CGPointMake(midpointX, midpointY);
//            CGContextAddEllipseInRect(context,CGRectMake(midpoint.x - 1 , midpoint.y - 1 , 2 , 2));
        }
        
        BOOL isOriRect=NO;
        if ([dicPerson objectForKey:RECT_ORI]) {
            isOriRect=[[dicPerson objectForKey:RECT_ORI] boolValue];
        }
    
        if ([dicPerson objectForKey:RECT_KEY]) {
            
            CGRect rect=CGRectFromString([dicPerson objectForKey:RECT_KEY]);
            if(self.headMap){
                CGFloat scale =  (rect.size.width / self.headMap.size.width) + 0.3;
                CGFloat headMapViewW = scale * self.headMap.size.width;
                CGFloat headmapViewH = scale * self.headMap.size.height;
                
               CGRect frame  =  CGRectMake(midpoint.x - (headMapViewW * 0.5), midpoint.y - headmapViewH, headMapViewW, headmapViewH);
                
                self.headMapView.frame = frame;
                self.headMapView.bounds = CGRectMake(0, 0, headMapViewW, headmapViewH);
                
                self.headMapView.layer.anchorPoint = CGPointMake(0.5, 1);
                self.headMapView.transform = CGAffineTransformMakeRotation(-rotation);
                
            }
        }
    }

    [[UIColor greenColor] set];
    CGContextSetLineWidth(context, 2);
    CGContextStrokePath(context);
}

@end
