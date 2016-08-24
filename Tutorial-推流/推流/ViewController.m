//
//  ViewController.m
//  推流
//
//  Created by iOS on 16/8/10.
//  Copyright © 2016年 xiaoai cheng. All rights reserved.
//

#import "ViewController.h"

#import "Livingshowview.h"

#import "StartLiveView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)ttt:(id)sender {
    
    
//    Livingshowview *liv = [[Livingshowview alloc]initWithFrame:self.view.bounds];
    
    StartLiveView *liv = [[StartLiveView alloc]initWithFrame:self.view.bounds];
    
    [self.view addSubview:liv];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
