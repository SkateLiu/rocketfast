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

NS_ASSUME_NONNULL_BEGIN

@class WXRocketCPUTraceHighLoadRecord;
@interface WXRocketCPUTraceAdaptor : NSObject <WXRocketPlugin>

- (NSDictionary *)readCPUHighLoadStackFramesRecordsDict;
- (NSArray<WXRocketCPUTraceHighLoadRecord *> *)readHighLoadRecords;

@end

NS_ASSUME_NONNULL_END
