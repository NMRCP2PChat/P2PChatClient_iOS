//
//  MessageProtocal.h
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/16.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (char, MessageProtocalType) {
    MessageProtocalTypeMessage = 0,
    MessageProtocalTypeRecord,
    MessageProtocalTypePicture,
    MessageProtocalTypeFile,
    MessageProtocalTypeAudio,
    MessageProtocalTypeVideo
};

@interface MessageProtocal : NSObject

+ (instancetype)shareInstance;

- (NSData *)archiveText:(NSString *)body;
- (NSData *)archiveRecord:(NSString *)path;

- (unsigned short)getUserID:(NSData *)data;
- (char)getMessageType:(NSData *)data;
- (NSData *)getBodyData:(NSData *)data;

@end
