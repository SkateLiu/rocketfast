//
// Copyright (c) 2019-present, TT, Inc.
// All rights reserved.
//
// Created on: 2019/10/18
// Created by: TT
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WXRocketAppStat : NSObject

/// Used memory by app in byte. ( task_basic_info.resident_size )
@property (nonatomic, readonly, class) int64_t memoryAppUsed;

/* The real physical memory used by app.
 - https://stackoverflow.com/questions/9660763/whats-the-right-statistic-for-ios-memory-footprint-live-bytes-real-memory-ot
 - https://developer.apple.com/library/archive/technotes/tn2434/_index.html
 */
@property (nonatomic, readonly, class) int64_t memoryFootprint;

@property (nonatomic, readonly, class) double cpuUsedByAllThreads;

@end

NS_ASSUME_NONNULL_END
