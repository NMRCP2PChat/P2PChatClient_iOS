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

- (id)init {
    self = [super init];
    _sendingQueue = [[NSMutableDictionary alloc]init];
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    _udpSocket = delegate.udpSocket;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(addSendingMessage:) name:MessageProtocalSendingNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(messageSended:) name:MessageProtocalDidSendNotification object:nil];
    
    return self;
}

- (void)addSendingMessage:(NSDictionary *)packetInfo {
    NSData *data = packetInfo[@"data"];
    unsigned int packetID = [[MessageProtocal shareInstance]getPacketID:data];
    _sendingQueue[[NSNumber numberWithUnsignedInt:packetID]] = packetInfo;
}

- (void)messageSended:(unsigned int)packetID {
    [_sendingQueue removeObjectForKey:[NSNumber numberWithUnsignedInt:packetID]];
}

- (void)sendAgain {
    NSArray *keys = _sendingQueue.allKeys;
    for (NSNumber *key in keys) {
        NSDictionary *dic = _sendingQueue[key];
        [_udpSocket sendData:dic[@"data"] toHost:dic[@"ipStr"] port:1234 withTimeout:-1 tag:0];
    }
}

@end
