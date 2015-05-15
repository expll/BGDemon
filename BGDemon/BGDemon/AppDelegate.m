//
//  AppDelegate.m
//  腾讯云统计刷用户
//
//  Created by Tiny on 15/5/13.
//  Copyright (c) 2015年 weiying. All rights reserved.
//

#import "AppDelegate.h"
#import "MTA.h"
#import "MMPDeepSleepPreventer.h"
#import "AppUtil.h"
#import "NSTask.h"

@interface AppDelegate ()
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgTaskID;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.bgTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTaskID];
        self.bgTaskID = UIBackgroundTaskInvalid;
    }];
    MMPDeepSleepPreventer * soundBoard =   [MMPDeepSleepPreventer new];
    [soundBoard startPreventSleep];
    
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkApp) userInfo:nil repeats:YES];
    
//    NSLog(@"5秒后重新启动机器。");
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self ReBoot];
//    });
    
    [MTA startWithAppkey:@"IA1HUM1Q86IH"];
    return YES;
}


- (void)checkApp
{
    
    NSString *bundleid = [AppUtil frontmostBundleId];
    if (![bundleid isEqualToString:@"com.weiying.GDTdemo"]) {
        [AppUtil launchAPP:@"com.weiying.GDTdemo"];
    }
}

- (void)ReBoot
{
    NSTask * mount = [[NSTask alloc] init];
    [mount setLaunchPath: @"/sbin/reboot"];
    //[mount setCurrentDirectoryPath:@"/"];
    //[mount setArguments:@[@"WL"]];
    [mount launch];
    [mount waitUntilExit];
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    UIApplication*   app = [UIApplication sharedApplication];
    __block    UIBackgroundTaskIdentifier bgTask;
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid)
            {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (bgTask != UIBackgroundTaskInvalid)
            {
                bgTask = UIBackgroundTaskInvalid;
            }
        });
    });
    
    [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
        NSLog(@"KeepAlive");
    }];
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
