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


#import "WXRocketCPUTraceAdaptor.h"
#import "WXRocketCPUTrace.h"
#import "WXRocketCPUTraceHighLoadRecord.h"
#import "WXRocketUserDefaults+CPUTrace.h"

#import <WXRocket/WXRocketDyldImagesStorage.h>
#import <WXRocket/WXRocketLogMacros.h>
#import <WXRocket/WXRocketStorage.h>
#import <WXRocket/WXRocketUserDefaults.h>


@interface WXRocketCPUTraceAdaptor () <WXRCPUTracingDelegate> {
    WXR_CPUTraceStackFramesNode *_currentSampleStackFrame;
}

@property (nonatomic, strong) WXRocketCPUTraceHighLoadRecord *currentRecord;

@end

@implementation WXRocketCPUTraceAdaptor

- (void)dealloc {
    [self unobserverCPUTraceRocketSetting];
    [self unObserveAppEnterBackground];
}

- (instancetype)init {
    if ((self = [super init])) {
        [self observerCPUTraceRocketSetting];
        [self unObserveAppEnterBackground];
    }
    return self;
}

+ (NSString *)pluginID {
    return @"cpu-tracer";
}

- (void)rocketClientDidStart {
    if (![WXRocketUserDefaults shared].cpuTraceOn)
        return;

    MTHLogInfo(@"cpu trace start");
    WXRocketCPUTrace *tracer = [WXRocketCPUTrace shareInstance];
    WXRocketUserDefaults *userDefault = [WXRocketUserDefaults shared];
    tracer.highLoadThreshold = userDefault.cpuTraceHighLoadThreshold;
    tracer.highLoadLastingLimit = userDefault.cpuTraceHighLoadLastingLimit;
    tracer.checkIntervalIdle = userDefault.cpuTraceCheckIntervalIdle;
    tracer.checkIntervalBusy = userDefault.cpuTraceCheckIntervalBusy;
    tracer.stackFramesDumpThreshold = userDefault.cpuTraceStackFramesDumpThreshold;
    [tracer startTracing];
    [tracer addDelegate:self];

    // needed for remote symbolics
    [WXRocketDyldImagesStorage asyncCacheDyldImagesInfoIfNeeded];
}

- (void)rocketClientDidStop {
    MTHLogInfo(@"cpu trace stop");

    [[WXRocketCPUTrace shareInstance] stopTracing];
    [[WXRocketCPUTrace shareInstance] removeDelegate:self];
}

// MARK: - MTHCPUTracingDelegate
- (void)cpuHighLoadRecordStartAt:(NSTimeInterval)startAt
       didUpdateStackFrameSample:(WXR_CPUTraceStackFramesNode *)stackframeRootNode
                 averageCPUUsage:(CGFloat)averageCPUUsage
                     lastingTime:(CGFloat)lastingTime {
    if (self.currentRecord == nil) {
        self.currentRecord = [[WXRocketCPUTraceHighLoadRecord alloc] init];
    }

    self.currentRecord.startAt = startAt;
    self.currentRecord.lasting = lastingTime;
    self.currentRecord.averageCPUUsage = averageCPUUsage;

    _currentSampleStackFrame = stackframeRootNode;
}

- (void)cpuHighLoadRecordDidEnd {
    [self writeLivingRecordIfNeed];
}

- (void)writeLivingRecordIfNeed {
    if (self.currentRecord.startAt > 0) {
        [self storeCPUHighLoadRecord:self.currentRecord stackFramesSample:_currentSampleStackFrame];
        self.currentRecord = nil;
    }
}

// MARK: - Storage

- (void)storeCPUHighLoadRecord:(WXRocketCPUTraceHighLoadRecord *)record stackFramesSample:(WXR_CPUTraceStackFramesNode *)stackFramesSample {
    NSString *key = [NSString stringWithFormat:@"%.2f", record.startAt];

    NSMutableDictionary *recordDict = @{}.mutableCopy;
    recordDict[@"start"] = key;
    recordDict[@"lasting"] = [NSString stringWithFormat:@"%.2f", record.lasting];
    recordDict[@"average"] = [NSString stringWithFormat:@"%.2f", record.averageCPUUsage * 100];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:recordDict options:0 error:nil];
    NSString *value = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    [[WXRocketStorage shared] asyncStoreValue:value withKey:key inCollection:@"cpu-highload"];
    [self storeCPUHighLoadStackFramesSample:stackFramesSample withKey:key];
}

- (void)storeCPUHighLoadStackFramesSample:(WXR_CPUTraceStackFramesNode *)rootNode withKey:(NSString *)key {
    NSString *sampleInJSON = rootNode->jsonString();
    if (sampleInJSON.length > 0) {
        if ([sampleInJSON lengthOfBytesUsingEncoding:NSUTF8StringEncoding] < 15 * 1024) {
            [[WXRocketStorage shared] asyncStoreValue:sampleInJSON withKey:key inCollection:@"cpu-highload-stackframe"];
        } else {
            [self _storeLongStackFramesInString:sampleInJSON withKey:key];
        }
    }
}

- (NSArray<WXRocketCPUTraceHighLoadRecord *> *)readHighLoadRecords {
    NSArray<NSString *> *keys;
    NSArray<NSString *> *values;
    [[WXRocketStorage shared] readKeyValuesInCollection:@"cpu-highload" keys:&keys values:&values];

    NSMutableArray<WXRocketCPUTraceHighLoadRecord *> *records = @[].mutableCopy;
    for (NSString *value in values) {
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (dict) {
            WXRocketCPUTraceHighLoadRecord *record = [[WXRocketCPUTraceHighLoadRecord alloc] init];
            record.startAt = [dict[@"start"] doubleValue];
            record.lasting = [dict[@"lasting"] doubleValue];
            record.averageCPUUsage = [dict[@"average"] doubleValue];
            [records addObject:record];
        } else {
            MTHLogWarn(@"read cpu high load record failed");
        }
    }
    return [records copy];
}

- (NSDictionary *)readCPUHighLoadStackFramesRecordsDict {
    NSArray *aKeys;
    NSArray *aValues;
    [[WXRocketStorage shared] readKeyValuesInCollection:@"cpu-highload-stackframe" keys:&aKeys values:&aValues];

    NSMutableArray *bKeys = @[].mutableCopy;
    NSMutableArray *bValues = @[].mutableCopy;
    NSArray<NSArray<NSString *> *> *bKeyValues = [self _readLongStackFramesFromFile];
    for (NSArray<NSString *> *keyValue in bKeyValues) {
        if (keyValue.count != 2)
            continue;

        [bKeys addObject:keyValue[0]];
        [bValues addObject:keyValue[1]];
    }

    NSMutableDictionary *dict = @{}.mutableCopy;
    for (NSInteger i = 0; i < aKeys.count && i < aValues.count; ++i) {
        dict[aKeys[i]] = aValues[i];
    }
    for (NSInteger i = 0; i < bKeys.count && i < bValues.count; ++i) {
        dict[bKeys[i]] = bValues[i];
    }

    return [dict copy];
}

- (void)_storeLongStackFramesInString:(NSString *)value withKey:(NSString *)key {
    dispatch_async([WXRocketStorage shared].storeQueue, ^{
        @autoreleasepool {
            NSString *content = [NSString stringWithFormat:@"%@,%@·", key, value];
            NSString *path = [self longFilePath];
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [content writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
                return;
            }
            NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
            if (data) {
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:path];
                @try {
                    [fileHandle seekToEndOfFile];
                    [fileHandle writeData:data];
                } @catch (NSException *exception) {
                    MTHLogWarn("store cpu trace recorded frames failed: %@", exception);
                } @finally {
                    [fileHandle closeFile];
                }
            }
        }
    });
}

- (NSArray<NSArray<NSString *> *> *)_readLongStackFramesFromFile {
    __block NSArray<NSString *> *keyValueRecords = nil;

    dispatch_sync([WXRocketStorage shared].storeQueue, ^{
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:[self longFilePath]];
        NSString *recordStr = [[NSString alloc] initWithData:[fileHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
        keyValueRecords = [recordStr componentsSeparatedByString:@"·"];
    });
    __block NSMutableArray *records = @[].mutableCopy;
    [keyValueRecords enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSArray *keyValue = [obj componentsSeparatedByString:@","];
        [records addObject:keyValue];
    }];

    return records;
}

- (NSString *)longFilePath {
    NSString *path = [NSString stringWithFormat:@"%@/%@", [WXRocketStorage shared].storeDirectory, @"cpu-highload-stackframe-ext"];
    return path;
}

// MARK: -
- (void)unObserveAppEnterBackground {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (void)observeAppEnterBackground {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *_Nonnull note) {
                                                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                          [self writeLivingRecordIfNeed];
                                                      });
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *_Nonnull note) {
                                                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                          [self writeLivingRecordIfNeed];
                                                      });
                                                  }];
}

// MARK: - CPUTrace Setting Observer

- (void)observerCPUTraceRocketSetting {
    __weak __typeof(self) weakSelf = self;
    [[WXRocketUserDefaults shared] wxr_addObserver:self
                                             forKey:NSStringFromSelector(@selector(cpuTraceOn))
                                        withHandler:^(id _Nullable oldValue, id _Nullable newValue) {
                                            if ([newValue boolValue])
                                                [weakSelf rocketClientDidStart];
                                            else
                                                [weakSelf rocketClientDidStop];
                                        }];
    [[WXRocketUserDefaults shared] wxr_addObserver:self
                                             forKey:NSStringFromSelector(@selector(cpuTraceHighLoadThreshold))
                                        withHandler:^(id _Nullable oldValue, id _Nullable newValue) {
                                            [WXRocketCPUTrace shareInstance].highLoadThreshold = [newValue doubleValue];
                                        }];
    [[WXRocketUserDefaults shared] wxr_addObserver:self
                                             forKey:NSStringFromSelector(@selector(cpuTraceCheckIntervalIdle))
                                        withHandler:^(id _Nullable oldValue, id _Nullable newValue) {
                                            [WXRocketCPUTrace shareInstance].checkIntervalIdle = [newValue doubleValue];
                                        }];
    [[WXRocketUserDefaults shared] wxr_addObserver:self
                                             forKey:NSStringFromSelector(@selector(cpuTraceCheckIntervalBusy))
                                        withHandler:^(id _Nullable oldValue, id _Nullable newValue) {
                                            [WXRocketCPUTrace shareInstance].checkIntervalBusy = [newValue doubleValue];
                                        }];
    [[WXRocketUserDefaults shared] wxr_addObserver:self
                                             forKey:NSStringFromSelector(@selector(cpuTraceHighLoadLastingLimit))
                                        withHandler:^(id _Nullable oldValue, id _Nullable newValue) {
                                            [WXRocketCPUTrace shareInstance].highLoadLastingLimit = [newValue doubleValue];
                                        }];
    [[WXRocketUserDefaults shared] wxr_addObserver:self
                                             forKey:NSStringFromSelector(@selector(cpuTraceStackFramesDumpThreshold))
                                        withHandler:^(id _Nullable oldValue, id _Nullable newValue) {
                                            [WXRocketCPUTrace shareInstance].stackFramesDumpThreshold = [newValue doubleValue];
                                        }];
}

- (void)unobserverCPUTraceRocketSetting {
    [[WXRocketUserDefaults shared] wxr_removeObserver:self forKey:NSStringFromSelector(@selector(cpuTraceOn))];
    [[WXRocketUserDefaults shared] wxr_removeObserver:self forKey:NSStringFromSelector(@selector(cpuTraceHighLoadThreshold))];
    [[WXRocketUserDefaults shared] wxr_removeObserver:self forKey:NSStringFromSelector(@selector(cpuTraceCheckIntervalIdle))];
    [[WXRocketUserDefaults shared] wxr_removeObserver:self forKey:NSStringFromSelector(@selector(cpuTraceHighLoadLastingLimit))];
    [[WXRocketUserDefaults shared] wxr_removeObserver:self forKey:NSStringFromSelector(@selector(cpuTraceStackFramesDumpThreshold))];
    [[WXRocketUserDefaults shared] wxr_removeObserver:self forKey:NSStringFromSelector(@selector(cpuTraceCheckIntervalBusy))];
}

@end
