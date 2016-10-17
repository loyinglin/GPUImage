//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by 林伟池 on 16/5/10.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "ViewController.h"
#import <GPUImageView.h>
#import <GPUImage/GPUImageSepiaFilter.h>

@interface ViewController ()
@property (nonatomic , strong) UIImageView* mImageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    self.mImageView = imageView;
    [self onCustom];
}

- (void)onCustom {
    GPUImageSepiaFilter* filter = [[GPUImageSepiaFilter alloc] init];
    UIImage* image = [UIImage imageNamed:@"face"];
    if (image) {
        [self.mImageView setImage:[filter imageByFilteringImage:image]];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
