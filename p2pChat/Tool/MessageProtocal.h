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
    MessageProtocalTypeVideo,
    MessageProtocalTypeACK
};

@interface MessageProtocal : NSObject

+ (instancetype)shareInstance;

- (NSData *)archiveACK:(unsigned char)packetID;

- (NSData *)archiveText:(NSString *)body;
- (NSArray *)archiveRecord:(NSString *)path during:(NSNumber *)during;

- (int)getPacketID:(NSData *)data;
- (unsigned short)getUserID:(NSData *)data;
- (char)getMessageType:(NSData *)data;
- (int)getPieceNum:(NSData *)data;
- (unsigned int)getWholeLength:(NSData *)data;
- (NSData *)getBodyData:(NSData *)data;
- (unsigned char)getACKID:(NSData *)data;

@end
