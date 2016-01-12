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

@property (strong, nonatomic, readonly) NSMutableDictionary *sendingQueue;

- (id)initWithSocket:(AsyncUdpSocket *)udpSocket timer:(NSTimer *)timer;
+ (instancetype)shareInstance;

- (void)addSendingMessageIP:(NSString *)ipStr packetData:(NSData *)data;
- (void)messageSended:(unsigned int)packetID;
- (void)sendAgain;

@end
