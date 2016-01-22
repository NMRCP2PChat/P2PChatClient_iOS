//
//  P2PUdpSocket.m
//  p2pChat
//
//  Created by xiaokun on 16/1/13.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "P2PUdpSocket.h"
#import "MessageProtocal.h"
#import "DataManager.h"
#import "Tool.h"
#import "MessageQueueManager.h"
#import "P2PTcpSocket.h"

@interface P2PUdpSocket ()

@property (strong, nonatomic) MessageProtocal *messageProtocal;
@property (strong, nonatomic) DataManager *dataManager;
@property (readonly, strong, nonatomic) MessageQueueManager *messageQueueManager;

@property (strong, nonatomic) NSMutableDictionary<NSNumber *, NSData *> *buff;
@property (strong, nonatomic) NSMutableArray *recentMessageQueue;
@property (strong, nonatomic) NSMutableDictionary<NSNumber *, NSString *> *uncomparedPic;

@property (strong, nonatomic) P2PTcpSocket *tcpSocket;

@end

@implementation P2PUdpSocket

- (id)init {
    self = [super initWithDelegate:self];
    NSError *err = nil;
    if (![self bindToPort:UdpPort error:&err]) {
        NSLog(@"p2p udp socket bind port failed: %@", err);
    }
    _messageProtocal = [MessageProtocal shareInstance];
    _dataManager = [DataManager shareManager];
    _buff = [[NSMutableDictionary alloc]initWithCapacity:15];
    _recentMessageQueue = [[NSMutableArray alloc]initWithCapacity:50];
    _uncomparedPic = [[NSMutableDictionary alloc]init];
    _messageQueueManager = [MessageQueueManager shareInstance];
    _tcpSocket = [P2PTcpSocket shareInstance];
    
    return self;
}

- (void)setMessageQueueManager:(MessageQueueManager *)messageQueueManager {
    _messageQueueManager = messageQueueManager;
}

+ (instancetype)shareInstance {
    P2PUdpSocket *udpSocket = nil;
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    udpSocket = delegate.udpSocket;
    return udpSocket;
}

- (NSString *)getAndRemoveThumbnailPath:(int)picID {
    NSString *thumbnailPath = _uncomparedPic[[NSNumber numberWithInt:picID]];
    [_uncomparedPic removeObjectForKey:[NSNumber numberWithInt:picID]];
    return thumbnailPath;
}

#pragma mark - delegate

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"didNotSendDataWithTag: %@", error);
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock
     didReceiveData:(NSData *)data
            withTag:(long)tag
           fromHost:(NSString *)host
               port:(UInt16)port {
        NSLog(@"%@", host);

    static int currentPos = 0;
    NSMutableData *wholeData = [[NSMutableData alloc]init];
    NSString *more = nil;
    NSDate *date = [NSDate date];
    
    //解析data，存储message
    MessageProtocalType type = [_messageProtocal getMessageType:data];
    //    unsigned short userId = type == MessageProtocalTypeACK ? 0 : [_messageProtocal getUserID:data];
    unsigned short userId = 234;
    unsigned char packetID = type == MessageProtocalTypeACK ? 0 : [_messageProtocal getPacketID:data];
    if (type != MessageProtocalTypeACK) {
        [self sendData:[_messageProtocal archiveACK:packetID] toHost:host port:UdpPort withTimeout:-1 tag:0];
        int messageID = userId << 16 | packetID;
        if ([_recentMessageQueue containsObject:[NSNumber numberWithInt:messageID]]) {
            [sock receiveWithTimeout:-1 tag:0];
            return YES;
        }
        [_recentMessageQueue insertObject:[NSNumber numberWithInt:messageID] atIndex:currentPos++ % 20];
    }
    unsigned int wholeLength = type == MessageProtocalTypeACK ? [_messageProtocal getACKID:data] : [_messageProtocal getWholeLength:data];
    int pieceNum = type == MessageProtocalTypeACK ? 0 : [_messageProtocal getPieceNum:data];
    NSData *bodyData = type == MessageProtocalTypeACK ? 0 : [_messageProtocal getBodyData:data];
    
    switch (type) {
        case MessageProtocalTypeMessage:
            [_dataManager saveMessageWithUserID:[NSNumber numberWithUnsignedShort:userId] time:date body:[[NSString alloc]initWithData:bodyData encoding:NSUTF8StringEncoding] isOut:NO];
            break;
        case MessageProtocalTypeRecord:
            _buff[[NSNumber numberWithInt:pieceNum]] = bodyData;
            if (_buff.allKeys.count == wholeLength / PIECELENGTH + 2) {
                float during;
                [_buff[[NSNumber numberWithInt:0]] getBytes:&during range:NSMakeRange(0, sizeof(float))];
                more = [[NSString alloc]initWithFormat:@"%0.2f", during];
                for (int i = 1; i < _buff.allKeys.count; i++) {
                    [wholeData appendData:_buff[[NSNumber numberWithInt:i]]];
                }
                NSString *path = [Tool getFileName:@"receive" extension:@"caf"];
                [wholeData writeToFile:path atomically:YES];
                [_dataManager saveRecordWithUserID:[NSNumber numberWithUnsignedShort:userId] time:date path:path length:more isOut:NO];
                [_buff removeAllObjects];
            }
            break;
        case MessageProtocalTypePicture:
            if (!_tcpSocket.isOn) {
                NSError *err = nil;
                [_tcpSocket disconnect];
                if (![_tcpSocket acceptOnPort:TcpPort error:&err]) {
                    NSLog(@"UdpSocket tcp socket listen failed: %@", err);
                }
                _tcpSocket.isOn = YES;
            }
            _buff[[NSNumber numberWithInt:pieceNum]] = bodyData;
            if (_buff.allKeys.count == wholeLength / PIECELENGTH + 2) {
                int picID;
                [_buff[[NSNumber numberWithInt:0]] getBytes:&picID length:sizeof(char)];
                picID = userId << 16 | picID;
                for (int i = 1; i < _buff.allKeys.count; i++) {
                    [wholeData appendData:_buff[[NSNumber numberWithInt:i]]];
                }
                
                NSString *path = [Tool getFileName:@"thumbnail" extension:@"png"];
                [wholeData writeToFile:path atomically:YES];
                [_buff removeAllObjects];
                _uncomparedPic[[NSNumber numberWithInt:picID]] = path;
            }
            break;
        case MessageProtocalTypeACK:
//            NSLog(@"received ack!");
            [_messageQueueManager messageSended:wholeLength];
            [[NSNotificationCenter defaultCenter]postNotificationName:P2PUdpSocketReceiveACKNotification object:[NSNumber numberWithUnsignedInt:wholeLength]];
            break;
        default: break;
            
    }
    [sock receiveWithTimeout:-1 tag:0];
    return YES;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    
}

@end
