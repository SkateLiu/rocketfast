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


#import "WXRocketClient.h"
#import "WXRocketAppStat.h"
#import "WXRocketLogMacros.h"
#import "WXRocketStorage.h"
#import "WXRocketUtility.h"


@interface WXRocketClient ()

@property (nonatomic, copy) WXRocketClientPluginsSetupHandler pluginsSetupHandler;
@property (nonatomic, copy) WXRocketClientPluginsCleanHandler pluginsCleanHandler;

@property (atomic, strong) NSArray<id<WXRocketPlugin>> *plugins;
@property (atomic, strong) NSArray<id<WXRocketPlugin>> *statusFlushPlugins;

@property (nonatomic, strong) dispatch_source_t statusFlushTimer;
@property (nonatomic, strong) dispatch_queue_t statusFlushQueue;

@property (nonatomic, assign) BOOL running;

@end


@implementation WXRocketClient

- (void)dealloc {
    [self unobserveAppActivity];
    [self unobserveUserDefaultsChange];
}

+ (instancetype)shared {
    static WXRocketClient *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        [self observeUserDefaultsChange];
        [self observeAppActivity];
    }
    return self;
}

- (void)addPlugin:(id<WXRocketPlugin>)plugin {
    NSMutableArray *plugins = self.plugins ? self.plugins.mutableCopy : @[].mutableCopy;
    [plugins addObject:plugin];
    self.plugins = plugins.copy;

    if ([plugin respondsToSelector:@selector(receivedFlushStatusCommand)]) {
        NSMutableArray *statusFlushPlugins = self.statusFlushPlugins ? self.statusFlushPlugins.mutableCopy : @[].mutableCopy;
        [statusFlushPlugins addObject:plugin];
        self.statusFlushPlugins = statusFlushPlugins.copy;
    }
}

- (void)removePlugin:(id<WXRocketPlugin>)plugin {
    if (![self.plugins containsObject:plugin])
        return;

    NSMutableArray *plugins = self.plugins ? self.plugins.mutableCopy : @[].mutableCopy;
    [plugins removeObject:plugin];
    self.plugins = plugins.copy;

    if (![self.statusFlushPlugins containsObject:plugin])
        return;

    NSMutableArray *statusFlushPlugins = self.statusFlushPlugins ? self.statusFlushPlugins.mutableCopy : @[].mutableCopy;
    [statusFlushPlugins removeObject:plugin];
    self.statusFlushPlugins = statusFlushPlugins;
}

- (nullable id<WXRocketPlugin>)pluginFromID:(NSString *)pluginID {
    NSInteger idx = [self.plugins indexOfObjectPassingTest:^BOOL(id<WXRocketPlugin> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        return [[[obj class] pluginID] isEqualToString:pluginID];
    }];
    if (idx == NSNotFound)
        return nil;
    else
        return self.plugins[idx];
}

// MARK: -

- (void)setPluginsSetupHandler:(WXRocketClientPluginsSetupHandler)pluginsSetupHandler
           pluginsCleanHandler:(WXRocketClientPluginsCleanHandler)pluginsCleanHandler {
    self.pluginsSetupHandler = pluginsSetupHandler;
    self.pluginsCleanHandler = pluginsCleanHandler;
}

- (void)startServer {
    if (![WXRocketUserDefaults shared].rocketOn)
        return;

    [self doStart];
}

- (void)stopServer {
    [self doStop];
}

- (void)doStart {
    if (self.running)
        return;

    self.running = YES;
    MTHLogInfo(@"----- rocket client start -----");

    if (self.pluginsSetupHandler) {
        NSMutableArray *plugins = self.plugins ? [self.plugins mutableCopy] : @[].mutableCopy;
        self.pluginsSetupHandler(plugins);

        NSMutableArray *statusFlushPlugins = @[].mutableCopy;
        for (id<WXRocketPlugin> plugin in plugins) {
            if ([plugin respondsToSelector:@selector(receivedFlushStatusCommand)]) {
                [statusFlushPlugins addObject:plugin];
            }
        }
        self.plugins = [plugins copy];
        self.statusFlushPlugins = [statusFlushPlugins copy];
    }

    // if a plugin need start earlier, it should load it earlier by itself.
    [self.plugins makeObjectsPerformSelector:@selector(rocketClientDidStart)];

    [self startStatusFlushTimer];
}

- (void)doStop {
    if (!self.running)
        return;

    self.running = NO;

    [self stopStatusFlushTimer];

    [self.plugins makeObjectsPerformSelector:@selector(rocketClientDidStop)];

    if (self.pluginsCleanHandler) {
        NSMutableArray *plugins = self.plugins ? [self.plugins mutableCopy] : @[].mutableCopy;
        self.pluginsCleanHandler(plugins);

        self.plugins = plugins;
        self.statusFlushPlugins = nil;
    }

    MTHLogInfo(@"----- rocket client stopped -----");
}

- (void)startStatusFlushTimer {
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
    self.statusFlushQueue = dispatch_queue_create("com.tt.rocket.status_flush", attr);
    self.statusFlushTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.statusFlushQueue);

    // Need Improve: if you need to change statusFlushIntevalInSeconds, config it before start.
    uint64_t interval = [WXRocketUserDefaults shared].statusFlushIntevalInSeconds * NSEC_PER_SEC;
    dispatch_source_set_timer(self.statusFlushTimer, DISPATCH_TIME_NOW, interval, 0);
    dispatch_source_set_event_handler(self.statusFlushTimer, ^{
        @autoreleasepool {
            [self statusFlushTimerFired];
        }
    });
    dispatch_resume(self.statusFlushTimer);
}

- (void)stopStatusFlushTimer {
    if (self.statusFlushTimer) {
        dispatch_source_cancel(self.statusFlushTimer);
        self.statusFlushTimer = nil;
        self.statusFlushQueue = nil;
    }
}

- (void)statusFlushTimerFired {
    [self doBuildInFlushStatusTasks];

    [self.statusFlushPlugins enumerateObjectsUsingBlock:^(id<WXRocketPlugin> _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [obj receivedFlushStatusCommand];
    }];
}

- (void)doBuildInFlushStatusTasks {
    NSString *time = [NSString stringWithFormat:@"%@", @([WXRocketUtility currentTime])];
    BOOL forceFlush = [WXRocketUserDefaults shared].statusFlushKeepRedundantRecords;

    // record memory usage
    if ([WXRocketUserDefaults shared].recordMemoryUsage) {
        static CGFloat preResident = 0.f;
        static CGFloat preMemFootprint = 0.f;
        CGFloat resident = WXRocketAppStat.memoryAppUsed / 1024.f / 1024.f;
        CGFloat memFootprint = WXRocketAppStat.memoryFootprint / 1024.f / 1024.f;
        if (forceFlush || (fabs(resident - preResident) > DBL_EPSILON) || (fabs(memFootprint - preMemFootprint) > DBL_EPSILON)) {
            preResident = resident;
            preMemFootprint = memFootprint;

            NSString *residentStr = [NSString stringWithFormat:@"%.2f", resident];
            NSString *memFootprintStr = [NSString stringWithFormat:@"%.2f", memFootprint];

            [[WXRocketStorage shared] asyncStoreValue:residentStr withKey:time inCollection:@"mem"];
            [[WXRocketStorage shared] asyncStoreValue:memFootprintStr withKey:time inCollection:@"r-mem"];
        }
    }

    // record cpu usage
    if ([WXRocketUserDefaults shared].recordCPUUsage) {
        static double preCPUUsage = 0.f;
        double cpuUsage = WXRocketAppStat.cpuUsedByAllThreads;
        if (forceFlush || (fabs(cpuUsage - preCPUUsage) > DBL_EPSILON)) {
            preCPUUsage = cpuUsage;

            NSString *cpuUsageStr = [NSString stringWithFormat:@"%.1f", cpuUsage * 100.f];
            [[WXRocketStorage shared] asyncStoreValue:cpuUsageStr withKey:time inCollection:@"cpu"];
        }
    }
}

// MARK: - AppLife Observe
- (void)observeAppActivity {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidEnterBackgroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *_Nonnull note) {
                    [self stopStatusFlushTimer];
                }];

    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationWillEnterForegroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *_Nonnull note) {
                    if ([WXRocketUserDefaults shared].rocketOn) {
                        [self stopStatusFlushTimer];
                        [self startStatusFlushTimer];
                    }
                }];
}

- (void)unobserveAppActivity {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

// MARK: - UserDefaults Observe
- (void)observeUserDefaultsChange {
    __weak __typeof(self) weakSelf = self;
    [[WXRocketUserDefaults shared]
        wxr_addObserver:self
                 forKey:NSStringFromSelector(@selector(rocketOn))
            withHandler:^(id _Nullable oldValue, id _Nullable newValue) {
                if ([newValue boolValue]) {
                    [weakSelf doStart];
                } else {
                    [weakSelf doStop];
                }
            }];
}

- (void)unobserveUserDefaultsChange {
    [[WXRocketUserDefaults shared] wxr_removeObserver:self forKey:NSStringFromSelector(@selector(rocketOn))];
}

@end
