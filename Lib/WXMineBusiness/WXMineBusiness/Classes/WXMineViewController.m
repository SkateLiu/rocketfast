//
//  WXMineViewController.m
//  RocketDemo
//
//  Created by chenjianneng on 2019/10/17.
//  Copyright © 2019 Teemo. All rights reserved.
//

#import "WXMineViewController.h"
#import "WXEnergyViewController.h"

@interface WXMineViewController ()

@end

@implementation WXMineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)energyButtonClicked:(id)sender {
    UIStoryboard *energyStoryBoard = [UIStoryboard storyboardWithName:@"WXEnergy" bundle:nil];
    WXEnergyViewController *vc = [energyStoryBoard instantiateInitialViewController];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
