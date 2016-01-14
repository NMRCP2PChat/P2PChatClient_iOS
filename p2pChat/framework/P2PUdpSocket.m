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

@property (strong, nonatomic) NSMutableArray *buffArr;
@property (strong, nonatomic) NSMutableArray *recentMessageQueue;
@property (strong, nonatomic) NSMutableDictionary<NSNumber *, NSString *> *uncomparedPic;

@end

@implementation P2PUdpSocket

- (id)init {
    self = [super initWithDelegate:self];
    NSError *err = nil;
    if (![self bindToPort:UdpPort error:&err]) {
        NSLog(@"p2p udp socket bind port failed: %@", err);
    }
    [self receiveWithTimeout:-1 tag:0];
    _messageProtocal = [MessageProtocal shareInstance];
    _dataManager = [DataManager shareManager];
    _buffArr = [[NSMutableArray alloc]initWithCapacity:15];
    _recentMessageQueue = [[NSMutableArray alloc]initWithCapacity:50];
    _uncomparedPic = [[NSMutableDictionary alloc]init];
    _messageQueueManager = [MessageQueueManager shareInstance];
    return self;
}

+ (instancetype)shareInstance {
    P2PUdpSocket *udpSocket = nil;
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    udpSocket = delegate.udpSocket;
    return udpSocket;
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
    unsigned int wholeLength = type == MessageProtocalTypeACK ? 0 : [_messageProtocal getWholeLength:data];
    int pieceNum = type == MessageProtocalTypeACK ? 0 : [_messageProtocal getPieceNum:data];
    NSData *bodyData = type == MessageProtocalTypeACK ? 0 : [_messageProtocal getBodyData:data];
    
    switch (type) {
        case MessageProtocalTypeMessage:
            [_dataManager saveMessageWithUserID:[NSNumber numberWithUnsignedShort:userId] time:date body:[[NSString alloc]initWithData:bodyData encoding:NSUTF8StringEncoding] isOut:NO];
            break;
        case MessageProtocalTypeRecord:
            _buffArr[pieceNum] = bodyData;
            if ([_buffArr count] == wholeLength / PIECELENGTH + 2) {
                float during;
                [_buffArr[0] getBytes:&during range:NSMakeRange(0, sizeof(float))];
                more = [[NSString alloc]initWithFormat:@"%0.2f", during];
                for (int i = 1; i < _buffArr.count; i++) {
                    [wholeData appendData:_buffArr[i]];
                }
                NSString *path = [Tool getFileName:@"receive" extension:@"caf"];
                [wholeData writeToFile:path atomically:YES];
                [_dataManager saveRecordWithUserID:[NSNumber numberWithUnsignedShort:userId] time:date path:path length:more isOut:NO];
                [_buffArr removeObjectsAtIndexes:[[NSIndexSet alloc]initWithIndexesInRange:NSMakeRange(0, _buffArr.count)]];
            }
            break;
        case MessageProtocalTypePicture:
            _buffArr[pieceNum] = bodyData;
            if (_buffArr.count == wholeLength / PIECELENGTH + 2) {
                NSLog(@"1");
                P2PTcpSocket *tcpSocket = [P2PTcpSocket shareInstance];
                NSError *err = nil;
                if (![tcpSocket acceptOnPort:TcpPort error:&err]) {
                    NSLog(@"UdpSocket tcp socket listen failed: %@", err);
                }
                NSLog(@"2");
                int picID;
                [_buffArr[0] getBytes:&picID length:sizeof(char)];
                picID = userId << 16 | picID;
                for (int i = 1; i < _buffArr.count; i++) {
                    [wholeData appendData:_buffArr[i]];
                }
                NSLog(@"3");
                NSString *path = [Tool getFileName:@"thumbnail" extension:@"png"];
                [wholeData writeToFile:path atomically:YES];
                [_dataManager savePhotoWithUserID:[NSNumber numberWithUnsignedShort:userId] time:date path:nil thumbnail:path isOut:NO];
                NSLog(@"4");
                [_buffArr removeObjectsAtIndexes:[[NSIndexSet alloc]initWithIndexesInRange:NSMakeRange(0, _buffArr.count)]];
                _uncomparedPic[[NSNumber numberWithInt:picID]] = path;
            }
            break;
        case MessageProtocalTypeACK:
//            NSLog(@"received ack!");
            [_messageQueueManager messageSended:[_messageProtocal getACKID:data]];
            break;
        default: break;
            
    }
    [sock receiveWithTimeout:-1 tag:0];
    return YES;
}
@end
