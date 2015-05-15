//
//  AppUtils.m
//  NoIcon
//
//  Created by shaojinkuang on 12/11/14.
//  Copyright (c) 2014 luocena. All rights reserved.
//

#import "AppUtil.h"
#include <dlfcn.h>
#include <sys/sysctl.h>
#import <AdSupport/AdSupport.h>
#import <MobileInstallation/MobileInstallation.h>
#import <SpringBoardServices/SpringBoardServices.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/objc.h>


@implementation AppUtil


+ (NSString *)IDFA
{
    NSString *idfaString = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    return idfaString;
}

//+ (NSString *)IDFV
//{
//    NSString *identifierForIdentifier = [CHKeychain load:kIdentifierForIdentifier];
//    
//    if (identifierForIdentifier == nil) {
//        NSLog(@"KeyChain中不存在:%@, 正在保存...", kIdentifierForIdentifier);
//        identifierForIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
//        [CHKeychain save:kIdentifierForIdentifier data:identifierForIdentifier];
//    }else{
//        NSLog(@"KeyChain中已存在:%@, 直接读取...", kIdentifierForIdentifier);
//    }
//    return  identifierForIdentifier;
//}

+ (NSString *)deviceIdnetifier
{
    return [self IDFV];
}

+ (NSString *)cacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    return cachesDirectory;
}

+ (NSString *)getCurrentAppVersion {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appCurVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    return appCurVersion;
}

+ (NSString *)getAppVersion:(NSString *)bundleId {
    
    NSString *retversion = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0f)
    {
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        NSObject* workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
        NSArray *array = [workspace performSelector:@selector(allInstalledApplications)];
        
        for (int i = 0; i < array.count; i ++)
        {
            Class LSApplicationProxy_class = [array objectAtIndex:i];
            NSString *bundleIdString = [LSApplicationProxy_class performSelector:@selector(applicationIdentifier)];
            NSString *versionString = [LSApplicationProxy_class performSelector:@selector(shortVersionString)];
            
            if ([bundleIdString isEqualToString:bundleId])
            {
                retversion = versionString;
            }
        }
    }else
    {
        NSDictionary *options = [NSDictionary dictionaryWithObject:@"Any" forKey:@"ApplicationType"];
        NSDictionary *data = (__bridge NSDictionary *) MobileInstallationLookup((__bridge CFDictionaryRef) options);
        retversion = [[data objectForKey:bundleId] objectForKey:@"CFBundleShortVersionString"];
        
    }
    return retversion;
}


+ (void)installApp:(NSString *)file succuss:(void(^)())succuss fail:(void(^)())fail
{
    
    CFStringRef filePathRef = (__bridge CFStringRef)(file);
    BOOL  isSuccess = MobileInstallationInstall(filePathRef, NULL, NULL, NULL);
    if (isSuccess == 0) {
        NSLog(@"安装成功!!");
        if(succuss != nil) succuss();
    } else {
        NSLog(@"安装失败!!");
        if(fail != nil) fail();
    }
}

+ (void)launchAPP:(NSString *)bundleID
{
    CFStringRef bundleRef = (__bridge CFStringRef)bundleID;
    int ret = SBSLaunchApplicationWithIdentifier(bundleRef, NO);
    NSLog(@"启动程序 ret:%d", ret);
    
}

+ (BOOL)isAppInstalled:(NSString *)bundleId
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0f)
    {
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        NSObject* workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
        NSArray *array = [workspace performSelector:@selector(allInstalledApplications)];
        
        for (int i = 0; i < array.count; i ++)
        {
            Class LSApplicationProxy_class = [array objectAtIndex:i];
            NSString *bundleIdString = [LSApplicationProxy_class performSelector:@selector(applicationIdentifier)];
            
            if ([bundleIdString isEqualToString:bundleId])
            {
                return YES;
            }
        }
    }else
    {
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"BundleIDs",@"ReturnAttributes", nil];
        NSDictionary *data = (__bridge NSDictionary *)MobileInstallationLookup((__bridge CFDictionaryRef)attributes);
        if([[data allKeys] containsObject:bundleId])
        {
            return YES;
        }
        
    }
    
    
    
    return NO;
}

+ (BOOL)isAppActived:(NSString *)processName
{
    //NSLog(@"%@", [AppUtil runningProcesses]);
    if ([[AppUtil runningProcesses] containsObject:processName]) {
        return YES;
    }
    
    return NO;
}

+ (NSArray *)runningProcesses {
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;
    
    size_t size;
    int st = sysctl(mib, miblen, NULL, &size, NULL, 0);
    
    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;
    
    do {
        size += size / 10;
        newprocess = realloc(process, size);
        if (!newprocess){
            if (process){
                free(process);
            }
            return nil;
        }
        process = newprocess;
        st = sysctl(mib, miblen, process, &size, NULL, 0);
    } while (st == -1 && errno == ENOMEM);
    
    if (st == 0){
        if (size % sizeof(struct kinfo_proc) == 0){
            int nprocess = size / sizeof(struct kinfo_proc);
            if (nprocess){
                NSMutableArray * array = [[NSMutableArray alloc] init];
                for (int i = nprocess - 1; i >= 0; i--){
                    NSString * processName = [[NSString alloc] initWithFormat:@"%s", process[i].kp_proc.p_comm];
                    [array addObject:processName];
                }
                free(process);
                return  array;
            }
        }
    }
    return nil;
}

+ (NSDate*) getNowDate
{
    // 获取系统当前时间
    NSDate * date = [NSDate date];
    NSTimeInterval sec = [date timeIntervalSinceNow];
    return [NSDate dateWithTimeIntervalSinceNow:sec];
}

static NSDateFormatter * df = nil;
+ (NSString *)date
{
    //设置时间输出格式:
    if (df == nil) {
        df = [[NSDateFormatter alloc] init];
    }
    
    [df setDateFormat:@"yyyy-MM-dd"];
    NSString * na = [df stringFromDate: [self getNowDate]];
    
    //NSLog(@"系统当前时间为: %@",na);
    return na;
}

//获取当前时间
+ (NSString*) getNowTimeStr
{
    //设置时间输出格式:
    if(df == nil){
        df = [[NSDateFormatter alloc] init];
    }
    [df setDateFormat:@"HH:mm:ss"];
    NSString * na = [df stringFromDate: [self getNowDate]];
    
    NSLog(@"系统当前时间为: %@",na);
    return na;
}

//+ (int)avgDelayTime;
//{
//    /*
//    NSDate *  senddate=[NSDate date];
//    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
//    [dateformatter setDateFormat:@"hhmmss"];
//    NSString *locationString=[dateformatter stringFromDate:senddate];
//    NSRange a = {0, 2};
//    NSRange b = {2, 2};
//    NSRange c = {4,2};
//    int x = arc4random_uniform(24*3600 - [[locationString substringWithRange:a] integerValue]*3600
//                                       - [[locationString substringWithRange:b] integerValue]*60
//                                       - [[locationString substringWithRange:c] integerValue]*1);
//    */
//    return arc4random() % kDelayReportIntervel;
//}

+ (NSArray *)installedAppBundleIds
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0f)
    {
        Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
        NSObject* workspace = [LSApplicationWorkspace_class performSelector:@selector(defaultWorkspace)];
        NSArray *array = [workspace performSelector:@selector(allInstalledApplications)];
        
        NSMutableArray *mArr = [NSMutableArray arrayWithCapacity:0];
        for (int i = 0; i < array.count; i++)
        {
            Class LSApplicationProxy_class = [array objectAtIndex:i];
            NSString *bundleIdString = [LSApplicationProxy_class performSelector:@selector(applicationIdentifier)];
            [mArr addObject:bundleIdString];
            
            
            return mArr;
        }
    }else
    {
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"ApplicationType",@"Any", nil];
        NSDictionary *data = (__bridge NSDictionary *)MobileInstallationLookup((__bridge CFDictionaryRef)attributes);
        NSArray *keys = [data allKeys];
        NSMutableArray *ret = [NSMutableArray arrayWithCapacity:0];
        for (NSString *key in keys) {
            if(![key hasPrefix:@"com.apple"]){
                [ret addObject:key];
            }
        }
        return ret;
        
    }
    
    
    return nil;
    
    
}

+ (id)urlSchemeWithBundleId:(NSString *)bundleId
{
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:@"ApplicationType",@"Any", nil];
    NSDictionary *data = (__bridge NSDictionary *)MobileInstallationLookup((__bridge CFDictionaryRef)attributes);
    NSArray *keys = [data allKeys];
    for (NSString *key in keys) {
        if([key isEqualToString:bundleId]){
            id array = [[[[data objectForKey:key] objectForKey:@"CFBundleURLTypes"] firstObject] objectForKey:@"CFBundleURLSchemes"];
            if ([array count] > 0) {
                NSString *urlScheme = [array firstObject];
                return urlScheme;
            }
        }
    }
    return nil;
}

+ (NSString *)frontmostBundleId;
{
    return (__bridge NSString *)SBSCopyFrontmostApplicationDisplayIdentifier();
}

+ (void)suspendApp
{
    SBSSuspendFrontmostApplication();
}

//获取年月日 十分秒
+(NSString *) GetYearMouthDayHourMinuteScend
{
    NSDate *datenow = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate:datenow];
    NSDate *localeDate = [datenow  dateByAddingTimeInterval: interval];
    return [NSString stringWithFormat:@"%@",localeDate];
}


+ (NSInvocation *)InvocationWithSEL:(SEL)s OBJ:(id)o Arguments:(NSArray *)args
{
    SEL mySelector = s;
    struct objc_object *a = (__bridge struct objc_object *)(o);
    NSMethodSignature * sig = [a->isa instanceMethodSignatureForSelector: mySelector];
    
    NSInvocation * myInvocation = [NSInvocation invocationWithMethodSignature: sig];
    [myInvocation setTarget: o];
    [myInvocation setSelector: mySelector];
    
    
    
    for (int i = 0; i < args.count; i++) {
        id arg = args[i];
        [myInvocation setArgument: &arg atIndex: i+2];
    }

    [myInvocation retainArguments];
    
    return myInvocation;
    
}

//BOOL IS_HighestPower()
//{
//    NSString *bundleid = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
//    
//    
//    // qq
//    if ([bundleid isEqualToString:BUNDLEID_QQ])
//    {
//        return YES;
//        //  weixin
//    }else if([bundleid isEqualToString:BUNDLEID_WX])
//    {
//        
//        if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:APP_URLSCHEME_QQ]]) {
//            return YES;
//        } else {
//            return NO;
//        }
//        // facebook
//    } else if ([bundleid isEqualToString:BUNDLEID_FB])
//    {
//        
//        if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:APP_URLSCHEME_QQ]] &&
//            ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:APP_URLSCHEME_WX]]) {
//            return YES;
//        } else {
//            return NO;
//        }
//        
//        // whatsapp
//    } else if([bundleid isEqualToString:BUNDLEID_WA])
//    {
//        if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:APP_URLSCHEME_QQ]] &&
//            ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:APP_URLSCHEME_WX]] &&
//            ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:APP_URLSCHEME_FB]]) {
//            return YES;
//        } else {
//            return NO;
//        }
//    }
//    
//    return NO;
//}

////////////
id topVC()
{
    id a = [UIApplication sharedApplication].keyWindow.rootViewController;
    return topViewController(a);
}

UIViewController *topViewController(UIViewController *rootViewController)
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return topViewController(lastViewController);
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return topViewController(presentedViewController);
}
////////////////


+ (BOOL)isJailBreak
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://"]]) {
        NSLog(@"The device is jail broken!");
        return YES;
    }
    NSLog(@"The device is NOT jail broken!");
    return NO;
}


@end
