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

#import <WXRocket/WXRocketClient.h>



@interface WXRocketDefaultPlugins : NSObject

+ (void)loadEarlyServices;

+ (void)addDefaultClientPluginsInto:(NSMutableArray<id<WXRocketPlugin>> *)clientPlugins;
+ (void)cleanDefaultClientPluginsFrom:(NSMutableArray<id<WXRocketPlugin>> *)clientPlugins;


@end
