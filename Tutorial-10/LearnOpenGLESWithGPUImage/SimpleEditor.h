//
//  SimpleEditor.h
//  LearnAVFoundation
//
//  Created by loyinglin on 16/6/28.
//  Copyright © 2016年 loyinglin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTime.h>
#import <AVFoundation/AVFoundation.h>

@interface SimpleEditor : NSObject

@property (nonatomic, copy) NSArray *clips;
@property (nonatomic, copy) NSArray *clipTimeRanges;
@property (nonatomic) CMTime transitionDuration;

@property (nonatomic, readonly, retain) AVMutableComposition *composition;
@property (nonatomic, readonly, retain) AVMutableVideoComposition *videoComposition;
@property (nonatomic, readonly, retain) AVMutableAudioMix *audioMix;

- (void)buildCompositionObjectsForPlayback;
- (AVPlayerItem *)playerItem;

@end
