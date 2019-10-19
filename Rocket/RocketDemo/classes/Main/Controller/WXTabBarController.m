//
//  WXTabBarController.m
//   
//
//  Created by Teemo on 19/10/16.
//  Copyright (c) 2019年 Teemo. All rights reserved.
//

#import "WXTabBarController.h"
#import "WXLoginViewController.h"
#import "WXMineViewController.h"
#import "WXNavigationController.h"

@interface WXTabBarController ()

@end

@implementation WXTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpAllChildViewController];
}

- (void)setUpAllChildViewController{
    UIStoryboard *threeStoryBoard = [UIStoryboard storyboardWithName:@"WXLoginViewController" bundle:nil];
    WXLoginViewController *login = [threeStoryBoard instantiateInitialViewController];
    [self setUpOneChildViewController:login image:[UIImage imageNamed:@"qw"] title:@"登录"];
    WXMineViewController *mine = [[WXMineViewController alloc] init];
    [self setUpOneChildViewController:mine image:[UIImage imageNamed:@"user"] title:@"我的"];
}

- (void)setUpOneChildViewController:(UIViewController *)viewController image:(UIImage *)image title:(NSString *)title{
    
    WXNavigationController *nav = [[WXNavigationController alloc] initWithRootViewController:viewController];
    nav.title = title;
    nav.tabBarItem.image = image;
    [nav.navigationBar setBackgroundImage:[UIImage imageNamed:@"commentary_num_bg"] forBarMetrics:UIBarMetricsDefault];
    viewController.navigationItem.title = title;
    [self addChildViewController:nav];
}

@end
