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


NS_ASSUME_NONNULL_BEGIN

/**
 Run Rocket shortly and simply.
 If you need custom plugins, see how `start` work, make your own start.
 */
@interface WXRocketInitHelper : NSObject

/**
 If you wanna start with custom plugins, implement your own start method.
 */
+ (void)start;
+ (void)stop;

@end

NS_ASSUME_NONNULL_END
