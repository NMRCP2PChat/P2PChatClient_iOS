//
//  MessageQueueManager.h
//  p2pChat
//
//  Created by xiaokun on 16/1/8.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AsyncUdpSocket;

@interface MessageQueueManager : NSObject

- (id)initWithSocket:(AsyncUdpSocket *)udpSocket;
+ (instancetype)shareInstance;

- (void)addSendingMessage:(NSString *)ipStr packetData:(NSData *)data;
- (void)messageSended:(unsigned int)packetID;
- (void)sendAgain;

@end
