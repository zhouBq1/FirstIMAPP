//
//  ZBSocketManager.m
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/11.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import "ZBSocketManager.h"

#import "GCDAsyncSocket.h"
#import "NetworkingCommonHeader.h"

#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

#define IS_GCD_SOCKET YES

/*
 //socket 创建并初始化 socket，返回该 socket 的文件描述符，如果描述符为 -1 表示创建失败。
 int socket(int addressFamily, int type,int protocol)
 //关闭socket连接
 int close(int socketFileDescriptor)
 //将 socket 与特定主机地址与端口号绑定，成功绑定返回0，失败返回 -1。
 int bind(int socketFileDescriptor,sockaddr *addressToBind,int addressStructLength)
 //接受客户端连接请求并将客户端的网络地址信息保存到 clientAddress 中。
 int accept(int socketFileDescriptor,sockaddr *clientAddress, int clientAddressStructLength)
 //客户端向特定网络地址的服务器发送连接请求，连接成功返回0，失败返回 -1。
 int connect(int socketFileDescriptor,sockaddr *serverAddress, int serverAddressLength)
 //使用 DNS 查找特定主机名字对应的 IP 地址。如果找不到对应的 IP 地址则返回 NULL。
 hostent* gethostbyname(char *hostname)
 //通过 socket 发送数据，发送成功返回成功发送的字节数，否则返回 -1。
 int send(int socketFileDescriptor, char *buffer, int bufferLength, int flags)
 //从 socket 中读取数据，读取成功返回成功读取的字节数，否则返回 -1。
 int receive(int socketFileDescriptor,char *buffer, int bufferLength, int flags)
 //通过UDP socket 发送数据到特定的网络地址，发送成功返回成功发送的字节数，否则返回 -1。
 int sendto(int socketFileDescriptor,char *buffer, int bufferLength, int flags, sockaddr *destinationAddress, int destinationAddressLength)
 //从UDP socket 中读取数据，并保存发送者的网络地址信息，读取成功返回成功读取的字节数，否则返回 -1 。
 int recvfrom(int socketFileDescriptor,char *buffer, int bufferLength, int flags, sockaddr *fromAddress, int *fromAddressLength)
 */
@interface ZBSocketManager()<GCDAsyncSocketDelegate>
{
    GCDAsyncSocket *gcdSocket;
    BOOL stopByUser;
}
@property (nonatomic,assign)int clientScoket;
@end

@implementation ZBSocketManager
@synthesize connectTimeout;
#pragma mark 对内逻辑
+(id) shareInstance
{
    static dispatch_once_t onceToken;
    static ZBSocketManager * instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

-(BOOL) createSocket
{
    BOOL createResult = [self initScoket];
    [self pullMsg];
    return createResult;
}

- (BOOL)initScoket
{
    stopByUser = NO;
    self.canReconnect = YES;
    connectTimeout = 3.0;
    //使用gcddAsyncSocket创建socket
    if (IS_GCD_SOCKET) {
        gcdSocket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        return [gcdSocket isEqual:nil];
    }
    
    
    //每次连接前，先断开连接
    if (_clientScoket != 0) {
        [self disConnect];
        _clientScoket = 0;
    }
    
    //创建客户端socket   
    _clientScoket = CreateClinetSocket();
    
    //服务器Ip
    const char * server_ip= [SERVER_ADDR UTF8String];
    //服务器端口
    short server_port= SERVER_PORT;
    //等于0说明连接失败
    if (ConnectionToServer(_clientScoket,server_ip, server_port)==0) {
        printf("Connect to server error\n");
        return NO;
    }
    //走到这说明连接成功
    printf("Connect to server ok\n");
    return YES;
}

static int CreateClinetSocket()
{
    int ClinetSocket = 0;
    //创建一个socket,返回值为Int。（注scoket其实就是Int类型）
    //第一个参数addressFamily IPv4(AF_INET) 或 IPv6(AF_INET6)。
    //第二个参数 type 表示 socket 的类型，通常是流stream(SOCK_STREAM) 或数据报文datagram(SOCK_DGRAM)
    //第三个参数 protocol 参数通常设置为0，以便让系统自动为选择我们合适的协议，对于 stream socket 来说会是 TCP 协议(IPPROTO_TCP)，而对于 datagram来说会是 UDP 协议(IPPROTO_UDP)。
    ClinetSocket = socket(AF_INET, SOCK_STREAM, 0);
    return ClinetSocket;
}
static int ConnectionToServer(int client_socket,const char * server_ip,unsigned short port)
{
    
    //生成一个sockaddr_in类型结构体
    struct sockaddr_in sAddr={0};
    sAddr.sin_len=sizeof(sAddr);
    //设置IPv4
    sAddr.sin_family=AF_INET;
    
    //inet_aton是一个改进的方法来将一个字符串IP地址转换为一个32位的网络序列IP地址
    //如果这个函数成功，函数的返回值非零，如果输入地址不正确则会返回零。
    inet_aton(server_ip, &sAddr.sin_addr);
    
    //htons是将整型变量从主机字节顺序转变成网络字节顺序，赋值端口号
    sAddr.sin_port=htons(port);
    
    //用scoket和服务端地址，发起连接。
    //客户端向特定网络地址的服务器发送连接请求，连接成功返回0，失败返回 -1。
    //注意：该接口调用会阻塞当前线程，直到服务器返回。
    if (connect(client_socket, (struct sockaddr *)&sAddr, sizeof(sAddr))==0) {
        return client_socket;
    }
    return 0;
}

-(void) reconnect
{
    //可以重连的情况：
    static int currentReconCount = 0;
    
    if (!self.canReconnect) {
        currentReconCount = 0;
        return;
    }
    if (gcdSocket.isConnected) {
        currentReconCount = 0;
        NSLog(@"当前socket已经连接 ，不需要重新连接");
        return;
    }
    
    if (currentReconCount >= MAX_RECONNECT_COUNT) {
        NSLog(@"超出最大连接次数(%d)",MAX_RECONNECT_COUNT);
        return;
    }
    
    currentReconCount ++;
    NSError * connectErr;
    if (![gcdSocket connectToHost:SERVER_ADDR onPort:SERVER_PORT withTimeout:connectTimeout error:&connectErr]) {
        NSLog(@"进行连接出错:%@" ,connectErr);
    }

}

-(void) cancelReconnect
{
    stopByUser = YES;
}
#pragma mark - 新线程来接收消息

- (void)pullMsg
{
    //监听读数据的代理  -1永远监听，不超时，但是只收一次消息，
    //所以每次接受到消息还得调用一次
    if (IS_GCD_SOCKET) {
        NSTimeInterval readTimeout = -1;
        long readTag = 100+ 1;
        [gcdSocket readDataWithTimeout:readTimeout tag:readTag];
        return;
    }
    
    NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(recieveAction) object:nil];
    NSLog(@"current thread is %@" ,[[NSThread currentThread] description]);
    [thread start];
    
    
}

#pragma mark - 对外逻辑

- (void)connect
{
    if (IS_GCD_SOCKET) {
        [gcdSocket connectToHost:SERVER_ADDR onPort:SERVER_PORT withTimeout:connectTimeout error:nil];
        return;
    }
    [self initScoket];
}
- (void)disConnect
{
    //关闭连接
    if (IS_GCD_SOCKET){[gcdSocket disconnect];return;}
    
    close(self.clientScoket);
}

//发送消息
- (void)sendMsg:(NSString *)msg
{
    if (IS_GCD_SOCKET) {
        NSTimeInterval writeTimeout = 3.0;
        long writeTag = 100;
        [gcdSocket writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] withTimeout:writeTimeout tag:writeTag];
        return;
    }
    
    const char *send_Message = [msg UTF8String];
    send(self.clientScoket,send_Message,strlen(send_Message)+1,0);
    
}

//收取服务端发送的消息
- (void)recieveAction{
    while (1) {
        char recv_Message[1024] = {0};
        recv(self.clientScoket, recv_Message, sizeof(recv_Message), 0);
        printf("收到信息：%s\n",recv_Message);
    }
}

#pragma mark ----
#pragma mark gcdAsyncSocketDelegate functions
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"gcdAsyncSocket did connect to host :%@ ,on port :%d",host , port);
}

-(void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"gcdAsyncSocket did disconnect");
    [self reconnect];
}

-(void) socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"gcdAsyncSocket did write data");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    //这里传输的字符串编码格式是否还是utf8？
    NSLog(@"gcdAsyncSocket did read data :%@ ,with Tag :%ld" ,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], tag);
    //继续进行read
    [self pullMsg];
}

//为上一次设置的读取数据代理续时 (如果设置超时为-1，则永远不会调用到)
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    NSLog(@"shouldTimeoutReadWithTag with Tag:%ld ,elapseTimeout:%f ,bytesDown:%ld ",tag , elapsed ,length);
    return 2.0;
}
@end
