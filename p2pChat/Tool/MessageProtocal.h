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

#define PIECELENGTH 9000

@interface MessageProtocal : NSObject

+ (instancetype)shareInstance;

@end

@interface MessageProtocal (Archive)

- (NSData *)archiveACK:(unsigned char)packetID;
- (NSData *)archiveText:(NSString *)body;
- (NSArray *)archiveRecord:(NSString *)path during:(NSNumber *)during;
- (NSArray *)archiveThumbnail:(NSString *)path picID:(char)picID;

@end

@interface MessageProtocal (Unarchive)

- (int)getPacketID:(NSData *)data;// 包id
- (unsigned short)getUserID:(NSData *)data;
- (char)getMessageType:(NSData *)data;
- (int)getPieceNum:(NSData *)data;// 包内分片序号
- (unsigned int)getWholeLength:(NSData *)data;// 包总长 （区别分片总长）
- (NSData *)getBodyData:(NSData *)data;
- (unsigned char)getACKID:(NSData *)data;

@end
