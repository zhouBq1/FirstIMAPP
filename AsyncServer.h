//
//  AsyncServer.h
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/19.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBAsyncSocket.h"

@class AsyncClient;

@interface AsyncServer : ZBAsyncSocket
//处理一些链接过程中的逻辑 ,

@property (nonatomic ,retain) NSMutableArray<AsyncClient *> *connectedClient;

+(instancetype) shareInstance;

-(BOOL) beginListening;

-(void) beginReadData;

-(void) stopListenning;

-(void) stopReadData;

-(void) sendHeartData:(NSString *) data;

-(void) sendConverData:(NSString *) data;
@end
