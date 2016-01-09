//
//  MessageQueueManager.m
//  p2pChat
//
//  Created by xiaokun on 16/1/8.
//  Copyright © 2016年 xiaokun. All rights reserved.
//
// packetInfo = @{@"ipStr" : ipStr, @"data" : data}

#import "MessageQueueManager.h"
#import "MessageProtocal.h"
#import "AppDelegate.h"

@interface MessageQueueManager ()

@property (strong, nonatomic) NSMutableDictionary *sendingQueue;

@property (strong, nonatomic) AsyncUdpSocket *udpSocket;

@end

@implementation MessageQueueManager

- (id)initWithSocket:(AsyncUdpSocket *)udpSocket {
    self = [super init];
    _sendingQueue = [[NSMutableDictionary alloc]init];
    _udpSocket = udpSocket;
    
    return self;
}
+ (instancetype)shareInstance {
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    return delegate.messageQueueManager;
}

- (void)addSendingMessage:(NSString *)ipStr packetData:(NSData *)data {
    unsigned int packetID = [[MessageProtocal shareInstance]getPacketID:data];
    NSDictionary *packetInfo = @{@"ipStr" : ipStr, @"data" : data};
    _sendingQueue[[NSNumber numberWithUnsignedInt:packetID]] = packetInfo;
//    NSLog(@"sending queue number: %d", _sendingQueue.allKeys.count);
}

- (void)messageSended:(unsigned int)packetID {
    [_sendingQueue removeObjectForKey:[NSNumber numberWithUnsignedInt:packetID]];
//    NSLog(@"sending queue number: %d", _sendingQueue.allKeys.count);
}

- (void)sendAgain {
    NSLog(@"MessageQueueManager send again");
    NSArray *keys = _sendingQueue.allKeys;
    for (NSNumber *key in keys) {
        NSDictionary *dic = _sendingQueue[key];
        [_udpSocket sendData:dic[@"data"] toHost:dic[@"ipStr"] port:1234 withTimeout:-1 tag:0];
    }
}

@end
