//
//  ZBAsyncSocket.h
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/20.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "AsyncSocketDel.h"
#import "UtilitiesHeader.h"
#import "NetworkingCommonHeader.h"

static NSString *socketDelegateQueueKey = @"asyncSocketDelegateQueue";
static NSString *socketQueueKey = @"asyncSocketQueue";
static NSString *socketListenningQueueKey = @"asyncSocketListenningQueue";

@interface ZBAsyncSocket : GCDAsyncSocket

@property (nonatomic ,retain) AsyncSocketDel * socketBlkDel;
#if OS_OBJECT_USE_OBJC
@property (strong, nonatomic) dispatch_queue_t zbDelegateQueue;
//处理所有的socket的线程
@property (strong, nonatomic) dispatch_queue_t socketQueue;
//处理监听的socket ，坚挺成功之后会在其他的线程上进行正式连接socket的创建来进行数据的传书。而代理则在一条线程上进行统一处理。
@property (strong, nonatomic) dispatch_queue_t socketListenningQueue;
#else
@property (assign, nonatomic) dispatch_queue_t zbDelegateQueue;
@property (assign, nonatomic) dispatch_queue_t socketQueue;
@property (assign, nonatomic) dispatch_queue_t socketListenningQueue;
#endif
//心跳包
@property (nonatomic ,retain) NSData * heartData;
@end
