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


#import "WXRocketCPUTrace.h"

#import <assert.h>
#import <mach/mach.h>
#import <mach/mach_types.h>
#import <pthread.h>

#import <WXRocket/WXRocketStackFrameSymbolics.h>
#import <WXRocket/WXRocketDyldImagesUtils.h>
#import <WXRocket/WXRocketLogMacros.h>
#import <WXRocket/WXRocketSignPosts.h>
#import <WXRocket/wxr_stack_backtrace.h>

#import "WXRocketCPUTraceHighLoadRecord.h"


#define WXRocketCPUTrace_MAXSTACKCOUNT 50


@interface WXRocketCPUTrace ()

@property (nonatomic, assign) BOOL isTracing;

@property (nonatomic, strong) NSHashTable<id<WXRCPUTracingDelegate>> *delegates;

@property (nonatomic, strong) dispatch_source_t cpuTracingTimer;
@property (nonatomic, strong) dispatch_queue_t cpuTracingQueue;

@property (nonatomic, assign) CFAbsoluteTime highLoadBeginTime;
@property (nonatomic, assign) NSTimeInterval highLoadLastingTime;

@property (nonatomic, assign) BOOL exceedingHighLoadThreshold;
@property (nonatomic, assign) BOOL exceedingHighLoadLastingLimit;

@property (nonatomic, assign) CFAbsoluteTime highLoadLastingSumUsage;

@property (nonatomic, assign) BOOL ptrToSkipFound;

@end

@implementation WXRocketCPUTrace {
    std::vector<wxr_stack_backtrace *> _cpuHighLoadStackFramesSample;

    WXR_CPUTraceThreadIdAndUsage *_threadIdAndUsageBuffers;
    uint8_t _threadIdAndUsageBuffersLength;

    WXR_CPUTraceStackFramesNode *_rootNode;
    uintptr_t _ptrToSkip;
}

- (void)dealloc {
    [self unobserveAppActivity];

    if (_threadIdAndUsageBuffers) {
        free(_threadIdAndUsageBuffers);
        _threadIdAndUsageBuffers = nil;
    }

    [self clearStackFramesSample];

    self.cpuTracingQueue = nil;
}

+ (instancetype)shareInstance {
    static WXRocketCPUTrace *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WXRocketCPUTrace alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.checkIntervalIdle = 1;
        self.checkIntervalBusy = 0.3;
        self.highLoadLastingLimit = 60;
        self.highLoadThreshold = 0.8;
        self.stackFramesDumpThreshold = 0.15;
        self.ptrToSkipFound = NO;

        self.delegates = [NSHashTable weakObjectsHashTable];

        _threadIdAndUsageBuffersLength = 128;
        _threadIdAndUsageBuffers = (WXR_CPUTraceThreadIdAndUsage *)malloc(sizeof(WXR_CPUTraceThreadIdAndUsage) * _threadIdAndUsageBuffersLength);

        [self observeAppActivity];
    }
    return self;
}

- (void)addDelegate:(id<WXRCPUTracingDelegate>)delegate {
    @synchronized(self.delegates) {
        [self.delegates addObject:delegate];
    }
}

- (void)removeDelegate:(id<WXRCPUTracingDelegate>)delegate {
    @synchronized(self.delegates) {
        [self.delegates removeObject:delegate];
    }
}

// MARK: -
- (void)startTracing {
    if (!self.cpuTracingQueue) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
        self.cpuTracingQueue = dispatch_queue_create("com.tt.rocket.cpu_trace", attr);
    }

    [self changeTimerIntervalTo:self.checkIntervalIdle];
    self.isTracing = YES;
}

- (void)stopTracing {
    [self stopTimerIfNeed];
    self.cpuTracingQueue = nil;
    self.isTracing = NO;
}

- (void)changeTimerIntervalTo:(CGFloat)timerIntervalInSec {
    [self stopTimerIfNeed];

    NSAssert(self.cpuTracingQueue, @"you should init queue firstly");

    self.cpuTracingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.cpuTracingQueue);
    dispatch_source_set_timer(self.cpuTracingTimer, DISPATCH_TIME_NOW, timerIntervalInSec * NSEC_PER_SEC, 0);

    dispatch_source_set_event_handler(self.cpuTracingTimer, ^{
        @autoreleasepool {
            [self cpuInspectTaskFired];
        }
    });
    dispatch_resume(self.cpuTracingTimer);
}

- (void)stopTimerIfNeed {
    if (self.cpuTracingTimer) {
        dispatch_source_cancel(self.cpuTracingTimer);
        self.cpuTracingTimer = nil;
    }
}

// MARK: -
- (void)resetState {
    self.highLoadBeginTime = 0.f;
    self.highLoadLastingTime = 0.f;
    self.highLoadLastingSumUsage = 0.f;

    self.exceedingHighLoadThreshold = NO;
    self.exceedingHighLoadLastingLimit = NO;

    [self clearStackFramesSample];

    _rootNode = new WXR_CPUTraceStackFramesNode();
}

- (void)clearStackFramesSample {
    if (_cpuHighLoadStackFramesSample.size() != 0) {
        for (auto iter = _cpuHighLoadStackFramesSample.begin(); iter != _cpuHighLoadStackFramesSample.end(); iter++) {
            wxr_stack_backtrace *stackframes = (*iter);
            wxr_free_stack_backtrace(stackframes);
        }
        _cpuHighLoadStackFramesSample.clear();
    }

    if (_rootNode) {
        _rootNode->resetSubCalls();

        delete _rootNode;
        _rootNode = nil;
    }
}

- (void)cpuInspectTaskFired {
    if (!self.ptrToSkipFound) {
        // skip recording cpu_trace thread.
        wxr_stack_backtrace *stackframes = wxr_malloc_stack_backtrace();
        wxr_stack_backtrace_of_thread(mach_thread_self(), stackframes, WXRocketCPUTrace_MAXSTACKCOUNT, 0);
        if (stackframes && stackframes->frames_size > 4) {
            _ptrToSkip = stackframes->frames[5];
            self.ptrToSkipFound = YES;
        }

        wxr_free_stack_backtrace(stackframes);
    }

    double cpuUsage = 0.0f;
    unsigned int threadsCount = 0;

    [self getAllThreadCpuUsage:&cpuUsage theadsDetail:_threadIdAndUsageBuffers threadsCount:&threadsCount maxThreadCount:_threadIdAndUsageBuffersLength];



    if (cpuUsage >= self.highLoadThreshold) {

        if (!self.exceedingHighLoadThreshold) {
            [self resetState];

            self.exceedingHighLoadThreshold = YES;

            [self changeTimerIntervalTo:self.checkIntervalBusy];

            self.highLoadBeginTime = CFAbsoluteTimeGetCurrent();
        }

        self.highLoadLastingSumUsage += cpuUsage;


        [self stackFramesFromThreads:_threadIdAndUsageBuffers
                               count:threadsCount
                   withTotalCPUUsage:cpuUsage];


        double lastingTime = CFAbsoluteTimeGetCurrent() - self.highLoadBeginTime;

        if (lastingTime > self.highLoadLastingLimit) {
            self.exceedingHighLoadLastingLimit = YES;
            self.highLoadLastingTime = lastingTime;

            // update stack frame, usage list, lasting time, and notify caller.
            [self generateOrUpdateCPUHighLoadRecord];

        }
    } else { // cpuUsage < self.highLoadThreshold

        if (self.exceedingHighLoadLastingLimit && self.exceedingHighLoadThreshold) {
            @synchronized(self.delegates) {
                for (id<WXRCPUTracingDelegate> delegate in self.delegates) {
                    [delegate cpuHighLoadRecordDidEnd];
                }
            }
        }

        BOOL shouldResetToIdleState = self.exceedingHighLoadThreshold;
        if (shouldResetToIdleState) {
            [self resetState];

            [self changeTimerIntervalTo:self.checkIntervalIdle];
        }
    }
}

- (void)stackFramesFromThreads:(WXR_CPUTraceThreadIdAndUsage *)threadInfos
                         count:(uint)threadCount
             withTotalCPUUsage:(double)cpuTotalUsage {
    /*
     performance:
     iPhone6s 10.3.2 release
        avg: 157us
     */

    for (int i = 0; i < threadCount; i++) {
        WXR_CPUTraceThreadIdAndUsage threadInfo = threadInfos[i];

        // only dump stack frames from the thread when the proportion is higher then threshold.
        if ((threadInfo.cpuUsage / cpuTotalUsage) > self.stackFramesDumpThreshold) {
            // get the stack frames of the thread
            wxr_stack_backtrace *stackframes = wxr_malloc_stack_backtrace();
            if (wxr_stack_backtrace_of_thread(threadInfo.traceThread, stackframes, WXRocketCPUTrace_MAXSTACKCOUNT, 0)) {
                BOOL shouldSkip = NO;
                for (int i = 0; i < stackframes->frames_size; i++) {
                    if (stackframes->frames[i] == _ptrToSkip) {
                        shouldSkip = YES;
                        break;
                    }
                }

                if (!shouldSkip) {
                    _cpuHighLoadStackFramesSample.push_back(stackframes);
                } else {
                    wxr_free_stack_backtrace(stackframes);
                }
            } else {
                wxr_free_stack_backtrace(stackframes);
            }
        }
    }
}

- (void)generateOrUpdateCPUHighLoadRecord {
    for (auto iter = _cpuHighLoadStackFramesSample.begin(); iter != _cpuHighLoadStackFramesSample.end(); iter++) {
        wxr_stack_backtrace *stackframes = (*iter);
        WXR_CPUTraceStackFramesNode *curNode = _rootNode;
        int continueCount = 0;
        int size = (int)stackframes->frames_size;
        for (int i = size - 1; i >= 0; i--) {
            // skip system stack frame.
            if (wxra_addr_is_in_sys_libraries(stackframes->frames[i])) {
                continueCount++;
                continue;
            }

            WXR_CPUTraceStackFramesNode *tmpNode = new WXR_CPUTraceStackFramesNode();
            tmpNode->stackframeAddr = stackframes->frames[i];
            tmpNode->calledCount = 0;

            curNode = curNode->addSubCallNode(tmpNode);
            if (curNode->calledCount > 1) {
                delete tmpNode;
            }
        }

        wxr_free_stack_backtrace(stackframes);
    }

    _cpuHighLoadStackFramesSample.clear();

    CGFloat averageUsage = (self.highLoadLastingSumUsage / (self.highLoadLastingTime / self.checkIntervalBusy));
    CGFloat lasting = CFAbsoluteTimeGetCurrent() - self.highLoadBeginTime;

    @synchronized(self.delegates) {
        for (id<WXRCPUTracingDelegate> delegate in self.delegates) {
            [delegate cpuHighLoadRecordStartAt:self.highLoadBeginTime
                     didUpdateStackFrameSample:_rootNode
                               averageCPUUsage:averageUsage
                                   lastingTime:lasting];
        }
    }
}

- (void)getAllThreadCpuUsage:(double *)p_totalUsage
                theadsDetail:(WXR_CPUTraceThreadIdAndUsage *)p_threads
                threadsCount:(unsigned int *)p_threadsCount
              maxThreadCount:(uint8_t)maxThreadCount {
    double totalUsageRatio = 0.0;

    thread_info_data_t thinfo;
    thread_act_array_t threads;
    thread_basic_info_t basic_info_t;

    mach_msg_type_number_t count = 0;
    mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;

    if (task_threads(mach_task_self(), &threads, &count) == KERN_SUCCESS) {
        for (int idx = 0; idx < count && idx < maxThreadCount; idx++) {
            double cpuUsage = 0.0;
            if (thread_info(threads[idx], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count) == KERN_SUCCESS) {
                basic_info_t = (thread_basic_info_t)thinfo;
                if (!(basic_info_t->flags & TH_FLAGS_IDLE)) {
                    cpuUsage = basic_info_t->cpu_usage / (double)TH_USAGE_SCALE;
                }
            }

            p_threads[idx].traceThread = threads[idx];
            p_threads[idx].cpuUsage = cpuUsage;

            totalUsageRatio += cpuUsage;
        }
        assert(vm_deallocate(mach_task_self(), (vm_address_t)threads, count * sizeof(thread_t)) == KERN_SUCCESS);
    }
    *p_totalUsage = totalUsageRatio;
    if (p_threadsCount) {
        *p_threadsCount = count;
    }
}

// MARK: -
- (void)observeAppActivity {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidEnterBackgroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *_Nonnull note) {
                    [self stopTimerIfNeed];
                }];

    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationWillEnterForegroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *_Nonnull note) {
                    if (self.isTracing) {
                        [self stopTimerIfNeed];
                        [self startTracing];
                    }
                }];
}

- (void)unobserveAppActivity {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

@end
