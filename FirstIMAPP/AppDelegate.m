//
//  AppDelegate.m
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/11.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import "AppDelegate.h"
#import "suanfaTest.h"

#define LOGIN_PATH [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"/mylog.log"]
#define MAX_LOGIN_SIZE 1024 * 1 *1024
//设置文件最大为1M

@interface AppDelegate ()
{
    NSTimer * timer;
    NSFileManager * fm ;
}
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
//    timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
//    [timer setFireDate:[NSDate distantFuture]];
//    [self startTimer];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        suanfaTest * test = [[suanfaTest alloc] init];
        [test testFS];
        [test testMS];
    });
    
    //to log to document directory
    NSLog(@"the login path is %@ " ,LOGIN_PATH);
    //redirect NSLog
    
    fm = [NSFileManager defaultManager];
    
    [self redir:LOGIN_PATH];
    
    
    return YES;
}

//重定位nslog到指定文件
-(void) redir:(NSString *) loggingPath
{
    freopen([loggingPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    // 添加文件检测
    [self gcdMonitorForFilePath:LOGIN_PATH];
}
//重定向nslog到原来的位置。
-(void) redirBack:(NSString *) loggingPath
{
    //在ios上可用的方式,还是得借助dup和dup2
    int originH1 = dup(STDERR_FILENO);
    FILE * myFile = freopen([loggingPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);//这句话已经重定向了,现在NSLog都输出到文件中去了,
    //……………….
    //恢复原来的
    dup2(originH1, STDERR_FILENO);//就可以了</code>
}

-(long long) fileSize:(NSString *) filePath
{
    if ([fm fileExistsAtPath:filePath]) {
        NSError * fileErr ;
        if (fileErr) {
            NSLog(@"file attri error :%@" ,fileErr);
            return 0;
        }
        return [[fm attributesOfItemAtPath:filePath error:&fileErr] fileSize];
    }
    return 0;
}

//gcd 信号源方式进行文件监测
-(void) gcdMonitorForFilePath:(NSString *) filePath
{
    __block int fileDes = open([filePath UTF8String], O_EVTONLY);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block dispatch_source_t  source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fileDes, DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_DELETE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE | DISPATCH_VNODE_WRITE, queue);
    dispatch_source_set_event_handler(source, ^{
        unsigned long eventType = dispatch_source_get_data(source);
        [self alterSourceType:eventType];
    });
    
    dispatch_source_set_cancel_handler(source, ^{
        NSLog(@"the source cancel for some reason");
        close(fileDes);
        fileDes = 0;
        source = nil;
    });
    
    dispatch_resume(source);
}


-(void) alterSourceType:(unsigned long) sourceType
{
    if (sourceType & DISPATCH_VNODE_WRITE) {
       //文件写入
        if ([self fileSize:LOGIN_PATH] >= MAX_LOGIN_SIZE) {
            //清空日志
            //移除之后重新进行添加
            [fm removeItemAtPath:LOGIN_PATH error:nil];
            [self redir:LOGIN_PATH];
        }
    }
    
    if (sourceType & DISPATCH_VNODE_DELETE) {
        //文件删除
    }
}

-(void) startTimer
{
    NSLog(@"start Timer");
    [timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:5]];
}

-(void) timerAction:(NSTimer *) sender
{
    NSLog(@"ssender");
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
