//
//  ViewController.m
//  LearnOpenGLESWithGPUImage
//
//  Created by loyinglin on 16/5/10.
//  Copyright © 2016年 loyinglin. All rights reserved.
//

#import "ViewController.h"
#import <GPUImageView.h>
//#import <GPUImage/GPUImageSepiaFilter.h>
#import <GPUImage/GPUImage.h>

@interface ViewController ()
@property (nonatomic , strong) UIImageView* mImageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:imageView];
    self.mImageView = imageView;
    [self onCustom];
}

- (void)onCustom {
    GPUImageFilter *filter = [[GPUImageSepiaFilter alloc] init];
    UIImage *image = [UIImage imageNamed:@"face"];
    if (image) {
        self.mImageView.image = [filter imageByFilteringImage:image];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
