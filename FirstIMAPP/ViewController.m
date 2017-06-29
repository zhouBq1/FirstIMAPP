//
//  ViewController.m
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/11.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import "ViewController.h"
//#import "ZBSocketManager.h"
#import "MQTTManager.h"

#import "AsyncClient.h"
#import "AsyncServer.h"
#define IS_MQTT_SOCKET NO
#define EIDT_TEXT_MAX_LENGTH 50


static NSString* clientsDictionaryKeyPre = @"client";
@interface ViewController ()
{
//    ZBSocketManager * socketManager;
    UITextField * msgToSendTF;
    MQTTManager * mqttSocketManager;
    
    UITextField * serverFd;
    UITextField * portFd;
    
    NSMutableDictionary * clientsToConnect;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    socketManager = [ZBSocketManager shareInstance];
    mqttSocketManager = [MQTTManager shareInstance];
    
    clientsToConnect = [NSMutableDictionary dictionary];
    
    //编辑server和 port
    serverFd = [[UITextField alloc] initWithFrame:CGRectMake(50, 50, 100, 45)];
    serverFd.placeholder = @"输入服务器ip";
    serverFd.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:serverFd];
    UILabel * seperator = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(serverFd.frame) + 5, CGRectGetMinY(serverFd.frame), 10, 45)];
    seperator.text = @":";
    seperator.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:seperator];
    portFd = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(seperator.frame) + 5, CGRectGetMinY(serverFd.frame), 100, 45)];
    portFd.backgroundColor = [UIColor lightGrayColor];
    portFd.placeholder = @"请输入服务器port";
    [self.view addSubview:portFd];
    
    UIButton * disConnect = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    disConnect.frame = CGRectMake(50, 200, 100, 45);
    [disConnect addTarget:self action:@selector(disConnectAction:) forControlEvents:UIControlEventTouchUpInside];
    [disConnect setTitle:@"断开连接" forState:UIControlStateNormal];
    [disConnect setTitle:@"连接" forState:UIControlStateSelected];
    [disConnect setSelected:NO];
    [self.view addSubview:disConnect];
    
    msgToSendTF = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMinX(disConnect.frame), CGRectGetMaxY(disConnect.frame) + 50, 100, 45)];
    msgToSendTF.placeholder = @"输入需要发送的文本";
    [self.view addSubview:msgToSendTF];
    //添加通知，输入文本长度监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textfieldDidChange:) name:@"UITextFieldTextDidChangeNotification" object:msgToSendTF];
    
    UIButton * sendBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendBtn.frame = CGRectMake(CGRectGetMaxX(msgToSendTF.frame) + 20, CGRectGetMinY(msgToSendTF.frame), 100, 45);
    [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
    [sendBtn addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendBtn];
    
    UIButton * serverStart = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    serverStart.frame = CGRectMake(CGRectGetMinX(msgToSendTF.frame), CGRectGetMaxY(msgToSendTF.frame) + 10, 100, 45);
    [serverStart setTitle:@"服务器未连接" forState:UIControlStateNormal];
    [serverStart setTitle:@"服务器已连接" forState:UIControlStateSelected];
    [serverStart addTarget:self action:@selector(serverStartAction:) forControlEvents:UIControlEventTouchUpInside];
    [serverStart setSelected:NO];
    [self.view addSubview:serverStart];
    
#pragma mark ----init server block
    __weak AsyncServer * weakServer = [AsyncServer shareInstance];
    [AsyncServer shareInstance].socketBlkDel.didReadData = ^(GCDAsyncSocket * socket ,NSData * data ,long tag){
        
        __strong AsyncServer *strongServer = weakServer;
        NSLog(@"服务器收到数据 ,%@" ,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        //收到发送的心跳包 原包进行返回。
//        if (tag == HEART_TAG) {
        if([data isEqualToData:strongServer.heartData])
        {
            [strongServer sendHeartData:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        }
        else
        {
            NSMutableData * toAppData = [NSMutableData data];
            [toAppData appendData:[@"server 收到数据:" dataUsingEncoding:NSUTF8StringEncoding]];
            [toAppData appendData:data];
            [strongServer sendConverData:[NSString stringWithFormat:@"servber收到数据：%@" ,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
        }

        
        [strongServer beginReadData];
    };
    
    UIButton * clientStart0 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    clientStart0.frame = CGRectMake(CGRectGetMinX(serverStart.frame), CGRectGetMaxY(serverStart.frame) + 10, 100, 45);
    [clientStart0 setTitle:@"客户端连接" forState:UIControlStateNormal];
    [clientStart0 addTarget:self action:@selector(clientStartAction:) forControlEvents:UIControlEventTouchUpInside];
    clientStart0.tag = 1000+ 0;
    [self.view addSubview:clientStart0];
    
    UIButton * clientSend0 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    clientSend0.frame = CGRectMake(CGRectGetMaxX(clientStart0.frame) + 20, CGRectGetMinY(clientStart0.frame), 100, 45);
    [clientSend0 setTitle:@"客户端发送" forState:UIControlStateNormal];
    [clientSend0 addTarget:self action:@selector(clientSendAction:) forControlEvents:UIControlEventTouchUpInside];
    clientSend0.tag = 100 + 0;
    [self.view addSubview:clientSend0];
    
    UITapGestureRecognizer * tapGst = [[UITapGestureRecognizer alloc]  initWithTarget:self action:@selector(resignKeyboard:)];
    [self.view addGestureRecognizer:tapGst];
    
    NSMutableData * byteData = [NSMutableData dataWithCapacity:HEART_LENGTH];
   
    
}

-(void) textfieldDidChange:(NSNotification *) obj
{
    UITextField *textField = (UITextField *)obj.object;
    
    NSString *toBeString = textField.text;
    NSString *lang = [[textField textInputMode] primaryLanguage]; // 键盘输入模式
    if ([lang isEqualToString:@"zh-Hans"]) { // 简体中文输入，包括简体拼音，健体五笔，简体手写
        UITextRange *selectedRange = [textField markedTextRange];
        //获取高亮部分
        UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
        // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
        if (!position) {
            if (toBeString.length > EIDT_TEXT_MAX_LENGTH) {
                textField.text = [toBeString substringToIndex:EIDT_TEXT_MAX_LENGTH];
            }
        }
        // 有高亮选择的字符串，则暂不对文字进行统计和限制
        else{
            
        }
    }
    // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
    else{
        if (toBeString.length > EIDT_TEXT_MAX_LENGTH) {
            textField.text = [toBeString substringToIndex:EIDT_TEXT_MAX_LENGTH];
        }
    }
}
-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (IS_MQTT_SOCKET) {
        [mqttSocketManager connect];
        return;
    }
//    [socketManager createSocket];
//    [socketManager connect];
//    [socketManager pullMsg];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//-(BOOL) isDataServerHeartData:(NSData *)data
//{
//    NSString * dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    if ([dataString isEqual:FULL_SERVER_HEART_STRING]) {
//        return YES;
//    }
//    return NO;
//}

#pragma mark ----disConnectAction
-(void) disConnectAction:(UIButton *)btn
{
    [btn setSelected:!btn.isSelected];
    if (IS_MQTT_SOCKET) {
        mqttSocketManager.toConnectServer = serverFd.text;
        mqttSocketManager.toConnectPort = [portFd.text integerValue];
        !btn.isSelected?[mqttSocketManager disconnect]:[mqttSocketManager connect];
        return;
    }
//    btn.isSelected?[socketManager disConnect]:[socketManager connect];
    
    
}
-(void) sendAction:(UIButton *) btn
{
    if (IS_MQTT_SOCKET) {
        msgToSendTF.text.length != 0?[mqttSocketManager sendMessage:[NSString stringWithFormat:@"%@" ,[NSString stringWithFormat:@"%@%@" ,msgToSendTF.text ,STRING_END]] toTopic:commonSubscribeKey]:NSLog(@"没有需要发送的信息");
    }
//    msgToSendTF.text.length != 0?[socketManager sendMsg:msgToSendTF.text]:NSLog(@"没有需要发送的信息");
}

-(void) serverStartAction:(UIButton *) btn
{
    if (!btn.isSelected) {
        if ([[AsyncServer shareInstance] beginListening]) {
            [[AsyncServer shareInstance] beginReadData];
        }
        else
            return;
    }
    else
    {
        //如果readdata都是在同一个线程的话怎样保证多个连接任务同时读写， 根据tag来进行区分吗？只是在线程上进行数据的获取，而没有为某一条连接单独开辟的线程进行处理读写？√
        [[AsyncServer shareInstance] stopReadData];
        [[AsyncServer shareInstance] stopListenning];
    }
    btn.selected = !btn.isSelected;
}

-(void) clientStartAction:(UIButton *) btn
{
    //客户端的进行连接
    AsyncClient * client = [[AsyncClient alloc] init];
    [clientsToConnect  setObject:client forKey:[NSString stringWithFormat:@"%@-%ld" ,clientsDictionaryKeyPre ,btn.tag - 1000]];
    [client connectToServer:serverFd.text onPort:[portFd.text intValue]];
    
    __weak ViewController * weakSelf = self;
    __weak AsyncClient *weakClient = client;
    client.socketBlkDel.connectToSocket = ^AsyncSocketCallbackDel *(NSString * addrIP ,uint16_t port){
        AsyncSocketCallbackDel * callback = [[AsyncSocketCallbackDel alloc] init];
        callback.successBlk = ^(GCDAsyncSocket *sock){
            __strong AsyncClient *strongClient = weakClient;
            LogInfo(@"客户端%@ 连接成功" ,sock);
            NSMutableData * byteData = [NSMutableData dataWithCapacity:HEART_LENGTH];
            
            Byte head = 0x01;//1byte ,string
            unsigned int length = 216;//4 int
            unsigned long userId = 18566235740;//8 long
            unsigned short deviceType = 1;//2 short
            unsigned long mac = 0xf0f16b146bdc;//2 long
            unsigned short actionType = 13; //2 short
            unsigned short actionValue = 14;//2 shrot
            Byte endB = 0x0a;
        
            
            [byteData appendBytes:&head length:sizeof(Byte)];
            [byteData appendBytes:convertToLittleEndianInt(length) length:sizeof(int)];
            [byteData appendBytes:convertToLittleEndianLong(userId) length:sizeof(long)];
            [byteData appendBytes:convertToLittleEndianShort(deviceType) length:sizeof(short)];
            [byteData appendBytes:convertToLittleEndianLong(mac) length:sizeof(long)];
            [byteData appendBytes:convertToLittleEndianShort(actionType) length:sizeof(short)];
            [byteData appendBytes:convertToLittleEndianShort(actionValue) length:sizeof(short)];
            [byteData appendBytes:&endB length:sizeof(Byte)];
            
            strongClient.heartData = byteData;
            [strongClient startHeart];
            [strongClient readDataWithTag:HEART_TAG];
            [strongClient readDataWithTag:CLIENT_READ_TAG];
        };
        callback.failBlk = ^(NSError *err){
            LogInfo(@"客户端链接失败 err:%@" ,err);
        };
        return callback;
    };
    
    client.socketBlkDel.writeDataWithTag = ^AsyncSocketCallbackDel *(long tag){
        AsyncSocketCallbackDel * callback = [[AsyncSocketCallbackDel alloc] init];
        NSMutableString * logInfo = [NSMutableString stringWithString:[NSString stringWithFormat:@"客户端发送"]] ;
        if (tag == HEART_TAG ) {
            LogInfo(@"=============心跳数据写入==================");
            [logInfo appendFormat:@"心跳数据"];
        }
        callback.successBlk = ^(GCDAsyncSocket*sock){
            [logInfo appendFormat:@"成功"];
            LogInfo(@"%@" ,logInfo);
            [weakClient readDataWithTag:HEART_TAG];
            [weakClient readDataWithTag:CLIENT_READ_TAG];
        };
        callback.failBlk = ^(NSError * err){
            [logInfo appendFormat:@"%@", [NSString stringWithFormat:@"失败：%@" ,err]];
        };
        return callback;
    };
    
    client.socketBlkDel.didReadData = ^(GCDAsyncSocket *sock ,NSData * data ,long tag){
        LogInfo(@"客户端sock：%@ ，收到数据：%@ " ,sock.description ,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        __strong AsyncClient * strongClient = weakClient;
        if ( [data isEqualToData:strongClient.heartData]/*&&tag == HEART_TAG */) {
            LogInfo(@"客户端收到服务端返回的信条数据");
            LogInfo(@"================心跳数据结束==========================");
        }
    };
}

-(void) clientSendAction:(UIButton *) btn
{
    AsyncClient * client = [clientsToConnect objectForKey:[NSString stringWithFormat:@"%@-%ld" ,clientsDictionaryKeyPre ,btn.tag - 100]];
    [client writeStringToServer:[[NSString stringWithFormat:@"%@" ,[NSString stringWithFormat:@"%@%@" ,msgToSendTF.text ,STRING_END]] dataUsingEncoding:NSUTF8StringEncoding] withTag:CLIENT_WRITE_TAG];
}

-(void) resignKeyboard:(UITapGestureRecognizer *) tap
{
    if ([msgToSendTF isFirstResponder] || [serverFd isFirstResponder] || [portFd isFirstResponder]) {
        [msgToSendTF resignFirstResponder];
        [serverFd resignFirstResponder];
        [portFd resignFirstResponder];
        
    }
}


#pragma mark ---
#pragma mark 位移操作进行大小端读写的转化。

Byte * convertToLittleEndianInt(unsigned int data)
{
    Byte * byteA = (Byte*)&data;
    Byte * resultB = malloc(sizeof(int));
    int size = sizeof(int);
    
    data = ((data & 0xff000000) >> 24)
    | ((data & 0x00ff0000) >>  8)
    | ((data & 0x0000ff00) <<  8)
    | ((data & 0x000000ff) << 24);
    
    for (int index = 0; index < size;index ++) {
        resultB[index] = *byteA;
        byteA ++;
    }
    return resultB;
}

Byte * convertToLittleEndianShort(unsigned short data)
{
    Byte * byteA = (Byte*)&data;
    Byte * resultB = malloc(sizeof(short));
    int size = sizeof(short);
    
    data = ((data &0xff00)>> 8)
    | ((data &0x00ff)<<8);
    for (int index = 0; index < size; index ++) {
        resultB[index] = *byteA;
        byteA ++;
    }
    return resultB;
}

Byte * convertToLittleEndianLong(unsigned long  data)
{
    Byte * byteA = (Byte*)&data;
    Byte * resultB = malloc(sizeof(long));
    int size = sizeof(short);
    
    data = ((data & 0xff00000000000000) >> 56)
    | ((data & 0x00ff000000000000) >> 40)
    | ((data & 0x0000ff0000000000) >> 24)
    | ((data & 0x000000ff00000000) >> 8)
    | ((data & 0x00000000ff000000) << 8)
    | ((data & 0x0000000000ff0000) << 24)
    | ((data & 0x000000000000ff00) << 40)
    | ((data & 0x00000000000000ff) << 56);
    
    for(int index = 0 ;index < size ;index ++)
    {
        resultB[index] = *byteA;
        byteA ++;
    }
    return resultB;
    
}

@end
