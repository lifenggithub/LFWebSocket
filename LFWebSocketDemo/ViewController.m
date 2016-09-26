//
//  ViewController.m
//  LFWebSocketDemo
//
//  Created by 李丰 on 16/9/26.
//  Copyright © 2016年 李丰. All rights reserved.
//

#import "ViewController.h"

#import "LFWSWebSocket.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSURL *url = [NSURL URLWithString:@"ws:"];
    LFWSWebSocket *webSocket = [[LFWSWebSocket alloc] initWithURL:url protocols:nil];
    [webSocket open];
    
    [webSocket setTextCallback:^(NSString *text) {
        
        NSLog(@"%@",text);
        
    }];
    [webSocket sendText:@"text"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
