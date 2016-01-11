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
#import "AppDelegate.h"

@interface RecordView () {
    AudioCenter *_audioCenter;
}
@end

@implementation RecordView

- (IBAction)startRecord:(id)sender {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    path = [path stringByAppendingPathComponent:[[Tool stringFromDate:[NSDate date]]stringByAppendingPathExtension:@"caf"]];
    _audioCenter = [AudioCenter shareInstance];
    _audioCenter.path = path;
    [_audioCenter startRecord];
}

- (IBAction)stopRecord:(id)sender {
    CGFloat during = [[AudioCenter shareInstance] stopRecord];
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    AsyncUdpSocket *udpSocket = delegate.udpSocket;
    [[DataManager shareManager]saveRecordWithUserID:_userID time:[NSDate date] path:_audioCenter.path length:[NSString stringWithFormat:@"%0.2f", during] isOut:YES];
    NSArray *recordArr = [[MessageProtocal shareInstance]archiveRecord:_audioCenter.path during:[NSNumber numberWithFloat:during]];
    for (NSData *pieceData in recordArr) {
        if (![udpSocket sendData:pieceData toHost:_ipStr port:1234 withTimeout:-1 tag:1]) {
            NSLog(@"RecordView send record failed");
        } else {
            [[MessageQueueManager shareInstance] addSendingMessage:_ipStr packetData:pieceData];
        }
    }
}
@end