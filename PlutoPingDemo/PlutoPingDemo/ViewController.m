//
//  ViewController.m
//  PlutoPingDemo
//
//  Created by Pluto on 2018/1/25.
//  Copyright © 2018年 Pluto. All rights reserved.
//

#import "ViewController.h"
#import "PlutoPingService.h"

@interface ViewController ()
@property (nonatomic, strong) UILabel *label;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [PlutoPingService doInitWithAddress:@"192.168.1.102"];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(50, 50, 50, 50);
    button.backgroundColor = [UIColor redColor];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noti:) name:PltPingServiceFinishNotification object:nil];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 50)];
    self.label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.label];
}

- (void)buttonAction {
    [PlutoPingService start];
    self.label.text = @"";
}

- (void)noti:(NSNotification *)noti {
    NSDictionary *dic = noti.userInfo;
    if ([[dic objectForKey:PltPingServiceResultKey] isEqualToString:PltPingServiceResultSuccess]) {
        self.label.text = @"success";
    } else if ([[dic objectForKey:PltPingServiceResultKey] isEqualToString:PltPingServiceResultFail]) {
        self.label.text = @"fail";
    }
}


@end
