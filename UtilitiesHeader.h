//
//  UtilitiesHeader.h
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/19.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#ifndef UtilitiesHeader_h
#define UtilitiesHeader_h

//设置日志输出
#define ENABLE_LOG NO

#if ENABLE_LOG
#import "DDLog.h"

#define LogAsync   YES
#define LogContext GCDAsyncSocketLoggingContext

#define LogObjc(flg, frmt, ...) LOG_OBJC_MAYBE(LogAsync, logLevel, flg, LogContext, frmt, ##__VA_ARGS__)
//#define LogC(flg, frmt, ...)    LOG_C_MAYBE(LogAsync, logLevel, flg, LogContext, frmt, ##__VA_ARGS__)
#define LogC(flg, frmt, ...)    LOG_OBJC_MAYBE(LogAsync, logLevel, flg, LogContext, frmt, ##__VA_ARGS__)

#define LogError(frmt, ...)     LogObjc(LOG_FLAG_ERROR,   (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogWarn(frmt, ...)      LogObjc(LOG_FLAG_WARN,    (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogInfo(frmt, ...)      LogObjc(LOG_FLAG_INFO,    (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogVerbose(frmt, ...)   LogObjc(LOG_FLAG_VERBOSE, (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)

#define LogCError(frmt, ...)    LogC(LOG_FLAG_ERROR,   (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogCWarn(frmt, ...)     LogC(LOG_FLAG_WARN,    (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogCInfo(frmt, ...)     LogC(LOG_FLAG_INFO,    (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)
#define LogCVerbose(frmt, ...)  LogC(LOG_FLAG_VERBOSE, (@"%@: " frmt), THIS_FILE, ##__VA_ARGS__)

#define LogTrace()              LogObjc(LOG_FLAG_VERBOSE, @"%@: %@", THIS_FILE, THIS_METHOD)
#define LogCTrace()             LogC(LOG_FLAG_VERBOSE, @"%@: %s", THIS_FILE, __FUNCTION__)

#ifndef GCDAsyncSocketLogLevel
#define GCDAsyncSocketLogLevel LOG_LEVEL_VERBOSE
#endif

// Log levels : off, error, warn, info, verbose
static const int logLevel = GCDAsyncSocketLogLevel;

#else
// Logging Disabled
#define LogError NSLog
#define LogWarn NSLog
#define LogInfo NSLog
#define LogVerbose NSLog

#define LogCError NSLog
#define LogCWarn NSLog
#define LogCInfo NSLog
#define LogCVerbose NSLog

#define LogTrace NSLog
#define LogCTrace NSLog
//#define LogError(frmt, ...)     {}
//#define LogWarn(frmt, ...)      {}
//#define LogInfo(frmt, ...)      {}
//#define LogVerbose(frmt, ...)   {}
//
//#define LogCError(frmt, ...)    {}
//#define LogCWarn(frmt, ...)     {}
//#define LogCInfo(frmt, ...)     {}
//#define LogCVerbose(frmt, ...)  {}
//
//#define LogTrace()              {}
//#define LogCTrace(frmt, ...)    {}

#endif

#endif /* UtilitiesHeader_h */
