//
//  AsyncServer.m
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/19.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import "AsyncServer.h"
#import "GCDAsyncSocket.h"


@interface AsyncServer ()
//1 block 的使用 a ：在h中不使用block的变量，而是直接使用block的完全定义，好处，直观，易于外部调用 b：在m中使用block变量对内方便调用，减少代码量，
//2  block 的使用 在h中使用block变量 ，并且变量的返回值定义为[self class] ，实现了链式编程 ，定义了变量间的层级关系，逻辑清晰。 易于外部理解
//心跳规则： 客户端发送一个心跳包数据，服务器收到包后原包返回。
{
    //是否不需要listenningsocket ，因为直接连接self ，self会在代理方法里自动创建线程度读写 ，self本身相当于实现了listenningSocket的功能，
//    GCDAsyncSocket * listenningSocket;
}
@property (nonatomic ,strong) AsyncServer *(^didAcceptNewSocket) (GCDAsyncSocket * socket);
//readSocket 接收到的新的socket ，在acceot方法中获取到，
@property (nonatomic ,strong) GCDAsyncSocket * readSocket;
@end

@implementation AsyncServer
@synthesize socketBlkDel;
+(instancetype) shareInstance
{
    static dispatch_once_t onceToken;
    static AsyncServer * instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(id) init
{
    dispatch_queue_t listenQueue = dispatch_queue_create([socketListenningQueueKey UTF8String], DISPATCH_QUEUE_SERIAL);
    if (self = [super initWithSocketQueue:listenQueue]) {
        [self initListenningSocket];
    }
    
    return self;
}

//初始化监听socket
-(void) initListenningSocket
{

    __weak AsyncServer *weakSelf = self;
    
    self.socketBlkDel.didAcceptNewSocket = ^(GCDAsyncSocket *sock ,GCDAsyncSocket *newSock){
        __strong AsyncServer*strongSelf = weakSelf;
        //获取到新的socket连接 ，对连入的socket数组进行操作。
        LogInfo(@"服务器%@收到新的连接%@" ,sock.description ,newSock.description);
        
        [strongSelf.connectedClient addObject:(AsyncClient*)newSock];
        strongSelf.readSocket = newSock;
        [newSock readDataWithTimeout:-1 tag:0];
    };
    
    self.socketBlkDel.socketDidDisconnect = ^(GCDAsyncSocket *socket ,NSError * err)
    {
        LogInfo(@"服务器%@断开连接err:%@" ,socket.description ,err);
        __strong AsyncServer*strongSelf = weakSelf;
        
        //socket断开连接  ，对连入的socket数组进行操作
        if ([strongSelf.connectedClient containsObject:(AsyncClient *)socket]) {
            [strongSelf.connectedClient removeObject:(AsyncClient *)socket];
        }
    };


    //设置接收到新的连接时候的处理，将新的连接交给socket线程进行处理
    //步骤 ： didaccept之后，设置newsocketqueue 来执行didAcceptNewSocket 中的newsocket的相关读写操作 ，当需要进行长连接的情况下需要retainnewSocket来进行保存 ，调用readData阻塞来继续接收数据
    LogInfo(@"服务器将连接交给socketQueue");
    __strong AsyncServer *strongSelf = weakSelf;
    
    self.socketBlkDel.newSocketQueueForConnectionFromAddress = ^dispatch_queue_t(GCDAsyncSocket *sock){
#if OS_OBJECT_USE_OBJC
        return strongSelf.socketQueue;
#else
        dispatch_retain(strongSelf.socketQueue);
        return strongSelf.socketQueue;
#endif
        
    };
    
    self.socketBlkDel.didReadData = ^(GCDAsyncSocket * socket ,NSData * data ,long tag){
        NSString * contentString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        LogInfo(@"服务器：%@收到数据：%@" ,socket.description ,contentString);
        __strong AsyncServer * strongSelf = weakSelf;
        
        //收到发送的心跳包 原包进行返回。
        if (tag == HEART_TAG) {
            [strongSelf sendHeartData:contentString];
        }
    };
    
}


#pragma mark ---- 对外接口
//开始进行监听
-(BOOL) beginListening
{
    NSError * listenErr;
    //acceptOnPort函数 执行了listen 和bind操作 ，之后执行程序的阻塞 ，接受accept方法的返回socketfd
    //当监听端口处于连接状态时候断开连接重新进行连接
 
    if (self.isConnected) {
        [self disconnect];
    }
    
    if (![self acceptOnPort:SERVER_PORT error:&listenErr]) {
        LogError(@"listen socket 创建失败 :%@" ,listenErr);
        return NO;
    }
    return YES;
}

-(void) stopListenning
{
    [self disconnect];
}

-(void) beginReadData
{
//    [self readDataWithTimeout:-1 tag:0];
    [self.readSocket readDataWithTimeout:-1 tag:0];
}

-(void) stopReadData
{
    
    [self.readSocket disconnect];
    self.readSocket = nil;
}

-(void) writeStringToClient:(NSString *) string withTag:(long)tag
{
    if (!self.isConnected) {
        LogError(@"客户端未连接 ,写入失败");
        return;
    }
    
    [self.readSocket writeData:[string dataUsingEncoding:NSUTF8StringEncoding] withTimeout:MAXFLOAT tag:tag];
}

-(void) sendHeartData:(NSString *) data
{
    [self.readSocket writeData:[data dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:HEART_TAG];
}

-(void) sendConverData:(NSString *) data
{
    [self.readSocket writeData:[data dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:SERVER_CONVER_TAG];
}
#pragma  mark ----.数组的安全操作：使用单线程同步写，多线程异步读，添加信号量进行通知。
-(NSMutableArray <AsyncClient *>*) connectedClient
{
    
    if (!_connectedClient) {
        _connectedClient = [NSMutableArray array];
    }
    return _connectedClient;
}
@end
