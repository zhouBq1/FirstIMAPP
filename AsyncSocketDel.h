//
//  AsyncSocketDel.h
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/19.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GCDAsyncSocket;

//AsyncSocketCallbackDel 这个callbakc代理仅仅处理一些需要一定过程的连接，一般是客户端。如 ：进行连接 ，进行读写操作？
@interface AsyncSocketCallbackDel : NSObject
@property  (nonatomic ,retain) GCDAsyncSocket * socket;
@property (nonatomic ,strong) void(^failBlk)(NSError *err);
@property (nonatomic ,strong) void(^successBlk)(GCDAsyncSocket * socket);
@end

@interface AsyncSocketDel : NSObject

/*common*/
//@property (nonatomic ,retain) AsyncSocketCallbackDel * callBackBlkDel;
@property (nonatomic ,strong) void (^didReadData)(GCDAsyncSocket *socket , NSData * data ,long tag);

//this would occur if using readToData: or readToLength: methods.处理断包粘包问题
@property (nonatomic ,strong) void (^didReadPartialDataOfLength) (GCDAsyncSocket *socket ,NSUInteger partialLength ,long tag);
//数据写入 ，根据tag进行判断，是否为心跳包的格式
@property (nonatomic ,strong) AsyncSocketCallbackDel *(^writeDataWithTag) (long tag);

//写入数据但没写入完成
@property (nonatomic ,strong) void (^didWritePartialDataOfLength) (GCDAsyncSocket *socket ,long tag);

@property (nonatomic ,strong) void (^socketDidCloseReadStream) (GCDAsyncSocket *socket);

//SSL/TLS安全认证完成之后的操作。
@property (nonatomic ,strong) void (^socketDidSecure) (GCDAsyncSocket *socket);
//断开连接
@property (nonatomic ,strong) void (^socketDidDisconnect) (GCDAsyncSocket * socket ,NSError * err);

/*client*/
@property (nonatomic ,strong) AsyncSocketCallbackDel *(^connectToSocket) ( NSString *address,uint16_t port);
//@property (nonatomic ,strong) void (^didReceiveTrust) ()


/*server*/
//收到socket连入时候 ，新创建线程进行sokcet 的处理
@property (nonatomic ,strong) dispatch_queue_t (^newSocketQueueForConnectionFromAddress) (GCDAsyncSocket *socket);

@property (nonatomic ,strong) void(^didAcceptNewSocket)(GCDAsyncSocket * socket ,GCDAsyncSocket * newSock);

@end
