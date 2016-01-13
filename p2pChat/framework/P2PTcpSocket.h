//
//  P2PTcpSocket.h
//  p2pChat
//
//  Created by xiaokun on 16/1/13.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "AsyncSocket.h"

@interface P2PTcpSocket : AsyncSocket <AsyncSocketDelegate>

+ (instancetype)shareInstance;

@end
