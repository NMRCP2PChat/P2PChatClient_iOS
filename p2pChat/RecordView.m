//
//  RecordView.m
//  p2pChat
//
//  Created by xiaokun on 16/1/10.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "RecordView.h"
#import "AudioCenter.h"
#import "Tool.h"
#import "DataManager.h"
#import "MessageProtocal.h"
#import "MessageQueueManager.h"
#import "P2PUdpSocket.h"

@interface RecordView () {
    AudioCenter *_audioCenter;
}
@end

@implementation RecordView

- (IBAction)startRecord:(id)sender {
    NSString *path = [Tool getFileName:@"send" extension:@"caf"];
    _audioCenter = [AudioCenter shareInstance];
    _audioCenter.path = path;
    [_audioCenter startRecord];
}

- (IBAction)stopRecord:(id)sender {
    CGFloat during = [[AudioCenter shareInstance] stopRecord];
    P2PUdpSocket *udpSocket = [P2PUdpSocket shareInstance];
    [[DataManager shareManager]saveRecordWithUserID:_userID time:[NSDate date] path:_audioCenter.path length:[NSString stringWithFormat:@"%0.2f", during] isOut:YES];
    NSArray *recordArr = [[MessageProtocal shareInstance]archiveRecord:_audioCenter.path during:[NSNumber numberWithFloat:during]];
    for (NSData *pieceData in recordArr) {
        if (![udpSocket sendData:pieceData toHost:_ipStr port:UdpPort withTimeout:-1 tag:1]) {
            NSLog(@"RecordView send record failed");
        } else {
            [[MessageQueueManager shareInstance] addSendingMessageIP:_ipStr packetData:pieceData];
        }
    }
}
@end