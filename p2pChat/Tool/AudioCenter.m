//
//  Recorder.m
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/20.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import "AudioCenter.h"
#import "AppDelegate.h"

@interface AudioCenter ()

@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) AVAudioPlayer *player;

@end

@implementation AudioCenter

+ (instancetype)shareInstance {
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    AudioCenter *center = delegate.audioCenter;
    return center;
}

- (void)startRecord {
    NSLog(@"AudioCenter: record start");
    NSDictionary *settings = @{AVFormatIDKey : @(kAudioFormatiLBC), AVSampleRateKey : @(8000), AVChannelLayoutKey : @(1), AVLinearPCMBitDepthKey : @(8), AVLinearPCMIsFloatKey : @(YES)};
    NSError *err = nil;
    _recorder = [[AVAudioRecorder alloc]initWithURL:[NSURL fileURLWithPath:_path] settings:settings error:&err];
    if (err) {
        NSLog(@"AudioCenter record error: %@", err);
    }
    [_recorder record];
}

- (float)stopRecord {
    NSTimeInterval during = _recorder.currentTime;
    [_recorder stop];
//    [self startPlay];
    return (float)during;
}

- (void)startPlay {
    NSError *err = nil;
    _player = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:_path] error:&err];
    if (err) {
        NSLog(@"AudioCenter play error: %@", err);
    }
    [_player play];
}
@end
