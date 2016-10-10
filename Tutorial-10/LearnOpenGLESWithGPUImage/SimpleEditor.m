//
//  SimpleEditor.m
//  LearnAVFoundation
//
//  Created by 林伟池 on 16/6/28.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "SimpleEditor.h"
#import <CoreMedia/CoreMedia.h>

@interface SimpleEditor ()
@property (nonatomic, readwrite, retain) AVMutableComposition *composition;
@property (nonatomic, readwrite, retain) AVMutableVideoComposition *videoComposition;
@property (nonatomic, readwrite, retain) AVMutableAudioMix *audioMix;

@end

@implementation SimpleEditor

- (void)buildTransitionComposition:(AVMutableComposition *)composition andVideoComposition:(AVMutableVideoComposition *)videoComposition andAudioMix:(AVMutableAudioMix *)audioMix
{
    CMTime nextClipStartTime = kCMTimeZero;
    NSInteger i;
    NSUInteger clipsCount = [self.clips count];
    
    // 确保最后合并后的视频，变换长度不会超过最小长度的一半
    CMTime transitionDuration = self.transitionDuration;
    for (i = 0; i < clipsCount; i++ ) {
        NSValue *clipTimeRange = [self.clipTimeRanges objectAtIndex:i];
        if (clipTimeRange) {
            CMTime halfClipDuration = [clipTimeRange CMTimeRangeValue].duration;
            halfClipDuration.timescale *= 2;
            transitionDuration = CMTimeMinimum(transitionDuration, halfClipDuration);
        }
    }
    
    // Add two video tracks and two audio tracks.
    AVMutableCompositionTrack *compositionVideoTracks[2];
    AVMutableCompositionTrack *compositionAudioTracks[2];
    compositionVideoTracks[0] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid]; // 添加视频轨道0
    compositionVideoTracks[1] = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid]; // 添加视频轨道1
    compositionAudioTracks[0] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid]; // 添加音频轨道0
    compositionAudioTracks[1] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid]; // 添加音频轨道1
    
    CMTimeRange *passThroughTimeRanges = alloca(sizeof(CMTimeRange) * clipsCount);
    CMTimeRange *transitionTimeRanges = alloca(sizeof(CMTimeRange) * clipsCount);
    
    // Place clips into alternating video & audio tracks in composition, overlapped by transitionDuration.
    for (i = 0; i < clipsCount; i++ ) {
        NSInteger alternatingIndex = i % 2; // alternating targets: 0, 1, 0, 1, ...
        AVURLAsset *asset = [self.clips objectAtIndex:i];
        NSValue *clipTimeRange = [self.clipTimeRanges objectAtIndex:i];
        CMTimeRange timeRangeInAsset;
        if (clipTimeRange) {
            timeRangeInAsset = [clipTimeRange CMTimeRangeValue];
        }
        else {
            timeRangeInAsset = CMTimeRangeMake(kCMTimeZero, [asset duration]);
        }
        
        AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        NSError* error;
        [compositionVideoTracks[alternatingIndex] insertTimeRange:timeRangeInAsset ofTrack:clipVideoTrack atTime:nextClipStartTime error:&error];
        
        
        AVAssetTrack *clipAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [compositionAudioTracks[alternatingIndex] insertTimeRange:timeRangeInAsset ofTrack:clipAudioTrack atTime:nextClipStartTime error:&error];
        
        NSLog(@"add at %lf long %lf", CMTimeGetSeconds(timeRangeInAsset.start) + CMTimeGetSeconds(nextClipStartTime), CMTimeGetSeconds(timeRangeInAsset.duration));
        
        // 计算应该直接播放的区间
        // 从播放区间里面去掉变换区间
        passThroughTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, timeRangeInAsset.duration);
        if (i > 0) {
            passThroughTimeRanges[i].start = CMTimeAdd(passThroughTimeRanges[i].start, transitionDuration);
            passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration);
        }
        if (i+1 < clipsCount) {
            passThroughTimeRanges[i].duration = CMTimeSubtract(passThroughTimeRanges[i].duration, transitionDuration);
        }
        NSLog(@"passthrough at %lf long %lf", CMTimeGetSeconds(passThroughTimeRanges[i].start), CMTimeGetSeconds(passThroughTimeRanges[i].duration));
        // 计算下一个插入点
        nextClipStartTime = CMTimeAdd(nextClipStartTime, timeRangeInAsset.duration); // 加上持续时间
        nextClipStartTime = CMTimeSubtract(nextClipStartTime, transitionDuration); // 减去变换时间，得到下一个插入点
        
        // 第i个视频的变换时间为下一个的插入点，长度为变换时间
        if (i+1 < clipsCount) {
            transitionTimeRanges[i] = CMTimeRangeMake(nextClipStartTime, transitionDuration);
        }
        NSLog(@"transitionTimeRanges at %lf long %lf", CMTimeGetSeconds(transitionTimeRanges[i].start), CMTimeGetSeconds(transitionTimeRanges[i].duration));
    }
    
    
    NSMutableArray *instructions = [NSMutableArray array]; // 视频操作指令集合
    NSMutableArray<AVAudioMixInputParameters *> *trackMixArray = [NSMutableArray<AVAudioMixInputParameters *> array]; // 音频轨道参数集合
    
    for (i = 0; i < clipsCount; i++ ) {
        NSInteger alternatingIndex = i % 2; // 轨道索引
        
        AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction]; // 新建指令
        passThroughInstruction.timeRange = passThroughTimeRanges[i]; // 直接播放
        AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[alternatingIndex]]; // 视频轨道操作指令
        
        passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
        [instructions addObject:passThroughInstruction]; // 添加到指令集合
        
        if (i+1 < clipsCount) { // 不是最后一个
            AVMutableVideoCompositionInstruction *transitionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction]; // 新建指令
            transitionInstruction.timeRange = transitionTimeRanges[i]; // 变换时间
            AVMutableVideoCompositionLayerInstruction *fromLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[alternatingIndex]]; // 视频轨道操作指令
            AVMutableVideoCompositionLayerInstruction *toLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks[1-alternatingIndex]]; // 新的轨道指令
            // 1 dao 0
            [fromLayer setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:transitionTimeRanges[i]];
            // 目的轨道，从0到1
            [toLayer setOpacityRampFromStartOpacity:0.0 toEndOpacity:1.0 timeRange:transitionTimeRanges[i]];
            
            transitionInstruction.layerInstructions = [NSArray arrayWithObjects:toLayer, fromLayer, nil];
            [instructions addObject:transitionInstruction];
            
            AVMutableAudioMixInputParameters *trackMix1 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTracks[alternatingIndex]]; // 音轨0的参数
            
            [trackMix1 setVolumeRampFromStartVolume:1.0 toEndVolume:0.0 timeRange:transitionTimeRanges[i]]; // 音轨0，变换期间音量从1.0到0.0
            
            [trackMixArray addObject:trackMix1];
            
            AVMutableAudioMixInputParameters *trackMix2 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTracks[1 - alternatingIndex]]; // 音轨1的参数
            
            [trackMix2 setVolumeRampFromStartVolume:0.0 toEndVolume:1.0 timeRange:transitionTimeRanges[i]]; // 变换期间音量从0.0到1.0
//            [trackMix2 setVolumeRampFromStartVolume:1.0 toEndVolume:1.0 timeRange:passThroughTimeRanges[i + 1]]; // 播放期间音量 一直为1.0
            
            [trackMixArray addObject:trackMix2];
        }
        
    }
    
    audioMix.inputParameters = trackMixArray;
    videoComposition.instructions = instructions;
}

- (void)buildCompositionObjectsForPlayback
{
    if ( (self.clips == nil) || [self.clips count] == 0 ) {
        self.composition = nil;
        self.videoComposition = nil;
        return;
    }
    
    CGSize videoSize = [[self.clips objectAtIndex:0] naturalSize];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = nil;
    AVMutableAudioMix *audioMix = nil;
    
    composition.naturalSize = videoSize;
    
    videoComposition = [AVMutableVideoComposition videoComposition];
    audioMix = [AVMutableAudioMix audioMix];
    
    [self buildTransitionComposition:composition andVideoComposition:videoComposition andAudioMix:audioMix];
    
    if (videoComposition) {
        // 通用属性
        videoComposition.frameDuration = CMTimeMake(1, 30); // 30 fps
        videoComposition.renderSize = videoSize;
    }
    
    self.composition = composition;
    self.videoComposition = videoComposition;
    self.audioMix = audioMix;
}

- (AVPlayerItem *)playerItem
{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
    playerItem.videoComposition = self.videoComposition;
    playerItem.audioMix = self.audioMix;
    
    return playerItem;
}

@end
