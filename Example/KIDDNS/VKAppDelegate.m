//
//  VKAppDelegate.m
//  KIDDNS
//
//  Created by yiyangest on 09/14/2018.
//  Copyright (c) 2018 yiyangest. All rights reserved.
//

#import "VKAppDelegate.h"
#import <KIDDNS/DNSCenter.h>


@interface KIDLogger : NSObject<KIDDNSLogger>

@end

@implementation KIDLogger

- (void)logLevel:(KIDDNSLogLevel)level result:(KIDDNSResult *)result
{
    NSLog(@"[DNSLog][%@] result: %@", @(level), result);
}

@end

@implementation VKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    KIDDNSConfig *config = [KIDDNSConfig new];
    config.accountId = 1291;
    config.key = @"your key";
    config.presolvedHosts = @[@"httpbin.org"];
    [[DNSCenter defaultCenter] initializeDNSServiceWithConfig:config];
    [[DNSCenter defaultCenter] addLogger:[KIDLogger new]];
    [DNSCenter defaultCenter].automaticDNS = YES;
    [DNSCenter defaultCenter].whiteList = @[@"httpbin.org"];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

