//
// Copyright (c) 2019-present, TT, Inc.
// All rights reserved.
//
// This source code is licensed under the license found in the LICENSE file in
// the root directory of this source tree.
//
// Created on: 2019/10/18
// Created by: TT
//


#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>


@interface WXRocketHooking : NSObject

// 生成的方法名每次都不一样，包含随机数
+ (SEL)swizzledSelectorForSelector:(SEL)selector;

// 生成的 selector 每次都一样，不包含随机数
+ (SEL)swizzledSelectorForSelectorConstant:(SEL)selector;

+ (BOOL)instanceRespondsButDoesNotImplementSelector:(SEL)selector onClass:(Class)cls;
+ (void)replaceImplementationOfKnownSelector:(SEL)originalSelector onClass:(Class)cls withBlock:(id)block swizzledSelector:(SEL)swizzledSelector;
+ (void)replaceImplementationOfSelector:(SEL)selector withSelector:(SEL)swizzledSelector forClass:(Class)cls withMethodDescription:(struct objc_method_description)methodDescription implementationBlock:(id)implementationBlock undefinedBlock:(id)undefinedBlock;

@end
