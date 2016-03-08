//
//  ServerConnectionSocket.h
//  p2pChat
//
//  Created by xiaokun on 16/3/8.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "AsyncSocket.h"

@interface ServerConnectionSocket : AsyncSocket <AsyncSocketDelegate>

+ (instancetype)shareInstance;

//- (BOOL)connectToServer:(NSString *)host WithError:(NSError **)error;

@end
