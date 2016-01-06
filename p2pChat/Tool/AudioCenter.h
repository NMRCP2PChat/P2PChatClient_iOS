//
//  Recorder.h
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/20.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioCenter : NSObject

@property (strong, nonatomic) NSString *path;

+ (instancetype)shareInstance;

- (void)startRecord;
- (float)stopRecord;

- (void)startPlay;

@end
