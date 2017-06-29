//
//  AsyncClient.m
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/19.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import "AsyncClient.h"

@interface AsyncClient ()
{
    BOOL heartRight;        //设置是否正在进行心跳包发送
    NSTimer * heartTimer;
}
@end

@implementation AsyncClient

//socket方法不需要重新封装
-(id) init
{
    return [self initWithSocketQueue:nil];
}

-(id) initWithSocketQueue:(dispatch_queue_t)sq
{
    return [self initWithDelegate:nil delegateQueue:nil];
}

-(id) initWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq
{
    return [self initWithDelegate:aDelegate delegateQueue:dq socketQueue:nil];
}

-(id) initWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq socketQueue:(dispatch_queue_t)sq
{
    if (self  =[super initWithDelegate:aDelegate delegateQueue:dq socketQueue:sq]) {
        [self initData];
        [self initHeart];
        [self initDelBlocksClient];
    }
    return self;
}
//设置初始化数据
-(void) initData
{
    heartRight = NO;
}

//初始化代理中的block数据
-(void) initDelBlocksClient
{
    __weak AsyncClient * weakSelf = self;
    self.socketBlkDel.connectToSocket = ^AsyncSocketCallbackDel*(NSString * server ,uint16_t port){
        AsyncSocketCallbackDel* callback = [[AsyncSocketCallbackDel alloc] init];
        callback.successBlk = ^(GCDAsyncSocket * socket){
            LogInfo(@"客户端%@连接成功" ,socket.description);
        };
        callback.failBlk = ^(NSError * err){
            LogInfo(@"客户端连接出错：%@",err);
        };
        return callback;
    };
    
    self.socketBlkDel.didReadData = ^(GCDAsyncSocket *socket ,NSData * data,long tag)
    {
        LogInfo(@"客户端%@接收到数据 ：%@ ，tag: %ld" ,socket ,[[NSString alloc] initWithData:data  encoding:NSUTF8StringEncoding] ,tag);
        __strong AsyncClient *strongSelf = weakSelf;
        
        if (tag == HEART_TAG) {
            [strongSelf terminateHeart];
        }
        
        //收到数据时候，继续执行readdata函数 ，继续接受数据
        [strongSelf readDataWithTag:tag];
    };
    
    self.socketBlkDel.writeDataWithTag = ^AsyncSocketCallbackDel *(long tag){
        AsyncSocketCallbackDel* callback = [[AsyncSocketCallbackDel alloc] init];
        callback.successBlk = ^(GCDAsyncSocket * sock){
            //判断发送出去的包内容为心跳包的内容
            if (tag == HEART_TAG) LogInfo(@"心跳包发送成功");
            LogInfo(@"客户端%@写入成功" ,sock.description);
        };
        callback.failBlk = ^(NSError *err){
            //发送包内容为心跳包的内容，并且失败， 断开连接.
            if (tag == HEART_TAG) LogError(@"心跳包发送失败");
            LogError(@"客户端写入失败Err:%@" ,err);
        };
        return callback;
    };

    self.socketBlkDel.socketDidDisconnect = ^(GCDAsyncSocket *socket ,NSError * err){
        __strong AsyncClient *strongSelf = weakSelf;
        LogInfo(@"客户端%@断开连接 err:%@" ,socket.description ,err);
        //断开心跳
        [strongSelf terminateHeart];
    };
}

//初始化心跳
-(void) initHeart
{
    __weak AsyncClient * weakSelf = self;

    heartTimer = [NSTimer scheduledTimerWithTimeInterval:HEART_INTERVAL repeats:YES block:^(NSTimer *timer){
        __strong AsyncClient *strongSelf = weakSelf;
        if (!self.isConnected) {
            return ;
        }
        NSData * heartD = strongSelf.heartData?:[FULL_HEART_STRING dataUsingEncoding:NSUTF8StringEncoding];
        [strongSelf sendHeartBeatData:heartD];
    }];
    
    [heartTimer setFireDate:[NSDate distantFuture]];
}

-(void) sendHeartBeatData:(NSData *) heartData
{
    //判断连接了仍要执行心跳的情况，可能因为特殊原因 ，虽然保持着连接但是并没有收到服务器的回复
    [self writeStringToServer:heartData withTag:HEART_TAG];
}

#pragma mark 对外接口
-(void) connectToServer:(NSString *) serverIP onPort:(uint16_t) port
{
    NSError * connectErr;
    [self connectToHost:serverIP onPort:port error:&connectErr];
    if (connectErr) {
        LogError(@"客户端连接错误Err：%@" ,connectErr);
    }
}

-(void) writeStringToServer:(NSData *) data withTag:(long)tag
{
    if (!self.isConnected) {
        LogError(@"客户端未连接 ,写入失败");
        return;
    }
    
    [self writeData:data withTimeout:-1 tag:tag];
}

-(void) readDataWithTag:(long)tag
{
    if (!self.isConnected) {
        LogError(@"客户端未连接 ，读取失败");
        return;
    }
    //timeout不能为maxfloat 直接超时
    [self readDataWithTimeout:-1 tag:tag];
}

#pragma mark ---心跳操作
//开始心跳
-(void) startHeart
{
    heartRight = YES;
    if (![heartTimer isValid]) {
        [[NSRunLoop currentRunLoop] addTimer:heartTimer forMode:NSDefaultRunLoopMode];
    }
    [heartTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:HEART_INTERVAL]];
}

//终止心跳
-(void) terminateHeart
{
    heartRight = NO;
    if ([heartTimer isValid]) {
        [heartTimer setFireDate:[NSDate distantFuture]];
    }
}

-(void) cancelHeart
{
    heartRight = NO;
    if (heartTimer) {
        [heartTimer invalidate];
        heartTimer = nil;
    }
}

@end
