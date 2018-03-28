//
//  ViewController.m
//  DataInteraction
//
//  Created by hjbsj on 2018/3/28.
//  Copyright © 2018年 hjb. All rights reserved.
//

#import "ViewController.h"
#import "LoanViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)loadHTML:(id)sender {
    
    //加载本地文件
    LoanViewController *loanVC = [[LoanViewController alloc] init];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"cameraTest-hjb.html" ofType:nil];
    loanVC.urlString = path;
    [self.navigationController pushViewController:loanVC animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
