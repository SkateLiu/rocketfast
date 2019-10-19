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
#import <mach/mach.h>
#import <vector>

NS_ASSUME_NONNULL_BEGIN

struct WXR_CPUTraceThreadIdAndUsage {
    thread_t traceThread;
    double cpuUsage;
};

class WXR_CPUTraceStackFramesNode
{
  public:
    uintptr_t stackframeAddr = 0;
    uint32_t calledCount = 0;

    std::vector<WXR_CPUTraceStackFramesNode *> children;

  public:
    WXR_CPUTraceStackFramesNode(){};
    ~WXR_CPUTraceStackFramesNode(){};

    void resetSubCalls();
    inline bool isEquralToStackFrameNode(WXR_CPUTraceStackFramesNode *node) {
        return this->stackframeAddr == node->stackframeAddr;
    };

    WXR_CPUTraceStackFramesNode *addSubCallNode(WXR_CPUTraceStackFramesNode *node);

    NSArray<NSDictionary *> *json();
    NSString *jsonString();
};


@interface WXRocketCPUTraceHighLoadRecord : NSObject

@property (nonatomic, assign) CFAbsoluteTime startAt; /**< The cpu high load record start at. */
@property (nonatomic, assign) CFAbsoluteTime lasting; /**< How long the cpu high load lasting */
@property (nonatomic, assign) float averageCPUUsage;  /**< The average cpu usage during the high load */

@end

NS_ASSUME_NONNULL_END
