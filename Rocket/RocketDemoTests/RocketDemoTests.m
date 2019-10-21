//
//  RocketDemoTests.m
//  RocketDemoTests
//
//  Created by chenjianneng on 2019/10/16.
//  Copyright © 2019 Teemo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KIF/KIFTypist.h>
#import <KIF/KIF.h>
#import <KIF/KIFTypist.h>


@interface RocketDemoTests  : KIFTestCase

@end

@implementation RocketDemoTests


- (void)testLogin {

    [tester tapViewWithAccessibilityLabel:@"登录"];

    [tester clearTextFromViewWithAccessibilityLabel:@"username"];
    [tester enterText:@"testusername\n" intoViewWithAccessibilityLabel:@"username"];
    [tester clearTextFromViewWithAccessibilityLabel:@"password"];
    [tester enterText:@"123445\n" intoViewWithAccessibilityLabel:@"password"];
    [tester tapViewWithAccessibilityLabel:@"login"];

    [tester clearTextFromViewWithAccessibilityLabel:@"username"];
    [tester enterText:@"dingdone\n" intoViewWithAccessibilityLabel:@"username"];
    [tester clearTextFromViewWithAccessibilityLabel:@"password"];
    [tester enterText:@"123456\n" intoViewWithAccessibilityLabel:@"password"];

    [tester tapViewWithAccessibilityLabel:@"ok"];
    [NSThread sleepForTimeInterval:1];

    [tester tapViewWithAccessibilityLabel:@"login"];


    [tester swipeViewWithAccessibilityLabel:@"tableView" inDirection:KIFSwipeDirectionUp];

}

@end
