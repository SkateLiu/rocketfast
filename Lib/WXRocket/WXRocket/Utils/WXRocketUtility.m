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


#import "WXRocketUtility.h"
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <sys/time.h>
#import <zlib.h>

static NSInteger underUnitTest = -1;

static NSString *gWXRocketRootDirectoryName = @"/com.tt.rocket";

#if WXRocket_Store_Under_LibraryCache
WXRocketStoreDirectoryOption gWXRocketStoreDirectoryRoot = WXRocketStoreDirectoryOptionLibraryCaches;
#elif WXRocket_Store_Under_Tmp
WXRocketStoreDirectoryOption gWXRocketStoreDirectoryRoot = WXRocketStoreDirectoryOptionTmp;
#else
WXRocketDirectoryOption gWXRocketStoreDirectoryRoot = WXRocketStoreDirectoryOptionDocument;
#endif

@implementation WXRocketUtility

+ (BOOL)underUnitTest {
    if (underUnitTest == -1) {
        if ([NSProcessInfo processInfo].environment[@"XCInjectBundleInto"] != nil)
            underUnitTest = 1;
        else
            underUnitTest = 0;
    }
    return underUnitTest == 1 ? YES : NO;
}

+ (double)currentTime {
    struct timeval t0;
    gettimeofday(&t0, NULL);
    return t0.tv_sec + t0.tv_usec * 1e-6;
}

+ (NSTimeInterval)appLaunchedTime {
    static NSTimeInterval appLaunchedTime;
    if (appLaunchedTime == 0.f) {
        struct kinfo_proc procInfo;
        size_t structSize = sizeof(procInfo);
        int mib[] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()};

        if (sysctl(mib, sizeof(mib) / sizeof(*mib), &procInfo, &structSize, NULL, 0) != 0) {
            NSLog(@"sysctrl failed");
            appLaunchedTime = [[NSDate date] timeIntervalSince1970];
        } else {
            struct timeval t = procInfo.kp_proc.p_un.__p_starttime;
            appLaunchedTime = t.tv_sec + t.tv_usec * 1e-6;
        }
    }
    return appLaunchedTime;
}

+ (NSString *)rocketStoreDirectory {
    if (gWXRocketStoreDirectoryRoot == WXRocketStoreDirectoryOptionDocument)
        return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:gWXRocketRootDirectoryName];
    else if (gWXRocketStoreDirectoryRoot == WXRocketStoreDirectoryOptionLibraryCaches)
        return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:gWXRocketRootDirectoryName];
    else if (gWXRocketStoreDirectoryRoot == WXRocketStoreDirectoryOptionTmp)
        return [NSTemporaryDirectory() stringByAppendingPathComponent:gWXRocketRootDirectoryName];
    else
        return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:gWXRocketRootDirectoryName];
}

+ (NSString *)currentStoreDirectoryNameFormat {
    return @"yyyy-MM-dd_HH-mm-ss+SSS";
}

+ (NSString *)currentStorePath {
    static dispatch_once_t onceToken;
    static NSString *storeDirectory;
    dispatch_once(&onceToken, ^{
        NSString *rocketPath = [WXRocketUtility rocketStoreDirectory];
        NSString *formattedDateString = [self currentStorePathLastComponent];
        storeDirectory = [rocketPath stringByAppendingPathComponent:formattedDateString];
    });
    return storeDirectory;
}

+ (NSString *)currentStorePathLastComponent {
    NSTimeInterval appLaunchedTime = [WXRocketUtility appLaunchedTime];
    NSDate *launchedDate = [NSDate dateWithTimeIntervalSince1970:appLaunchedTime];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:[self currentStoreDirectoryNameFormat]];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *formattedDateString = [dateFormatter stringFromDate:launchedDate];
    return formattedDateString;
}

+ (NSString *)previousSessionStorePath {
    static dispatch_once_t onceToken;
    static NSString *preStoreDirectory = nil;
    dispatch_once(&onceToken, ^{
        NSString *rocketPath = [WXRocketUtility rocketStoreDirectory];
        NSArray<NSString *> *logDirectories = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:rocketPath error:NULL];

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[WXRocketUtility currentStoreDirectoryNameFormat]];
        [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];

        NSIndexSet *cachesIndexSet = [logDirectories
            indexesOfObjectsWithOptions:0
                            passingTest:^BOOL(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                NSDate *createDate = [dateFormatter dateFromString:obj];
                                return createDate ? YES : NO;
                            }];
        logDirectories = [logDirectories objectsAtIndexes:cachesIndexSet];
        logDirectories = [logDirectories sortedArrayUsingComparator:^NSComparisonResult(NSString *_Nonnull obj1, NSString *_Nonnull obj2) {
            return [obj2 compare:obj1];
        }];

        NSString *currentSessionDirName = [self currentStorePathLastComponent];
        // in case current session directory not creat yet.
        if ([logDirectories.firstObject isEqualToString:currentSessionDirName]) {
            if (logDirectories.count >= 2) {
                preStoreDirectory = [rocketPath stringByAppendingPathComponent:logDirectories[1]];
            }
        } else {
            preStoreDirectory = [rocketPath stringByAppendingPathComponent:[logDirectories firstObject]];
        }
    });
    return preStoreDirectory;
}

@end
