//
//  P2PTcpSocket.m
//  p2pChat
//
//  Created by xiaokun on 16/1/13.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "P2PTcpSocket.h"
#import "AppDelegate.h"
#import "DataManager.h"

@interface P2PTcpSocket ()

@property (strong, nonatomic) NSNumber *userID;

@end

@implementation P2PTcpSocket

- (id) init {
    self = [super initWithDelegate:self];
    _userID = [NSNumber numberWithUnsignedShort:234];
    
    return self;
}

+ (instancetype)shareInstance {
    P2PTcpSocket *tcpSocket = nil;
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    tcpSocket = delegate.tcpSocket;
    
    return tcpSocket;
}

#pragma mark - delegate
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    NSLog(@"willDisconnectWithError: %@", err);
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
    NSLog(@"SocketDidDisconnect");
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {
    NSLog(@"didAcceptNewSocket");
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (NSRunLoop *)onSocket:(AsyncSocket *)sock wantsRunLoopForNewSocket:(AsyncSocket *)newSocket {
    NSLog(@"wantsRunLoopForNewSocket");
    return [NSRunLoop currentRunLoop];
}

- (BOOL)onSocketWillConnect:(AsyncSocket *)sock {
    NSLog(@"will connect");
    return YES;
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"didConnectToHost: %@", host);
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"did read data");
    NSString *body = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    [[DataManager shareManager]saveMessageWithUserID:_userID time:[NSDate date] body:body isOut:NO];
}

- (void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"didReadPartialDataOfLength");
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"didWriteDataWithTag");
}

- (void)onSocket:(AsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"didWritePartialDataOfLength");
}

@end
