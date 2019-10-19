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


#import "WXRocketUserDefaults.h"
#import "WXRocketUtility.h"

@interface MTHUserDefaultsObserverInfo : NSObject
@property (nonatomic, assign) NSInteger observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) WXRocketUserDefaultChangedHandler handler;
@end

@implementation MTHUserDefaultsObserverInfo
@end


@interface WXRocketUserDefaults ()

@property (nonatomic, strong) NSMutableDictionary *defaults;

@property (nonatomic, strong) NSMapTable<NSString *, NSMutableArray *> *observerHandlers;

@end

@implementation WXRocketUserDefaults

+ (instancetype)shared {
    static WXRocketUserDefaults *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:[self cachePath]];
        _defaults = defaults ? defaults.mutableCopy : @{}.mutableCopy;
        _observerHandlers = [NSMapTable strongToStrongObjectsMapTable];
        _recordMemoryUsage = YES;
        _recordCPUUsage = YES;
    }
    return self;
}

// MARK: -

- (void)wxr_addObserver:(NSObject *)object forKey:(NSString *)key withHandler:(WXRocketUserDefaultChangedHandler)handler {
    @synchronized(self.observerHandlers) {
        NSMutableArray *handlers = [self.observerHandlers objectForKey:key];
        if (handlers == nil) {
            handlers = @[].mutableCopy;
            [self.observerHandlers setObject:handlers forKey:key];
        }

        MTHUserDefaultsObserverInfo *observerInfo = [[MTHUserDefaultsObserverInfo alloc] init];
        observerInfo.observer = (NSInteger)object;
        observerInfo.key = key;
        observerInfo.handler = handler;
        [handlers addObject:observerInfo];
    }
}

- (void)wxr_removeObserver:(NSObject *)observer forKey:(NSString *)key {
    @synchronized(self.observerHandlers) {
        NSMutableArray *handlers = [self.observerHandlers objectForKey:key];
        for (MTHUserDefaultsObserverInfo *info in handlers) {
            if (info.observer == (NSInteger)observer) {
                [handlers removeObject:info];
                if (handlers.count == 0)
                    [self.observerHandlers removeObjectForKey:key];
                break;
            }
        }
    }
}

// MARK: -
- (void)setRocketOn:(BOOL)rocketOn {
    [self setObject:@(rocketOn) forKey:@"rocketOn"];
}

- (BOOL)rocketOn {
    NSNumber *on = [self objectForKey:@"rocketOn"];
    return on ? [on boolValue] : YES;
}

- (void)setStatusFlushIntevalInSeconds:(NSTimeInterval)statusFlushIntevalInSeconds {
    [self setObject:@(statusFlushIntevalInSeconds) forKey:@"statusFlushIntevalInSeconds"];
}

- (NSTimeInterval)statusFlushIntevalInSeconds {
    NSNumber *value = [self objectForKey:@"statusFlushIntevalInSeconds"];
    return value ? value.doubleValue : 0.5f;
}

- (void)setStatusFlushKeepRedundantRecords:(BOOL)statusFlushKeepRedundantRecords {
    [self setObject:@(statusFlushKeepRedundantRecords) forKey:@"statusFlushKeepRedundantRecords"];
}

- (BOOL)statusFlushKeepRedundantRecords {
    NSNumber *value = [self objectForKey:@"statusFlushKeepRedundantRecords"];
    return value ? value.boolValue : NO;
}

// MARK: -
- (nullable id)objectForKey:(NSString *)defaultName {
    @synchronized(self.defaults) {
        return [self.defaults objectForKey:defaultName];
    }
}

- (void)setObject:(nullable id)value forKey:(NSString *)defaultName {
    id oldValue = [self objectForKey:defaultName];
    if (oldValue == value)
        return;

    @synchronized(self.defaults) {
        if (value)
            [self.defaults setObject:value forKey:defaultName];
        else
            [self.defaults removeObjectForKey:defaultName];

        [self.defaults writeToFile:[self cachePath] atomically:NO];
    }

    @synchronized(self.observerHandlers) {
        NSEnumerator *keyEnumerator = [self.observerHandlers keyEnumerator];
        NSString *key;
        while ((key = [keyEnumerator nextObject])) {
            if ([key isEqualToString:defaultName]) {
                NSMutableArray<MTHUserDefaultsObserverInfo *> *handlers = [self.observerHandlers objectForKey:defaultName];
                [handlers enumerateObjectsUsingBlock:^(MTHUserDefaultsObserverInfo *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                    obj.handler(oldValue, value);
                }];
                break;
            }
        }
    }
}

- (NSString *)cachePath {
    return [[WXRocketUtility rocketStoreDirectory] stringByAppendingPathComponent:@"preferences"];
}

@end
