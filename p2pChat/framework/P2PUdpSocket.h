//
//  P2PUdpSocket.h
//  p2pChat
//
//  Created by xiaokun on 16/1/13.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "AsyncUdpSocket.h"
#import "AppDelegate.h"

#define P2PUdpSocketReceiveACKNotification @"P2PUdpSocketReceiveACKNotification"

@interface P2PUdpSocket : AsyncUdpSocket <AsyncUdpSocketDelegate>

+ (instancetype)shareInstance;
- (void)setMessageQueueManager:(MessageQueueManager *)messageQueueManager;

- (NSString *)getAndRemoveThumbnailPath:(int)picID;

@end
