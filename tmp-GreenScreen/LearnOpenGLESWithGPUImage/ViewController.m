//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by loyinglin on 16/5/10.
//  Copyright © 2016年 loyinglin. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"

@interface ViewController ()
@property (nonatomic, strong) GPUImageMovie *movieGreen;
@property (nonatomic, strong) GPUImageMovie *movieNormal;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.movieGreen = [[GPUImageMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"greenscreen" withExtension:@"mp4"]];
    self.movieGreen.playAtActualSpeed = YES;
    self.movieGreen.shouldRepeat = YES;
    
    self.movieNormal = [[GPUImageMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"abc" withExtension:@"mp4"]];
    self.movieNormal.playAtActualSpeed = YES;
    self.movieNormal.shouldRepeat = YES;
    
    GPUImageChromaKeyBlendFilter *chromaKeyBlendFilter = [[GPUImageChromaKeyBlendFilter alloc] init];
    
    GPUImageView *imageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    
    // chan
    [self.movieGreen addTarget:chromaKeyBlendFilter];
    [self.movieNormal addTarget:chromaKeyBlendFilter];
    [chromaKeyBlendFilter addTarget:imageView];

    [self.movieGreen startProcessing];
    [self.movieNormal startProcessing];
    
}

@end
