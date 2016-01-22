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
#import "PhotoLibraryCenter.h"
#import "P2PUdpSocket.h"

@interface P2PTcpSocket () <PhotoLibraryCenterDelegate> {
    int picID;
}

@property (strong, nonatomic) NSNumber *userID;
@property (strong, nonatomic) NSMutableData *buff;
@property (strong, nonatomic) PhotoLibraryCenter *photoCenter;

@end

static char ack = 1;

@implementation P2PTcpSocket

- (id) init {
    self = [super initWithDelegate:self];
    _userID = [NSNumber numberWithUnsignedShort:234];
    _isOn = NO;
    _buff = [[NSMutableData alloc]init];
    _photoCenter = [[PhotoLibraryCenter alloc]init];
    _photoCenter.delegate = self;
    
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
    _isOn = NO;
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
    NSLog(@"disconnect");
    if (_buff.length != 0) {
        NSLog(@"SocketDidDisconnect, buff length: %lu", (unsigned long)_buff.length);
        UIImage *image = [UIImage imageWithData:_buff];
        [_photoCenter saveImage:image];
        [_buff setLength:0];// clear
    }    
    
    _isOn = NO;
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {
    NSLog(@"didAcceptNewSocket");
    [newSocket readDataWithTimeout:60 tag:P2PTcpSocketTagTypeInfo];
    _isOn = YES;
}

- (NSRunLoop *)onSocket:(AsyncSocket *)sock wantsRunLoopForNewSocket:(AsyncSocket *)newSocket {
    NSLog(@"wantsRunLoopForNewSocket");
    return [NSRunLoop currentRunLoop];
}

- (BOOL)onSocketWillConnect:(AsyncSocket *)sock {
    NSLog(@"will connect");
    _isOn = YES;
    return YES;
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"did read data, length: %lu, tag: %ld", (unsigned long)data.length, tag);
    char tmp;
    switch (tag) {
        case P2PTcpSocketTagTypeData:
            [_buff appendData:data];
            [sock readDataWithTimeout:60 tag:P2PTcpSocketTagTypeData];
            break;
        case P2PTcpSocketTagTypeInfo:
            [data getBytes:&picID length:sizeof(int)];
            [sock writeData:[NSData dataWithBytes:&ack length:sizeof(char)] withTimeout:10 tag:P2PTcpSocketTagTypeAck];
            [sock readDataWithTimeout:60 tag:P2PTcpSocketTagTypeData];
            break;
        case P2PTcpSocketTagTypeAck:
            [data getBytes:&tmp length:sizeof(char)];
            if (tmp == ack) {
                [[NSNotificationCenter defaultCenter]postNotificationName:P2PTcpSocketDidWritePicInfoNotification object:nil];
                tmp = 0;
            }
            break;
    }
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"did Write Data With Tag: %ld", tag);
    switch (tag) {
        case P2PTcpSocketTagTypeData:
            [sock disconnect];
            break;
        case P2PTcpSocketTagTypeInfo:
            [sock readDataWithTimeout:60 tag:P2PTcpSocketTagTypeAck];
            break;
        case P2PTcpSocketTagTypeAck:
            [sock readDataWithTimeout:60 tag:P2PTcpSocketTagTypeData];
            break;
    }
}

#pragma mark - photo library center delegate
- (void)photoLibraryCenterSavedImageWithLocalIdentifier:(NSString *)localIdentifier {
    NSString *thumbnailPath = [[P2PUdpSocket shareInstance]getAndRemoveThumbnailPath:picID];
    [[DataManager shareManager]savePhotoWithUserID:[NSNumber numberWithUnsignedShort:picID >> 16] time:[NSDate date] path:localIdentifier thumbnail:thumbnailPath isOut:NO];
}
@end
