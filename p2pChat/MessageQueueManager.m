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
#import "P2PUdpSocket.h"

@interface MessageQueueManager ()

@property (strong, nonatomic) P2PUdpSocket *udpSocket;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation MessageQueueManager

- (id)initWithSocket:(P2PUdpSocket *)udpSocket timer:(NSTimer *)timer {
    self = [super init];
    _sendingQueue = [[NSMutableDictionary alloc]init];
    _udpSocket = udpSocket;
    _timer = timer;
    
    return self;
}
+ (instancetype)shareInstance {
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    return delegate.messageQueueManager;
}

- (void)addSendingMessageIP:(NSString *)ipStr packetData:(NSData *)data {
    unsigned char packetID = [[MessageProtocal shareInstance]getPacketID:data];
    NSDictionary *packetInfo = @{@"ipStr" : ipStr, @"data" : data};
    _sendingQueue[[NSNumber numberWithChar:packetID]] = packetInfo;
    [_timer setFireDate:[NSDate date]];
//    NSLog(@"sending queue number: %d", _sendingQueue.allKeys.count);
}

- (void)messageSended:(unsigned int)packetID {
    [_sendingQueue removeObjectForKey:[NSNumber numberWithChar:packetID]];
    if (_sendingQueue.allKeys.count == 0) {
        [_timer setFireDate:[NSDate distantFuture]];
    }
//    NSLog(@"sending queue number: %lu", (unsigned long)_sendingQueue.allKeys.count);
}

- (void)sendAgain {
//    NSLog(@"MessageQueueManager send again");
    NSArray *keys = _sendingQueue.allKeys;
    for (NSNumber *key in keys) {
        NSDictionary *dic = _sendingQueue[key];
        [_udpSocket sendData:dic[@"data"] toHost:dic[@"ipStr"] port:UdpPort withTimeout:-1 tag:0];
    }
}

@end
