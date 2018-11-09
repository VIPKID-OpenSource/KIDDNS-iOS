//
//  VKViewController.m
//  KIDDNS
//
//  Created by yiyangest on 09/14/2018.
//  Copyright (c) 2018 yiyangest. All rights reserved.
//

#import "VKViewController.h"
#import <KIDDNS/DNSCenter.h>

@interface VKViewController ()

@end

@implementation VKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://httpbin.org/get"] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"[VC] error:  %@", error);
        }
        NSLog(@"[VC] completed");
    }] resume];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
