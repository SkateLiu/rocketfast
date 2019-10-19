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
 The protocol of a Rocket client plugin.

 Once you have a new or exist module and wanna add it as Rocket client plugin,
 you should implement a adaptor that following WXRocketPlugin.

 you can see class `MTHNetworkMonitorRocketAdaptor` as an example.
 */
@protocol WXRocketPlugin <NSObject>

@required

/**
 Plugin Identity, should be different with other plugins.
 */
+ (NSString *)pluginID;


/**
 will triggered when Rocket client did start.
 */
- (void)rocketClientDidStart;

/**
 will triggered when Rocket client did stop.
 */
- (void)rocketClientDidStop;

@optional

/**
 will triggered when Rocket client status flush timer fired.
 */
- (void)receivedFlushStatusCommand;

@end

NS_ASSUME_NONNULL_END
