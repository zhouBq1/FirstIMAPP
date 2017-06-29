//
//  NetworkingCommonHeader.h
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/12.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#ifndef NetworkingCommonHeader_h
#define NetworkingCommonHeader_h

#define SERVER_ADDR @"192.168.1.233"
#define SERVER_PORT 6667

//字符串结束标志,传输字符串结束标志
#define STRING_END @"\n"

//设置心跳
//间隔 4'45 ,心跳包data
#define HEART_INTERVAL 5.0
#define HEART_STRING @"CHB"
#define SERVER_HEART_STRING @"SHB"
#define FULL_HEART_STRING [NSString stringWithFormat:@"%@%@" ,HEART_STRING ,STRING_END]
#define FULL_SERVER_HEART_STRING [NSString stringWithFormat:@"%@%@" ,SERVER_HEART_STRING ,STRING_END]
#define HEART_TAG 11
#define HEART_LENGTH 216

#define SERVER_CONVER_TAG 110

//设置时候应该会通过在服务器登录时候分配一个整个im系统唯一的tag来进行相互间的通信
//一个客户端与一个服务器允许的wr的tag唯一？
#if TARGET_IPHONE_SIMULATOR
#define CLIENT_WRITE_TAG 100
#define CLIENT_READ_TAG 101
#else
#define CLIENT_WRITE_TAG 110
#define CLIENT_READ_TAG 111
#endif

//相关配置
#define MAX_RECONNECT_COUNT 20

#endif /* NetworkingCommonHeader_h */
