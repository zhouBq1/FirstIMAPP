//
//  MQTTManager.h
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/12.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_IPHONE_SIMULATOR
static NSString * kClientKey = @"zhoubao";
#else
static NSString * kClientKey = @"zhoubao device";
#endif
static NSString * commonSubscribeKey = @"zhoubao";

@interface MQTTManager : NSObject
{
    
}

@property (nonatomic ,retain) NSString *toConnectServer;
@property (nonatomic ,assign) NSUInteger toConnectPort;
//-(void) createSocket;

+(id) shareInstance;

-(void) initClient;

-(void) connect;

-(void) disconnect;

-(void) subscribeTopic:(NSString *) topic ;

-(void) sendMessage:(NSString *)msg toTopic:(NSString *) topic ;

-(void) pullMessage;

@end
