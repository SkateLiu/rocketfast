//
//  WXLoginViewController.m
//  
//
//  Created by Teemo on 19/10/16.
//  Copyright (c) 2019年 Teemo. All rights reserved.
//  分类控制器

#import "WXLoginViewController.h"
#import <objc/runtime.h>
#import <SVProgressHUD.h>
#import "WXLoginDetailViewController.h"

@interface WXLoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *useName;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UILabel *okLab;

@end

@implementation WXLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

- (IBAction)loginBtnClick:(UIButton *)sender {
    if ([self.useName.text isEqualToString:@"dingdone"] && [self.password.text isEqualToString:@"123456"]) {
        [SVProgressHUD showSuccessWithStatus:@"登录成功"];
        WXLoginDetailViewController *detailVC = [WXLoginDetailViewController new];
        [self.navigationController pushViewController:detailVC animated:YES];
    } else {
        [SVProgressHUD showErrorWithStatus:@"用户名或密码错误！"];
    }
}
- (IBAction)switchClick:(UISwitch *)sender {
    
    if (sender.isOn) {
        self.okLab.text = @"同意协议";
    }
}



@end
