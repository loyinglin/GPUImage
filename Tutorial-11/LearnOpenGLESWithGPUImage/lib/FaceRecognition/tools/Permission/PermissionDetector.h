//
//  PermissionDetector.h
//  IFlyMFVDemo
//
//  Created by 张剑 on 15/6/2.
//
//

#import <Foundation/Foundation.h>

@interface PermissionDetector : NSObject

/**
 *  检测麦克风权限，仅支持iOS7.0以上系统
 *
 *  @return 准许返回YES;否则返回NO
 */
+(BOOL)isMicrophonePermissionGranted;

/**
 *  检测相机权限
 *
 *  @return 准许返回YES;否则返回NO
 */
+(BOOL)isCapturePermissionGranted;

/**
 *  检测相册权限
 *
 *  @return 准许返回YES;否则返回NO
 */
+(BOOL)isAssetsLibraryPermissionGranted;

@end
