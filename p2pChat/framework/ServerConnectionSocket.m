//
//  ServerConnectionSocket.m
//  p2pChat
//
//  Created by xiaokun on 16/3/8.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "ServerConnectionSocket.h"
#import "AppDelegate.h"
#import "Tool.h"

@implementation ServerConnectionSocket

- (id)init {
    self = [super initWithDelegate:self];
    return self;
}

+ (instancetype)shareInstance {
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    return appDelegate.serverConnection;
}

#pragma mark - asyncSocket delegate
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    NSLog(@"willDisconnectWithError: %@", err);
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"server connection socket did connect to host");
    NSString *ipStr = [Tool getLocalIp];
    int userId = [[NSUserDefaults standardUserDefaults]integerForKey:@"id"];
    NSDictionary *statusDic = @{@"id":[NSNumber numberWithInt:userId], @"ip":ipStr, @"version":[NSNumber numberWithInt:0]};
    NSData *statusData = [NSJSONSerialization dataWithJSONObject:statusDic options:NSJSONWritingPrettyPrinted error:nil];
    [sock writeData:statusData withTimeout:10 tag:0];
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"did read data: %@", data);
    NSError *err = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&err];
    if (err != nil) {
        NSLog(@"%@", err);
    }
    NSLog(@"%@", dic);
}
@end
