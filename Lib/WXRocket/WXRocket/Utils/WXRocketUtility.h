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
#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    WXRocketStoreDirectoryOptionDocument,      /**< Document/ */
    WXRocketStoreDirectoryOptionLibraryCaches, /**< Library/Caches */
    WXRocketStoreDirectoryOptionTmp,           /**< tmp/ */
} WXRocketDirectoryOption;

// clang-format off
#ifndef WXRocket_Store_Under_LibraryCache
#  define WXRocket_Store_Under_LibraryCache 0
#endif

#ifndef WXRocket_Store_Under_Tmp
#  define WXRocket_Store_Under_Tmp 0
#endif
// clang-format on

/*
 default Document/
 define MACRO `WXRocket_Store_Under_LibraryCache 1` to use `Library/Cache`
 define MACRO `WXRocket_Store_Under_Tmp 1` to use `tmp`
 */
extern WXRocketDirectoryOption gWXRocketStoreDirectoryRoot; /**< default WXRocketStoreDirectoryOptionDocument */

@interface WXRocketUtility : NSObject

+ (BOOL)underUnitTest;

+ (double)currentTime;
+ (NSTimeInterval)appLaunchedTime;

+ (NSString *)rocketStoreDirectory;           /**< Rocket Cache Files Root: default /Document/com.tt.rocket/, see gWXRocketStoreDirectoryRoot for detail */
+ (NSString *)currentStoreDirectoryNameFormat; /**< yyyy-MM-dd_HH:mm:ss+SSS */
+ (NSString *)currentStorePath;                /**< Current Session Rocket cache directory, default /Document/com.tt.rocket/yyyy-MM-dd_HH:mm:ss+SSS */
+ (NSString *)previousSessionStorePath;        /**< Previous session Rocket cache directory, find by convert directory name into time in desc order. */

@end
