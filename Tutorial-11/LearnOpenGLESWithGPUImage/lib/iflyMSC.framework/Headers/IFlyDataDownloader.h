//
//  IFlyDataDownloader.h
//  msc
//
//  Created by ypzhao on 13-3-3.
//  Copyright (c) 2013年 IFLYTEK. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IFlySpeechError;
/*!
 *  此接口为数据上传接口 为个性化服务提供数据
 */
@interface IFlyDataDownloader : NSObject

/*!
 *  设置下载数据参数
 *
 *  @param parameter 参数值
 *  @param key       参数名
 */
-(void) setParameter:(NSString*) parameter forKey:(NSString*) key;

/*!
 *  下载完成回调
 *
 *  @param result 结果
 *  @param error  错误码
 */
typedef void(^IFlyDownLoadDataCompletionHandler)(NSString* result,IFlySpeechError * error);

/*!
 *  下载数据
 *  下载过程是**异步**的
 *
 *  @param completionHandler 下载完成回调
 */
- (void) downLoadDataWithCompletionHandler:(IFlyDownLoadDataCompletionHandler) completionHandler;

@end
