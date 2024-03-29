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


#import "WXRocketUserDefaults+CPUTrace.h"

@implementation WXRocketUserDefaults (CPUTrace)

- (void)setCpuTraceOn:(BOOL)cpuTraceOn {
    [self setObject:@(cpuTraceOn) forKey:NSStringFromSelector(@selector(cpuTraceOn))];
}

- (BOOL)cpuTraceOn {
    NSNumber *value = [self objectForKey:NSStringFromSelector(@selector(cpuTraceOn))];
    return value ? value.boolValue : YES;
}

- (void)setCpuTraceHighLoadThreshold:(CGFloat)cpuTraceRatioThreshold {
    [self setObject:@(cpuTraceRatioThreshold) forKey:NSStringFromSelector(@selector(cpuTraceHighLoadThreshold))];
}

- (CGFloat)cpuTraceHighLoadThreshold {
    NSNumber *value = [self objectForKey:NSStringFromSelector(@selector(cpuTraceHighLoadThreshold))];
    return value ? value.floatValue : 0.1f;
}

- (void)setCpuTraceCheckIntervalIdle:(CGFloat)checkIntervalIdle {
    [self setObject:@(checkIntervalIdle) forKey:NSStringFromSelector(@selector(cpuTraceCheckIntervalIdle))];
}

- (CGFloat)cpuTraceCheckIntervalIdle {
    NSNumber *value = [self objectForKey:NSStringFromSelector(@selector(cpuTraceCheckIntervalIdle))];
    return value ? value.floatValue : 1.0f;
}

- (void)setCpuTraceCheckIntervalBusy:(CGFloat)checkIntervalBusy {
    [self setObject:@(checkIntervalBusy) forKey:NSStringFromSelector(@selector(cpuTraceCheckIntervalBusy))];
}

- (CGFloat)cpuTraceCheckIntervalBusy {
    NSNumber *value = [self objectForKey:NSStringFromSelector(@selector(cpuTraceCheckIntervalBusy))];
    return value ? value.floatValue : 0.3f;
}

- (void)setCpuTraceHighLoadLastingLimit:(CGFloat)highLoadLastingLimit {
    [self setObject:@(highLoadLastingLimit) forKey:NSStringFromSelector(@selector(cpuTraceHighLoadLastingLimit))];
}

- (CGFloat)cpuTraceHighLoadLastingLimit {
    NSNumber *value = [self objectForKey:NSStringFromSelector(@selector(cpuTraceHighLoadLastingLimit))];
    return value ? value.floatValue : 10.0f;
}

- (void)setCpuTraceStackFramesDumpThreshold:(CGFloat)stackFrameDumpThreshold {
    [self setObject:@(stackFrameDumpThreshold) forKey:NSStringFromSelector(@selector(cpuTraceStackFramesDumpThreshold))];
}

- (CGFloat)cpuTraceStackFramesDumpThreshold {
    NSNumber *value = [self objectForKey:NSStringFromSelector(@selector(cpuTraceStackFramesDumpThreshold))];
    return value ? value.floatValue : 0.1f;
}

@end
