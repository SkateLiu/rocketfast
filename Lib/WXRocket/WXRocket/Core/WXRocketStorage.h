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

NS_ASSUME_NONNULL_BEGIN

extern NSTimeInterval kWXRocketLogExpiredTime;                     /**< default: 1 week */
extern NSString *const kWXRocketCollectionKeyValueRecordsFileName; /**< "records" */
extern NSUInteger kWXRocketLogStoreMaxLength;// Limit in 16 KB for each one append action

/****************************************************************************/
#pragma mark -

@class WXRocketStorageObject;

typedef void (^WXRocketStoragePageFilterBlock)(NSUInteger index, NSArray<WXRocketStorageObject *> *recordsInThisPage);
typedef NS_ENUM(NSUInteger, WXRocketStorageOrderType) {
    kWXRocketStorageOrderTypeAscending,
    kWXRocketStorageOrderTypeDescending
};

@interface WXRocketStorageObject : NSObject

@property (nonatomic, copy) NSString *collection;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *string;

+ (WXRocketStorageObject *)createObjectWithCollection:(NSString *)collection key:(NSString *)key string:(NSString *)string;

@end



/****************************************************************************/
#pragma mark -


@interface WXRocketStorage : NSObject

@property (nonatomic, copy, readonly) NSString *storeDirectory;
@property (nonatomic, strong, readonly) dispatch_queue_t storeQueue;

@property (nonatomic, assign) NSUInteger pageSize;
@property (nonatomic, assign, readonly) NSRange availablePages;

+ (instancetype)shared;

/**
 len((collection + value + key) -> char) should < 16K
 */
- (void)syncStoreValue:(NSString *)value withKey:(NSString *)key inCollection:(NSString *)collection;
- (void)asyncStoreValue:(NSString *)value withKey:(NSString *)key inCollection:(NSString *)collection;

- (NSUInteger)readKeyValuesInCollection:(NSString *)collection
                                   keys:(NSArray<NSString *> *_Nullable __autoreleasing *_Nullable)outKeys
                                 values:(NSArray<NSString *> *_Nullable __autoreleasing *_Nullable)outStrings;

/**
 *  read record using page filter
 *
 *  @param  pageRange           page range for reading, each page content multiple lines of string
 *  @param  inCollection        return this type of collection records in the pageRange content, if nil return all types of collection record
 *  @param  orderBy             will sort all contens between startPage to lastPage
 *  @param  usingBlock          processing bolck, will call multiple times for pageRange
 */
- (void)readKeyValuesInPageRange:(NSRange)pageRange
                    inCollection:(NSString *__nullable)inCollection
                         orderBy:(WXRocketStorageOrderType)orderBy
                      usingBlock:(WXRocketStoragePageFilterBlock)usingBlock;

@end

NS_ASSUME_NONNULL_END
