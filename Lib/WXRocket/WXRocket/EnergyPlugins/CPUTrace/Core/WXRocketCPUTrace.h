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


#import <UIKit/UIKit.h>
#include <vector>
#import "WXRocketCPUTraceHighLoadRecord.h"


@protocol WXRCPUTracingDelegate;

@interface WXRocketCPUTrace : NSObject

/**
 When the CPU is under low load, the frequency to check the CPU usage. default 1 second.
 */
@property (nonatomic, assign) CGFloat checkIntervalIdle;

/**
 When the CPU is under high load, the frequency to check the CPU usage. default 0.3 second.
 */
@property (nonatomic, assign) CGFloat checkIntervalBusy;

/**
 Only care when the CPU usage exceeding the threshold. default 80%
 */
@property (nonatomic, assign) CGFloat highLoadThreshold;

/**
 Only dump StackFrame of the thread when it's CPU usage exceeding the threshold while sampling. default 15%
 */
@property (nonatomic, assign) CGFloat stackFramesDumpThreshold;

/**
 Only generate record when the high load lasting longer than limit. default 60 seconds.
 */
@property (nonatomic, assign) CGFloat highLoadLastingLimit;


+ (instancetype)shareInstance;

- (void)addDelegate:(id<WXRCPUTracingDelegate>)delegate;
- (void)removeDelegate:(id<WXRCPUTracingDelegate>)delegate;

- (void)startTracing;
- (void)stopTracing;
- (BOOL)isTracing;

@end

/****************************************************************************/
#pragma mark -

@protocol WXRCPUTracingDelegate <NSObject>

- (void)cpuHighLoadRecordStartAt:(NSTimeInterval)startAt
       didUpdateStackFrameSample:(WXR_CPUTraceStackFramesNode *)stackframeRootNode
                 averageCPUUsage:(CGFloat)averageCPUUsage
                     lastingTime:(CGFloat)lastingTime;

- (void)cpuHighLoadRecordDidEnd;

@end
