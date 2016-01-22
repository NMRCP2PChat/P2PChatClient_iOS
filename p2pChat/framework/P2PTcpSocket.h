//
//  P2PTcpSocket.h
//  p2pChat
//
//  Created by xiaokun on 16/1/13.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "AsyncSocket.h"

#define P2PTcpSocketDidWritePicInfoNotification @"P2PTcpSocketDidWritePicInfoNotification"

typedef NS_ENUM(long, P2PTcpSocketTagType) {
    P2PTcpSocketTagTypeData = 0,
    P2PTcpSocketTagTypeInfo,
    P2PTcpSocketTagTypeAck
};

@interface P2PTcpSocket : AsyncSocket <AsyncSocketDelegate>

+ (instancetype)shareInstance;

@property (assign, nonatomic) BOOL isOn;

@end
