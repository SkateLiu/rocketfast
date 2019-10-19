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
#import "WXRocketPlugin.h"
#import "WXRocketUserDefaults.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^WXRocketClientPluginsSetupHandler)(NSMutableArray<id<WXRocketPlugin>> *pluginsToAdd);
typedef void (^WXRocketClientPluginsCleanHandler)(NSMutableArray<id<WXRocketPlugin>> *pluginsAdded);

@interface WXRocketClient : NSObject

+ (instancetype)shared;

/**
 plugins setup and cleaner

 @param pluginsSetupHandler pluginsSetupHandler will be called while `startServer` invoked.
                            the initial plugin array is empty,
                            after the block, the added plugins will be used to setup client,
                            you can add your own plugins into the array here.

 @param pluginsCleanHandler pluginsCleanHandler will be called while `stopServer` invoked.
                            the plugin array item will be remove internal after stop,
                            you can do cleanup if you've retain the plugins external.
 */
- (void)setPluginsSetupHandler:(WXRocketClientPluginsSetupHandler)pluginsSetupHandler
           pluginsCleanHandler:(WXRocketClientPluginsCleanHandler)pluginsCleanHandler;


/**
 start rocket client server, and trigger `rocketClientDidStart` in all plugins.
 */
- (void)startServer;

- (void)stopServer;

/**
 manual call `addPlugin` after startServer will not invoke `rocketClientDidStart`
 */
- (void)addPlugin:(id<WXRocketPlugin>)plugin;
- (void)removePlugin:(id<WXRocketPlugin>)plugin;
- (nullable id<WXRocketPlugin>)pluginFromID:(NSString *)pluginID;

@end

NS_ASSUME_NONNULL_END
