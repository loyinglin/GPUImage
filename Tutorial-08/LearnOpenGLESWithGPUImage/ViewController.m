//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by 林伟池 on 16/5/10.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"

#import "THImageMovieWriter.h"
#import "THImageMovie.h"

#import <AssetsLibrary/ALAssetsLibrary.h>

@interface ViewController ()
@property (nonatomic , strong) UILabel  *mLabel;
@property (nonatomic, strong) THImageMovieWriter *movieWriter;
@property(nonatomic) dispatch_group_t recordSyncingDispatchGroup;
@end


@implementation ViewController
{
    THImageMovie *movieFile;
    THImageMovie *movieFile2;
    GPUImageOutput<GPUImageInput> *filter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.view = filterView;
    
    self.mLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 100, 100)];
    self.mLabel.textColor = [UIColor redColor];
    [self.view addSubview:self.mLabel];
    
    filter = [[GPUImageDissolveBlendFilter alloc] init];
    [(GPUImageDissolveBlendFilter *)filter setMix:0.5];
    
    // 播放
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"abc" withExtension:@"mp4"];
    movieFile = [[THImageMovie alloc] initWithURL:sampleURL];
    movieFile.runBenchmark = YES;
    movieFile.playAtActualSpeed = YES;
    
    NSURL *sampleURL2 = [[NSBundle mainBundle] URLForResource:@"qwe" withExtension:@"mp4"];
    movieFile2 = [[THImageMovie alloc] initWithURL:sampleURL2];
    movieFile2.runBenchmark = YES;
    movieFile2.playAtActualSpeed = YES;
//
    NSArray *thMovies = @[movieFile, movieFile2];

    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    self.movieWriter = [[THImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640, 480) movies:thMovies];

    
    // 响应链
    [movieFile addTarget:filter];
    [movieFile2 addTarget:filter];
    
    // 显示到界面
    [filter addTarget:filterView];
    [filter addTarget:_movieWriter];
    
    [movieFile2 startProcessing];
    [movieFile startProcessing];
    [_movieWriter startRecording];
    
    CADisplayLink* dlink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
    [dlink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [dlink setPaused:NO];
    
    __weak typeof(self) weakSelf = self;
    [_movieWriter setCompletionBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->filter removeTarget:strongSelf->_movieWriter];
        [strongSelf->movieFile endProcessing];
        [strongSelf->movieFile2 endProcessing];
//        [strongSelf->_movieWriter finishRecording];
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToMovie))
        {
            [library writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     if (error) {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil
                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     } else {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil
                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     }
                 });
             }];
        }
        else {
            NSLog(@"error mssg)");
        }
    }];
}


- (void)printDuration:(NSURL *)url{
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:url options:inputOptions];
    
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler: ^{
        NSLog(@"movie: %@ duration: %.2f", url.lastPathComponent, CMTimeGetSeconds(inputAsset.duration));
    }];
}


- (void)setupAudioAssetReader {
    
    NSMutableArray *audioTracks = [NSMutableArray array];
    
    for(GPUImageMovie *movie in @[movieFile, movieFile2]){
        AVAsset *asset = movie.asset;
        if(asset){
            NSArray *_audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            if(_audioTracks.count > 0){
                [audioTracks addObject:_audioTracks.firstObject];
            }
        }
    }
    
    NSLog(@"audioTracks: %@", audioTracks);
    
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    for(AVAssetTrack *track in audioTracks){
        if(![track isKindOfClass:[NSNull class]]){
            NSLog(@"track url: %@ duration: %.2f", track.asset, CMTimeGetSeconds(track.asset.duration));
            AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio                                   preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, track.asset.duration)
                                                ofTrack:track
                                                 atTime:kCMTimeZero error:nil];
        }
    }
    
    
//    AVMutableComposition* videoComposition = [AVMutableComposition composition];
    NSMutableArray *videoTracks = [NSMutableArray array];
    
    for(GPUImageMovie *movie in @[movieFile, movieFile2]){
        AVAsset *asset = movie.asset;
        if(asset){
            NSArray *_videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if(_videoTracks.count > 0){
                [videoTracks addObject:_videoTracks.firstObject];
            }
        }
    }
    
    NSLog(@"videoTracks: %@", videoTracks);
    
    for(AVAssetTrack *track in videoTracks){
        if(![track isKindOfClass:[NSNull class]]){
            NSLog(@"track url: %@ duration: %.2f", track.asset, CMTimeGetSeconds(track.asset.duration));
            AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo                                   preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, track.asset.duration)
                                                ofTrack:track
                                                 atTime:kCMTimeZero error:nil];
        }
    }
    
//    NSMutableArray *trackMixArray = [NSMutableArray array];
//    
//    // Add AudioMix to fade in the volume ramps
//    AVMutableAudioMixInputParameters *trackMix1 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTracks[0]];
//    
//    [trackMix1 setVolumeRampFromStartVolume:1.0 toEndVolume:0.0 timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(1, 1), CMTimeMakeWithSeconds(5, 1))];
//    
//    [trackMixArray addObject:trackMix1];
//    
//    AVMutableAudioMixInputParameters *trackMix2 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTracks[1]];
//    
//    [trackMix2 setVolumeRampFromStartVolume:0.0 toEndVolume:1.0 timeRange:transitionTimeRanges[0]];
//    [trackMix2 setVolumeRampFromStartVolume:1.0 toEndVolume:1.0 timeRange:passThroughTimeRanges[1]];
//    
//    [trackMixArray addObject:trackMix2];
    
    
    AVAudioMix *audioMix = [AVMutableAudioMix audioMix];
    
    
//    movieCompostion = [[GPUImageMovieComposition alloc] initWithComposition:mixComposition andVideoComposition:nil andAudioMix:audioMix];
}





- (void)updateProgress
{
    self.mLabel.text = [NSString stringWithFormat:@"Progress:%d%%", (int)(movieFile.progress * 100)];
    [self.mLabel sizeToFit];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
