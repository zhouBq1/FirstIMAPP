//
//  ZBAsyncSocket.m
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/20.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import "ZBAsyncSocket.h"

@interface ZBAsyncSocket ()

@end

@implementation ZBAsyncSocket
@synthesize socketQueue ,zbDelegateQueue ,socketListenningQueue;
-(id) init
{
    
    return [self initWithSocketQueue:socketQueue];
}

-(id) initWithSocketQueue:(dispatch_queue_t)sq
{
    
    return [self initWithDelegate:nil delegateQueue:nil socketQueue:sq];
}

-(id) initWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq
{
    
    return [self initWithDelegate:aDelegate delegateQueue:dq socketQueue:nil];
}

-(id) initWithDelegate:(id)aDelegate delegateQueue:(dispatch_queue_t)dq socketQueue:(dispatch_queue_t)sq
{
    
    [self initQueues];
    self.socketBlkDel = [[AsyncSocketDel alloc] init];
    [self initDelBlocks];
    if (!aDelegate) {
        aDelegate = self.socketBlkDel;
    }
    //设置为自定义的队列
    if (!dq) {
        dq = zbDelegateQueue;
    }
    
    //设置为自定义的默认队列
    if (!sq) {
        sq = socketQueue;
    }
    
    if (self = [super initWithDelegate:aDelegate delegateQueue:dq socketQueue:sq]) {}
    return self;
}

//初始化队列
-(void) initQueues
{
    //并行队列处理收到的socket响应 ，代理方法执行的线程设置。
    zbDelegateQueue = dispatch_queue_create([socketDelegateQueueKey UTF8String], DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_set_specific(zbDelegateQueue, [socketDelegateQueueKey UTF8String], (__bridge void *)self, NULL);
    //串行队列处理socket相关的操作。
    socketQueue = dispatch_queue_create([socketQueueKey UTF8String], DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(socketQueue, [socketQueueKey UTF8String], (__bridge void *)self, NULL);
    
    //串行队列处理接入的socket连接。
    socketListenningQueue = dispatch_queue_create([socketListenningQueueKey UTF8String], DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_set_specific(socketListenningQueue, [socketListenningQueueKey UTF8String], (__bridge void *)self, NULL);
}

//初始化代理blocks
-(void) initDelBlocks
{
    //收到新的连接
    self.socketBlkDel.didAcceptNewSocket = ^(GCDAsyncSocket *socket ,GCDAsyncSocket * newSocket){
        LogInfo(@"%@收到新的socket连接请求 :%@ ",socket.description ,newSocket.description);
    };
    // 读写block
    self.socketBlkDel.didReadData = ^(GCDAsyncSocket *socket ,NSData * data ,long tag){
        
        LogInfo(@"%@收到 读入的数据：%@ ,tag: %ld" , socket.description,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ,tag);
    };
    self.socketBlkDel.writeDataWithTag = ^AsyncSocketCallbackDel *(long tag){
        LogInfo(@"执行了writedata");
        AsyncSocketCallbackDel * callback = [[AsyncSocketCallbackDel alloc] init];
        callback.failBlk = ^(NSError *err){
            LogError(@"写入错误:%@" ,err);
        };
        callback.successBlk = ^(GCDAsyncSocket *socket){
            LogInfo(@"写入成功 :%@" ,socket.description);
        };
        return callback;
    };
    //连接block
    //关闭读写流
    self.socketBlkDel.socketDidCloseReadStream = ^(GCDAsyncSocket *socket){
        LogInfo(@"关闭读入stream :%@" ,socket.description);
    };
    
    //收到新的sokcet时候重新创建线程来进行socket处理
    self.socketBlkDel.newSocketQueueForConnectionFromAddress = ^dispatch_queue_t (GCDAsyncSocket *socket){
        if (!socketQueue) {
            LogError(@"socketQueue is nil");
            return nil;
        }
        LogInfo(@"socketQueue 正在处理新的socket");
        return socketQueue;
    };
    
    self.socketBlkDel.socketDidDisconnect = ^(GCDAsyncSocket * socket ,NSError * err)
    {
        LogError(@"%@ 断开连接:%@" ,socket.description ,err);
    };
    
    self.socketBlkDel.connectToSocket = ^AsyncSocketCallbackDel *(NSString * server ,uint16_t port){
        LogInfo(@"连接到服务器：%@ ，端口：%d" ,server ,port);
        AsyncSocketCallbackDel * callback = [[AsyncSocketCallbackDel alloc] init];
        callback.successBlk = ^(GCDAsyncSocket *sock ){
            LogInfo(@"%@ 连接成功" ,sock.description);
        };
        callback.failBlk = ^(NSError *err){
            LogError(@"连接失败err:%@" ,err);
        };
        return  callback;
    };
    
    
    
}


-(NSData *) heartData
{
    if (!_heartData) {
        _heartData = [FULL_HEART_STRING dataUsingEncoding:NSUTF8StringEncoding];
    }
    return _heartData;
}
@end
