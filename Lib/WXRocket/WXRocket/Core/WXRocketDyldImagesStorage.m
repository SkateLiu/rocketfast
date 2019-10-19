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


#import "WXRocketDyldImagesStorage.h"
#import "WXRocketStorage.h"
#import "WXRocketUtility.h"

#import <WXRocket/WXRocketDyldImagesUtils.h>
#import <WXRocket/WXRocketLogMacros.h>

@implementation WXRocketDyldImagesStorage

+ (void)asyncCacheDyldImagesInfoIfNeeded {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *path = [self currentStoragePath];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                wxra_setup_dyld_images_dumper_with_path(path);
            }
        });
    });
}

+ (NSDictionary *)cachedDyldImagesInfo {
    return [self cachedDyldImagesInfoAt:[self currentStoragePath]];
}

+ (NSDictionary *)previousSessionCachedDyldImagesInfo {
    NSString *prevSessionPath = [WXRocketUtility previousSessionStorePath];
    if (prevSessionPath.length == 0) return nil;
    return [self cachedDyldImagesInfoAt:[prevSessionPath stringByAppendingPathComponent:@"dyld-images"]];
}

+ (NSDictionary *)cachedDyldImagesInfoAt:(NSString *)dyldImagesCacheFilePath {
    NSString *dyldImagesInfoString = [[NSString alloc] initWithContentsOfFile:dyldImagesCacheFilePath encoding:NSUTF8StringEncoding error:nil];
    NSData *dyldImagesInfoData = [dyldImagesInfoString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dyldImagesDict = nil;
    if (dyldImagesInfoData) {
        NSError *error;
        dyldImagesDict = [NSJSONSerialization JSONObjectWithData:dyldImagesInfoData options:0 error:&error];
        if (error || ![dyldImagesDict isKindOfClass:[NSDictionary class]]) {
            MTHLogWarn(@"%@", [NSString stringWithFormat:@"convert dyld images file string to json failed: %@, at:%@", error, dyldImagesCacheFilePath]);
        }
    }
    return dyldImagesDict;
}

+ (NSString *)currentStoragePath {
    NSString *path = [[WXRocketUtility currentStorePath] stringByAppendingPathComponent:@"dyld-images"];
    return path;
}

@end
