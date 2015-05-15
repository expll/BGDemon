//
//  AppUtils.h
//  NoIcon
//
//  Created by shaojinkuang on 12/11/14.
//  Copyright (c) 2014 luocena. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface AppUtil : NSObject

//+ (NSString *)IDFA;
+ (NSString *)IDFV;
+ (NSString *)deviceIdnetifier;
+ (NSString *)cacheDirectory;

// 获取版本
+ (NSString *)getCurrentAppVersion;
+ (NSString *)getAppVersion:(NSString *)bundleId;

// 检查状态
+ (BOOL)isAppInstalled:(NSString *)bundleId ;
+ (BOOL)isAppActived:(NSString *)processName;

// 安装激活
+ (void)installApp:(NSString *)file succuss:(void(^)())succuss fail:(void(^)())fail;
+ (void)launchAPP:(NSString *)bundleID;

// 日期
+ (NSString *)date;

+ (NSString*) getNowTimeStr;

// 均衡延迟时间
+ (int)avgDelayTime;

// 获取手机中安装的apps列表
+ (NSArray *)installedAppBundleIds;

+ (id)urlSchemeWithBundleId:(NSString *)bundleId;

+ (NSString *)frontmostBundleId;
+ (void)suspendApp;

+(NSString *) GetYearMouthDayHourMinuteScend;

+ (NSInvocation *)InvocationWithSEL:(SEL)s OBJ:(id)o Arguments:(NSArray *)args;

BOOL IS_HighestPower();
id topVC();

+ (BOOL)isJailBreak;

@end
