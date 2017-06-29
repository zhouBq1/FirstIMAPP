//
//  MQTTManager.m
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/12.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import "MQTTManager.h"
#import "NetworkingCommonHeader.h"
#import "MQTTKit.h"

#import "MBProgressHUD+JT.h"

#define MQTT_CONNECT_CODE_ACCEPTED @"连接成功"
#define MQTT_CONNECT_CODE_REFUSED_UNACCEPTABLE_PROTOCOL_VERSION @"协议版本错误"
#define MQTT_CONNECT_CODE_REFUSED_IDENTIFIER_REJECTED @"id被拒绝"
#define MQTT_CONNECT_CODE_REFUSED_SERVER_UNAVAILABLE @"服务器不可达"
#define MQTT_CONNECT_CODE_REFUSED_BAD_USERNAME_OR_PASSWORD @"用户名或密码错误"
#define MQTT_CONNECT_CODE_REFUSED_NOT_AUTHORED @"未授权"

@interface MQTTManager()
{
    MQTTClient * client;
    //mqtt client 不能创建多个，而是只能创建一个client但是这个client可以订阅多个主题
}

@end

@implementation MQTTManager
@synthesize toConnectPort ,toConnectServer;
#pragma mark ----
#pragma mark 外部使用接口
+(id) shareInstance
{
    static MQTTManager * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MQTTManager alloc] init];
    });
    return instance;
}

-(void) createSocket
{
    if (client) {
        //断开连接
        [self disconnect];
    }
    client = [[MQTTClient alloc] initWithClientId:kClientKey cleanSession:YES];
    client.port = toConnectPort != 0?toConnectPort:SERVER_PORT;
    
    [client setMessageHandler:^(MQTTMessage *msg){
        //收到消息的回调 ，前提是需要实现进行订阅
        NSString * msgContent = [[NSString alloc] initWithData:msg.payload encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [MBProgressHUD showSuccess:[NSString stringWithFormat:@"收到的消息为：%@ ,%@ ,%@" ,msgContent ,NSDictionaryOfVariableBindings(msg.topic) ,NSDictionaryOfVariableBindings(@(msg.mid))]];
        });
        
    }];
    
    //连接
    NSString * server = [toConnectServer length] == 0?SERVER_ADDR:toConnectServer;
    [client connectToHost:server completionHandler:^(MQTTConnectionReturnCode code){
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD showSuccess:[NSString stringWithFormat:@"进行连接的结果 ： %@" ,[self conerseWithCode:code]]];
        });
        
        if (code == ConnectionAccepted) {
            //连接成功 ,开始订阅
            [client subscribe:commonSubscribeKey withQos:AtMostOnce completionHandler:^(NSArray* grantedQoss){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD showSuccess:[NSString stringWithFormat:@"granted Qoss is :%@" ,grantedQoss]];
                });
                
                NSLog(@"开启订阅成功");
            }];
        }
    }];
}

-(void) connect
{
    dispatch_async(dispatch_get_main_queue(), ^{
         [MBProgressHUD showSuccess:@"进行连接"];
    });
   
    [self initClient];
}

-(void) disconnect
{
    //断开连接 ，取消订阅
    if (client) {
        [client unsubscribe:commonSubscribeKey withCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD showSuccess:[NSString stringWithFormat:@"取消订阅成功 id：%@",client.clientID]];
            });
            
            NSLog(@"取消订阅成功 id：%@",client.clientID);
        }];
        //断开连接
        [client disconnectWithCompletionHandler:^(NSUInteger code){
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD showSuccess:[NSString stringWithFormat:@"断开连接成功 code：%ld" ,code]];
            });
            
        }];
        client = nil;
    }
}

-(void) sendMessage:(NSString *)msg toTopic:(NSString *) topic
{
    //发送消息 .发送消息给自己订阅的主题 ,
    //发布消息的topic应该为自己的对应id，而应该是commonSubscribe上
    //[topic length]==0?client.clientID:topic
    [client publishString:msg toTopic:client.clientID withQos:AtMostOnce retain:YES completionHandler:^(int mid){
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD showSuccess:[NSString stringWithFormat:@"发送消息成功 mid：%d , topic:%@" ,mid ,client.clientID]];
        });
        
    }];
}

-(void) pullMessage
{

}

-(void) subscribeTopic:(NSString *)topic
{
    [client subscribe:topic withQos:AtMostOnce completionHandler:^(NSArray * grantedQos){
        NSLog(@"subscribe topic result :%@" ,NSDictionaryOfVariableBindings(grantedQos));
    }];
}

-(void) dissubscribeTopic:(NSString *) topic
{
    
    //是否需要判断已经订阅了相关主题。如何判断？
}
#pragma mark ----
#pragma mark 内部私用接口

-(void) initClient
{
    [self createSocket];
}

-(NSString *) conerseWithCode:(MQTTConnectionReturnCode) code
{
    NSString * resultString = nil;
    switch (code) {
        case ConnectionAccepted:
            resultString= MQTT_CONNECT_CODE_ACCEPTED;
            break;
        case ConnectionRefusedUnacceptableProtocolVersion:
            resultString= MQTT_CONNECT_CODE_REFUSED_UNACCEPTABLE_PROTOCOL_VERSION;
            break;
        case ConnectionRefusedServerUnavailable:
            resultString= MQTT_CONNECT_CODE_REFUSED_SERVER_UNAVAILABLE;
            break;
        case ConnectionRefusedIdentiferRejected:
            resultString= MQTT_CONNECT_CODE_REFUSED_IDENTIFIER_REJECTED;
            break;
        case ConnectionRefusedBadUserNameOrPassword:
            resultString = MQTT_CONNECT_CODE_REFUSED_BAD_USERNAME_OR_PASSWORD;
            break;
        case ConnectionRefusedNotAuthorized:
            resultString = MQTT_CONNECT_CODE_REFUSED_NOT_AUTHORED;
            break;
        default:
            resultString = @"位置错误code";
            break;
    }
    return resultString;
}
@end
