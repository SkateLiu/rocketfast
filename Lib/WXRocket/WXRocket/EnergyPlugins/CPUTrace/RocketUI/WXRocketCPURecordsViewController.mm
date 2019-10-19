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


#import "WXRocketCPURecordsViewController.h"
#import <WXRocket/WXRocketStackFrameSymbolics.h>
#import <WXRocket/WXRocketStackFrameSymbolicsRemote.h>
#import <WXRocket/WXRocketClient.h>
#import <WXRocket/WXRocketDyldImagesStorage.h>
#import <WXRocket/WXRocketDyldImagesUtils.h>
#import <WXRocket/WXRocketLogMacros.h>

#import <WXRocket/WXRocketStorage.h>

#import "WXRocketCPUTrace.h"
#import "WXRocketCPUTraceAdaptor.h"
#import "WXRocketWebViewController.h"


@interface WXRocketCPURecordsViewController () <WXRCPUTracingDelegate, UITableViewDelegate, UITableViewDataSource> {
    WXRocketStackFrameSymbolics *_stackHelper;
    WXR_CPUTraceStackFramesNode *_livingRecordStackFrameSample;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) NSInteger detailLoadingIndex;

@property (nonatomic, assign) BOOL recordsDataLoading;
@property (nonatomic, copy) NSArray<WXRocketCPUTraceHighLoadRecord *> *records;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *stackFramesSampleDict;

@property (nonatomic, strong) WXRocketCPUTraceHighLoadRecord *livingRecord;

@end


@implementation WXRocketCPURecordsViewController

- (void)dealloc {
    [[WXRocketCPUTrace shareInstance] removeDelegate:self];

    if (_stackHelper) {
        delete _stackHelper;
        _stackHelper = nil;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"CPU Records";

    self.detailLoadingIndex = -1;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view = self.tableView;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"tt-rocket-setting"];

    [self loadRecordsData];
}

- (void)loadRecordsData {
    self.recordsDataLoading = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^(void) {
        WXRocketCPUTraceAdaptor *cpuTraceAdaptor = [[WXRocketClient shared] pluginFromID:[WXRocketCPUTraceAdaptor pluginID]];
        self.records = [[[cpuTraceAdaptor readHighLoadRecords] reverseObjectEnumerator] allObjects];
        self.stackFramesSampleDict = [cpuTraceAdaptor readCPUHighLoadStackFramesRecordsDict];
        self.recordsDataLoading = NO;

        [[WXRocketCPUTrace shareInstance] addDelegate:self];

        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.tableView reloadData];
        });
    });
}

+ (NSString *)timestampStringFromDate:(NSDate *)date {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"HH:mm:ss";
    });
    return [dateFormatter stringFromDate:date];
}

// MARK: - table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.records.count + (self.livingRecord ? 1 : 0) > 0)
        return 2;
    else
        return 0;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 0;
    else
        return self.records.count + (self.livingRecord ? 1 : 0);
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTHCPUHighLoadRecordCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MTHCPUHighLoadRecordCell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    NSInteger recordIndex = indexPath.row;
    if (self.livingRecord) {
        recordIndex -= 1;
    }

    WXRocketCPUTraceHighLoadRecord *record;
    if (recordIndex == -1) {
        record = self.livingRecord;
    } else {
        record = self.records[recordIndex];
    }

    cell.textLabel.font = [UIFont systemFontOfSize:11];
    cell.textLabel.text = [NSString stringWithFormat:@"Begin: %@", [WXRocketCPURecordsViewController timestampStringFromDate:[NSDate dateWithTimeIntervalSince1970:record.startAt]]];

    cell.detailTextLabel.text = [NSString stringWithFormat:@"AverageUsage:%.2lf%%  Lasting: %.1lfs ", record.averageCPUUsage, record.lasting];

    if (self.detailLoadingIndex == indexPath.row) {
        UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        cell.accessoryView = loadingView;
        [loadingView startAnimating];
    } else {
        cell.accessoryView = nil;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

static BOOL needDoSymbolicsRemote = NO;

// MARK: -
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
        return NO;

    if (self.detailLoadingIndex < 0)
        return YES;
    else
        return self.detailLoadingIndex == indexPath.row;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
        return;

    if (self.detailLoadingIndex >= 0)
        return;

    if (indexPath.row >= self.records.count + (self.livingRecord ? 1 : 0))
        return;

    self.detailLoadingIndex = indexPath.row;

    [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSInteger recordIndex = indexPath.row;
        if (self.livingRecord)
            recordIndex -= 1;

        void (^showContentHandler)(NSString *content) = ^void(NSString *content) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                self.detailLoadingIndex = -1;
                [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];

                WXRocketWebViewController *vc = [[WXRocketWebViewController alloc] initWithText:content];
                [self.navigationController pushViewController:vc animated:YES];
            });
        };

        if (recordIndex == -1) {
            [self detailDescribeForLivingRecord:^(NSString *recordContent) {
                showContentHandler(recordContent);
            }];
        } else {
            WXRocketCPUTraceHighLoadRecord *record = self.records[recordIndex];
            [self detailDescribeForOldRecord:record
                                  completion:^(NSString *recordContent) {
                                      showContentHandler(recordContent);
                                  }];
        }
    });
}

- (void)detailDescribeForOldRecord:(WXRocketCPUTraceHighLoadRecord *)record completion:(void (^)(NSString *recordContent))completion {
    NSMutableString *result = [NSMutableString string];
    NSString *beginTime = [WXRocketCPURecordsViewController timestampStringFromDate:[NSDate dateWithTimeIntervalSince1970:record.startAt]];
    [result appendFormat:
                @"\nCPU high load begin at: %@ \n"
                @"Average Usage:%.2lf%%, Lasting: %lfs \n\n\n",
            beginTime, record.averageCPUUsage, record.lasting];
    NSString *key = [NSString stringWithFormat:@"%.2f", record.startAt];
    NSString *stackFramesSample = self.stackFramesSampleDict[key];
    if (stackFramesSample.length == 0) {
        [result appendString:@" --- reenter main panel to load --- "];
    } else {
        NSData *data = [stackFramesSample dataUsingEncoding:NSUTF8StringEncoding];
        if (!data) {
            [result appendString:@" error data "];
            completion(result.copy);
            return;
        }

        NSArray *sampleDicts = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([sampleDicts isKindOfClass:[NSArray class]]) {
            if (needDoSymbolicsRemote) {
                NSSet<NSString *> *frames = [self stackFramesSetFromSample:sampleDicts];
                [WXRocketStackFrameSymbolicsRemote
                    symbolizeStackFrames:[frames allObjects]
                     withDyldImagesInfos:[WXRocketDyldImagesStorage cachedDyldImagesInfo]
                       completionHandler:^(NSArray<NSDictionary<NSString *, NSString *> *> *_Nonnull symbolizedFrames, NSError *_Nonnull error) {
                           if (error) {
                               [result appendFormat:@"%@", error];
                           } else {
                               NSMutableDictionary<NSString *, NSString *> *resultFrames = @{}.mutableCopy;
                               [self formatRemoteSymolizedFramesDicts:symbolizedFrames intoOnlineFrame:resultFrames];

                               [result appendString:[self stringFromStackFrameSamples:sampleDicts level:0 localSymbolics:NO]];

                               [resultFrames enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
                                   [result replaceOccurrencesOfString:key withString:obj options:0 range:NSMakeRange(0, result.length)];
                               }];
                           }

                           completion(result.copy);
                           return;
                       }];
            } else {
                [result appendString:[self stringFromStackFrameSamples:sampleDicts level:0 localSymbolics:YES]];
                completion(result.copy);
                return;
            }
            return;
        } else {
            [result appendString:@" --- read data error --- "];
        }
    }
    completion(result.copy);
}

- (void)detailDescribeForLivingRecord:(void (^)(NSString *recordContent))completion {
    NSMutableString *result = [NSMutableString string];
    NSString *beginTime = [WXRocketCPURecordsViewController timestampStringFromDate:[NSDate dateWithTimeIntervalSince1970:self.livingRecord.startAt]];
    [result appendFormat:
                @"\nCPU high load begin at: %@ \n"
                @"Average Usage:%.2lf%%, Lasting: %lfs \n\n\n",
            beginTime, self.livingRecord.averageCPUUsage, self.livingRecord.lasting];

    if (_livingRecordStackFrameSample) {
        NSArray *sampleDicts = _livingRecordStackFrameSample->json();
        if ([sampleDicts isKindOfClass:[NSArray class]]) {
            if (needDoSymbolicsRemote) {
                NSSet<NSString *> *frames = [self stackFramesSetFromSample:sampleDicts];
                [WXRocketStackFrameSymbolicsRemote
                    symbolizeStackFrames:[frames allObjects]
                     withDyldImagesInfos:[WXRocketDyldImagesStorage cachedDyldImagesInfo]
                       completionHandler:^(NSArray<NSDictionary<NSString *, NSString *> *> *_Nonnull symbolizedFrames, NSError *_Nonnull error) {
                           if (error) {
                               [result appendFormat:@"%@", error];
                           } else {
                               NSMutableDictionary<NSString *, NSString *> *resultFrames = @{}.mutableCopy;
                               [self formatRemoteSymolizedFramesDicts:symbolizedFrames intoOnlineFrame:resultFrames];

                               [result appendString:[self stringFromStackFrameSamples:sampleDicts level:0 localSymbolics:NO]];

                               [resultFrames enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSString *_Nonnull obj, BOOL *_Nonnull stop) {
                                   [result replaceOccurrencesOfString:key withString:obj options:0 range:NSMakeRange(0, result.length)];
                               }];
                           }

                           completion(result.copy);
                           return;
                       }];
            } else {
                [result appendString:[self stringFromStackFrameSamples:sampleDicts level:0 localSymbolics:YES]];
                completion(result.copy);
                return;
            }
            return;
        } else {
            [result appendString:@" --- convert data error --- "];
        }
    } else {
        [result appendString:@" --- empty living record stack frames sample"];
    }

    completion(result.copy);
}

- (NSSet<NSString *> *)stackFramesSetFromSample:(NSArray<NSDictionary *> *)stackframeSamplesDicts {
    NSMutableSet<NSString *> *frames = [NSMutableSet set];
    for (NSDictionary *sample in stackframeSamplesDicts) {
        [frames addObject:sample[@"frame"]];
        NSArray *children = sample[@"children"];
        if (children.count > 0) {
            NSSet *childrenFrames = [self stackFramesSetFromSample:children];
            [frames addObjectsFromArray:[childrenFrames allObjects]];
        }
    }
    return [frames copy];
}

- (NSString *)stringFromStackFrameSamples:(NSArray<NSDictionary *> *)stackframeSamplesDicts level:(NSInteger)level localSymbolics:(BOOL)doSymbolics {
    NSMutableString *result = [NSMutableString string];

    NSArray *sortedDicts = [stackframeSamplesDicts sortedArrayUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
        double proportion1 = [[obj1 objectForKey:@"proportion"] doubleValue];
        double proportion2 = [[obj2 objectForKey:@"proportion"] doubleValue];
        return (proportion1 > proportion2) ? NSOrderedAscending : NSOrderedDescending;
    }];

    [sortedDicts enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSString *frame = [obj objectForKey:@"frame"];

        NSString *desc = frame;
        if (doSymbolics) {
            unsigned long long frameV = 0;
            NSScanner *scanner = [NSScanner scannerWithString:frame];
            [scanner setScanLocation:2];
            [scanner scanHexLongLong:&frameV];
            desc = [self recordFrameStringFrom:(vm_address_t)frameV withoutFnameIfExistSname:YES];
        }

        double proportion = [[obj objectForKey:@"proportion"] doubleValue];
        // ignore < 1%
        if (proportion < 0.01)
            return;

        [result appendString:[NSString stringWithFormat:@"|%*.1lf%% %@\n", (int)level * 2 + 6, proportion * 100, desc]];

        NSArray *children = [obj objectForKey:@"children"];
        if (children.count > 0) {
            [result appendFormat:@"%@", [self stringFromStackFrameSamples:children level:level + 1 localSymbolics:doSymbolics]];
        }
    }];
    return [result copy];
}

- (NSString *)recordFrameStringFrom:(vm_address_t)frame withoutFnameIfExistSname:(BOOL)shortV {
    NSString *title = nil;
    Dl_info dlinfo = {NULL, NULL, NULL, NULL};

    if (!self->_stackHelper) {
        self->_stackHelper = new WXRocketStackFrameSymbolics();
    }
    self->_stackHelper->getDLInfoByAddr(frame, &dlinfo, true);

    if (dlinfo.dli_sname) {
        if (shortV)
            title = [NSString stringWithFormat:@"%s", dlinfo.dli_sname];
        else
            title = [NSString stringWithFormat:@"%s %s", dlinfo.dli_fname, dlinfo.dli_sname];
    } else {
        title = [NSString stringWithFormat:@"%s %p %p", dlinfo.dli_fname, dlinfo.dli_fbase, dlinfo.dli_saddr];
    }
    return title;
}

- (void)formatRemoteSymolizedFramesDicts:(NSArray<NSDictionary<NSString *, NSString *> *> *)remoteSymblizedFrames
                         intoOnlineFrame:(NSMutableDictionary<NSString *, NSString *> *)outFrameDict {
    for (NSDictionary<NSString *, NSString *> *frameInfo in remoteSymblizedFrames) {
        if (![frameInfo isKindOfClass:[NSDictionary class]]) {
            MTHLogWarn(@" unexpected frameInfo: %@", frameInfo);
            continue;
        }

        NSString *frameKey = frameInfo[@"addr"];
        if (frameKey.length == 0)
            continue;

        NSString *fname = frameInfo[@"fname"];
        NSString *fbase = frameInfo[@"fbase"];
        NSString *sname = frameInfo[@"sname"];
        NSString *sbase = frameInfo[@"sbase"];
        NSMutableString *frameDealed = [NSMutableString string];
        if (fname.length > 0) {
            [frameDealed appendFormat:@"%@  ", fname];
        } else if (fbase.length > 0) {
            [frameDealed appendFormat:@"%@  ", fbase];
        }
        if (sname.length > 0) {
            [frameDealed appendFormat:@"%@", sname];
        } else if (sbase.length > 0) {
            [frameDealed appendFormat:@"%@", sbase];
        } else {
            [frameDealed appendFormat:@"%@", frameKey];
        }
        outFrameDict[frameKey] = [frameDealed copy];
    }
}

// MARK: - MTHCPUTracingDelegate
- (void)cpuHighLoadRecordStartAt:(NSTimeInterval)startAt
       didUpdateStackFrameSample:(WXR_CPUTraceStackFramesNode *)stackframeRootNode
                 averageCPUUsage:(CGFloat)averageCPUUsage
                     lastingTime:(CGFloat)lastingTime {
    BOOL insert = NO;
    if (self.livingRecord == nil) {
        insert = YES;
        self.livingRecord = [[WXRocketCPUTraceHighLoadRecord alloc] init];
    }
    self.livingRecord.startAt = startAt;
    self.livingRecord.averageCPUUsage = averageCPUUsage * 100;
    self.livingRecord.lasting = lastingTime;
    _livingRecordStackFrameSample = stackframeRootNode;

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (insert) {
            [self.tableView reloadData];
        } else {
            if ([self.tableView numberOfRowsInSection:1] > 0)
                [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:1] ] withRowAnimation:UITableViewRowAnimationNone];
        }
    });
}

- (void)cpuHighLoadRecordDidEnd {
    // simply reload data after 1s
    _livingRecordStackFrameSample = nil;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.livingRecord = nil;
        [self loadRecordsData];
    });
}

@end
