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


#include "WXRocketInnerLogger.h"

#if __has_include(<CocoaLumberjack/CocoaLumberjack.h>)

#import <CocoaLumberjack/DDLog.h>
#import <MTAppenderFile/MTAppenderFile.h>
#import "WXRocketUtility.h"


typedef NS_ENUM(NSInteger, WXRocketInnerDDLogFormatterType) {
    WXRocketInnerDDLogFormatterTypeFile = 1,
    WXRocketInnerDDLogFormatterTypeConsole = 2,
};

@interface WXRocketInnerDDLogFormatter : NSObject <DDLogFormatter>

@property (assign, nonatomic) WXRocketInnerDDLogFormatterType type;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation WXRocketInnerDDLogFormatter

- (instancetype)initWithType:(WXRocketInnerDDLogFormatterType)type {
    if ((self = [super init])) {
        _type = type;
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
        [_dateFormatter setDateFormat:@"mm:ss:SSS"];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    if (logMessage->_message.length == 0)
        return nil;

    if (logMessage->_timestamp) {
        NSString *dateAndTime = [_dateFormatter stringFromDate:logMessage.timestamp];
        NSString *message;
        if (_type == WXRocketInnerDDLogFormatterTypeFile) {
            message = [NSString stringWithFormat:@"%@ %@", dateAndTime, logMessage->_message];
        } else if (_type == WXRocketInnerDDLogFormatterTypeConsole) {
            message = [NSString stringWithFormat:@"[rocket] %@ %@", dateAndTime, logMessage->_message];
        }
        return message;
    } else {
        return logMessage->_message;
    }
}

@end

// MARK: - Rocket File logger

@interface WXRocketInnerDDLogFileLogger : DDAbstractLogger <DDLogger>

@property (strong, nonatomic) MTAppenderFile *logFile;
@property (copy, nonatomic) NSString *logPath;

@end

@implementation WXRocketInnerDDLogFileLogger

- (void)dealloc {
    [_logFile close];
}

- (instancetype)init {
    if ((self = [super init])) {
        _logPath = [WXRocketUtility currentStorePath];

        if ([[NSFileManager defaultManager] fileExistsAtPath:_logPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:_logPath error:nil];
        }

        NSError *error;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:_logPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"create log path failed, %@", [error localizedDescription]);
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

- (MTAppenderFile *)logFile {
    if (!_logFile) {
        _logFile = [[MTAppenderFile alloc] initWithFileDir:_logPath name:@"log"];
        [_logFile open];
    }
    return _logFile;
}

- (void)appWillTerminate:(NSNotification *)notification {
    [_logFile close];
}

#pragma mark Override

- (void)logMessage:(DDLogMessage *)logMessage {
    if (logMessage->_message.length == 0)
        return;

    if (_logFormatter) {
        NSString *message = [_logFormatter formatLogMessage:logMessage];
        [self.logFile appendText:message];
    } else {
        [self.logFile appendText:logMessage->_message];
    }
}

- (NSString *)loggerName {
    return @"tt.rocket.inner.log";
}

@end


// MARK: - Logger

static DDLog *_wxr_log = nil;
static DDTTYLogger *_ttyLogger = nil;
static WXRocketInnerDDLogFileLogger *_fileLogger = nil;

@implementation WXRocketInnerLogger

+ (void)log:(BOOL)asynchronous
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
        tag:(id __nullable)tag
     format:(NSString *)format, ... {
    va_list args;
    if (format) {
        va_start(args, format);

        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        DDLogMessage *logMsg = [[DDLogMessage alloc] initWithMessage:message level:level flag:flag context:0 file:@"" function:nil line:0 tag:tag options:0 timestamp:[NSDate new]];

        [_wxr_log log:asynchronous message:logMsg];

        va_end(args);
    }
}

+ (void)setup {
    if (_wxr_log == nil) {
        _wxr_log = [[DDLog alloc] init];
    }
}

+ (void)setupFileLoggerWithLevel:(DDLogLevel)logLevel {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setup];
        _fileLogger = [[WXRocketInnerDDLogFileLogger alloc] init];
        _fileLogger.logFormatter = [[WXRocketInnerDDLogFormatter alloc] initWithType:WXRocketInnerDDLogFormatterTypeFile];
        [_wxr_log addLogger:_fileLogger withLevel:logLevel];
    });
}

+ (void)setupConsoleLoggerWithLevel:(DDLogLevel)logLevel {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setup];
        _ttyLogger = [[DDTTYLogger alloc] init];
        _ttyLogger.logFormatter = [[WXRocketInnerDDLogFormatter alloc] initWithType:WXRocketInnerDDLogFormatterTypeConsole];
        [_wxr_log addLogger:_ttyLogger withLevel:logLevel];
    });
}

+ (void)configFileLoggerLevel:(DDLogLevel)logLevel {
    if (_fileLogger) {
        [_wxr_log removeLogger:_fileLogger];
        [_wxr_log addLogger:_fileLogger withLevel:logLevel];
    } else {
        [self setupFileLoggerWithLevel:logLevel];
    }
}

+ (void)configConsoleLoggerLevel:(DDLogLevel)logLevel {
    if (_ttyLogger) {
        [_wxr_log removeLogger:_ttyLogger];
        [_wxr_log addLogger:_ttyLogger withLevel:logLevel];
    } else {
        [self setupConsoleLoggerWithLevel:logLevel];
    }
}

@end


#endif // __has_include(<CocoaLumberjack/CocoaLumberjack.h>)
