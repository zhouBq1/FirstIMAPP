//
//  AsyncSocketDel.m
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/19.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import "AsyncSocketDel.h"
#import "GCDAsyncSocket.h"
#import "UtilitiesHeader.h"

@implementation AsyncSocketCallbackDel


@end

@interface AsyncSocketDel ()<GCDAsyncSocketDelegate>
{

}
@end

@implementation AsyncSocketDel

-(id) init
{
    if (self = [super init]) {
    }
    return self;
}

#pragma mark -----asyncSocketDelegate
//从addre获取到的新的socket连接
- (dispatch_queue_t)newSocketQueueForConnectionFromAddress:(NSData *)address onSocket:(GCDAsyncSocket *)sock
{
    return self.newSocketQueueForConnectionFromAddress(sock);
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    self.didAcceptNewSocket(sock ,newSocket);
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    self.connectToSocket(host,port).successBlk(sock);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    self.didReadData(sock ,data , tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    NSLog(@"read partial data");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    self.writeDataWithTag(tag).successBlk(sock);
}

- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    self.didWritePartialDataOfLength(sock ,partialLength);
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock
{
    self.socketDidCloseReadStream(sock);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (self.socketDidDisconnect) {
        self.socketDidDisconnect(sock ,err);
    }
    else
    {
        LogError(@"socketDidDisconnect为空");
    }
}
//实现selector与block的相互转化
@end
