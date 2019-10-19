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


#import "WXRocketDefaultPlugins.h"

#import <WXRocket/WXRocketInnerLogger.h>
#import <WXRocket/WXRocketUserDefaults.h>
#import <WXRocket/WXRocketUtility.h>

#import <WXRocket/WXRocketCPUTraceAdaptor.h>


@interface WXRocketDefaultPlugins ()

@end

static NSMutableArray<id<WXRocketPlugin>> *defaultClientPlugins;


@implementation WXRocketDefaultPlugins

+ (void)load {
    [self loadEarlyServices];
}

+ (void)loadEarlyServices {
    if (![WXRocketUserDefaults shared].rocketOn)
        return;
}

+ (void)initialize {
    defaultClientPlugins = @[].mutableCopy;
   
}

// MARK: -
+ (void)addDefaultClientPluginsInto:(NSMutableArray<id<WXRocketPlugin>> *)plugins {
    @synchronized(defaultClientPlugins) {
        if (defaultClientPlugins.count == 0)
            [self setupDefaultClientPlugins];

        for (id<WXRocketPlugin> plugin in defaultClientPlugins) {
            if (![plugins containsObject:plugin])
                [plugins addObject:plugin];
        }
    }
}

+ (void)cleanDefaultClientPluginsFrom:(NSMutableArray<id<WXRocketPlugin>> *)plugins {
    @synchronized(defaultClientPlugins) {
        for (id<WXRocketPlugin> plugin in defaultClientPlugins) {
            if ([plugins containsObject:plugin])
                [plugins removeObject:plugin];
        }

        [defaultClientPlugins removeAllObjects];
    }
}

+ (void)setupDefaultClientPlugins {
    [defaultClientPlugins removeAllObjects];
    [defaultClientPlugins addObject:[WXRocketCPUTraceAdaptor new]];
}

@end
