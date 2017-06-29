//
//  AsyncClient.h
//  FirstIMAPP
//
//  Created by F7686296 on 17/4/19.
//  Copyright © 2017年 MyOrg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBAsyncSocket.h"

@interface AsyncClient : ZBAsyncSocket

-(void) connectToServer:(NSString *) serverIP onPort:(uint16_t) port;

-(void) writeStringToServer:(NSData *) string withTag:(long) tag;

-(void) readDataWithTag:(long) tag;

-(void) startHeart;

-(void) terminateHeart;

@end
