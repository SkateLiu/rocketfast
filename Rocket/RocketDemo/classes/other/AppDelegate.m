//
//  AppDelegate.m
//   
//
//  Created by Teemo on 19/10/16.
//  Copyright (c) 2019年 Teemo. All rights reserved.
//

#import "AppDelegate.h"
#import "WXTabBarController.h"
#import <WXRocket/WXRocketInitHelper.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self startRocket];
    [self setupTab];
    return YES;
}

- (void)setupTab {
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    WXTabBarController *tab = [[WXTabBarController alloc] init];
    self.window.rootViewController = tab;
    [self.window makeKeyAndVisible];
}

- (void)startRocket {
    [WXRocketInitHelper start];
}

@end
