//
//  ZBSocketManager.h
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/11.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZBSocketManager : NSObject
//创建单利实例
+(id) shareInstance;
//建立连接
-(BOOL) createSocket;
//-(void) connectWithServer:(NSString *) serverIP onPort:(NSInteger) port;
-(void) connect;
//断开当前连接
-(void) disConnect;
//接受消息
-(void) pullMsg;
- (void)sendMsg:(NSString *)msg;

@property (nonatomic ,assign) BOOL canReconnect;
@property (nonatomic ,assign) NSTimeInterval connectTimeout;
@end
