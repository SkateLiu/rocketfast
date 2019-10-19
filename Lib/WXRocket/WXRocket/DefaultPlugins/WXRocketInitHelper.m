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


#import "WXRocketInitHelper.h"
#import "WXRocketClient.h"
#import "WXRocketDefaultPlugins.h"

@implementation WXRocketInitHelper

+ (void)start {
    [[WXRocketClient shared]
        setPluginsSetupHandler:^(NSMutableArray<id<WXRocketPlugin>> *_Nonnull plugins) {
            [WXRocketDefaultPlugins addDefaultClientPluginsInto:plugins];
        }
        pluginsCleanHandler:^(NSMutableArray<id<WXRocketPlugin>> *_Nonnull plugins) {
        [WXRocketDefaultPlugins cleanDefaultClientPluginsFrom:plugins];

    }];

    [[WXRocketClient shared] startServer];
}

+ (void)stop {
    [[WXRocketClient shared] stopServer];
}

@end
