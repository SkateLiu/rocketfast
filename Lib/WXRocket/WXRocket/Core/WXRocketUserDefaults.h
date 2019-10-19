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

typedef void (^WXRocketUserDefaultChangedHandler)(_Nullable id oldValue, _Nullable id newValue);

@interface WXRocketUserDefaults : NSObject

@property (nonatomic, assign) BOOL rocketOn;

@property (nonatomic, assign) NSTimeInterval statusFlushIntevalInSeconds;
@property (nonatomic, assign) BOOL statusFlushKeepRedundantRecords; // only record when status changed.

@property (nonatomic, assign) BOOL recordMemoryUsage;
@property (nonatomic, assign) BOOL recordCPUUsage;

+ (instancetype)shared;

- (void)wxr_addObserver:(nullable NSObject *)object forKey:(NSString *)key withHandler:(WXRocketUserDefaultChangedHandler)handler;
- (void)wxr_removeObserver:(NSObject *)observer forKey:(NSString *)key;

- (nullable id)objectForKey:(NSString *)defaultName;
- (void)setObject:(nullable id)value forKey:(NSString *)defaultName;

@end

NS_ASSUME_NONNULL_END
