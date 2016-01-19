//
//  MessageProtocal.m
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/16.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import "MessageProtocal.h"
#import "AppDelegate.h"

@implementation MessageProtocal

static unsigned char packetID = 0;

+(instancetype)shareInstance {
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    MessageProtocal *messageProtocal = delegate.messageProtocal;
    return messageProtocal;
}

- (NSData *)archiveMessageWithType:(char)type wholeLength:(int)wholeLength length:(unsigned short)length body:(NSData *)body {
    packetID++;
    packetID = packetID % 256;
    NSMutableData *data = [[NSMutableData alloc]init];
    NSNumber *userIDInteger = [[NSUserDefaults standardUserDefaults] objectForKey:@"userID"];
    unsigned short userID = [userIDInteger unsignedShortValue];
    
    [data appendBytes:&type length:sizeof(char)];
    [data appendBytes:&userID length:sizeof(unsigned short)];
    [data appendBytes:&packetID length:sizeof(unsigned char)];
    [data appendBytes:&wholeLength length:sizeof(int)];
    [data appendBytes:&length length:sizeof(unsigned short)];
    [data appendBytes:body.bytes length:body.length];
    return data;
}

- (NSData *)archiveACK:(unsigned char)receivePacketID {
    NSMutableData *data = [[NSMutableData alloc]init];
    char type = MessageProtocalTypeACK << 4;
    [data appendBytes:&type length:sizeof(char)];
    [data appendBytes:&receivePacketID length:sizeof(unsigned char)];
    return data;
}

- (NSData *)archiveText:(NSString *)bodyStr {
    NSData *strData = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
    return [self archiveMessageWithType:MessageProtocalTypeMessage << 4 wholeLength:0 length:strData.length body:strData];
}

- (NSArray *)archiveRecord:(NSString *)path during:(NSNumber *)during{
    NSData *recordData = [NSData dataWithContentsOfFile:path];
    int length = (int)recordData.length;
    int piece = length / PIECELENGTH;
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    float time = [during floatValue];
    
    NSMutableData *infoData = [[NSMutableData alloc]initWithBytes:&time length:sizeof(float)];
    [arr addObject:[self archiveMessageWithType:MessageProtocalTypeRecord << 4 wholeLength:length length:infoData.length body:infoData]];
    
    for (int i = 0; i < piece; i++) {
        [arr addObject:[self archiveMessageWithType:MessageProtocalTypeRecord << 4 | (char)(i + 1) wholeLength:length length:PIECELENGTH body:[recordData subdataWithRange:NSMakeRange(i * PIECELENGTH, PIECELENGTH)]]];
    }
    [arr addObject:[self archiveMessageWithType:MessageProtocalTypeRecord << 4 | (char)(piece + 1) wholeLength:length length:length - piece * PIECELENGTH body:[recordData subdataWithRange:NSMakeRange(piece * PIECELENGTH, length - piece * PIECELENGTH)]]];
    
    return arr;
}

- (NSArray *)archiveThumbnail:(NSString *)path picID:(char)picID {
    NSData *thumbnailData = [NSData dataWithContentsOfFile:path];
    int length = (int)thumbnailData.length;
    int piece = length / PIECELENGTH;
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    NSMutableData *picIDData = [[NSMutableData alloc]initWithBytes:&picID length:sizeof(unsigned char)];

    [arr addObject:[self archiveMessageWithType:MessageProtocalTypePicture << 4 wholeLength:length length:picIDData.length body:picIDData]];
    for (int i = 0; i < piece; i++) {
        [arr addObject:[self archiveMessageWithType:MessageProtocalTypePicture << 4 | (char)(i + 1) wholeLength:length length:PIECELENGTH body:[thumbnailData subdataWithRange:NSMakeRange(i * PIECELENGTH, PIECELENGTH)]]];
    }
    [arr addObject:[self archiveMessageWithType:MessageProtocalTypePicture << 4 | (char)(piece + 1) wholeLength:length length:length - piece * PIECELENGTH body:[thumbnailData subdataWithRange:NSMakeRange((piece - 1) * PIECELENGTH, length - piece * PIECELENGTH)]]];
    return arr;
}

- (char)getMessageType:(NSData *)data {
    char type;
    [data getBytes:&type range:NSMakeRange(0, sizeof(char))];
    
    return type >> 4;
}

- (int)getPieceNum:(NSData *)data {
    char order;
    [data getBytes:&order range:NSMakeRange(0, sizeof(char))];
    
    return order & 15;
}

- (unsigned short)getUserID:(NSData *)data {
    unsigned short userID;
    [data getBytes:&userID range:NSMakeRange(sizeof(unsigned char), sizeof(unsigned short))];
    
    return userID;
}

- (int)getPacketID:(NSData *)data {
    int packetID;
    [data getBytes:&packetID range:NSMakeRange(sizeof(char) + sizeof(unsigned short), sizeof(unsigned char))];
    
    return packetID;
}

- (unsigned int)getWholeLength:(NSData *)data {
    unsigned int length;
    [data getBytes:&length range:NSMakeRange(sizeof(char) * 2 + sizeof(unsigned short), sizeof(unsigned int))];
    
    return length;
}

- (NSData *)getBodyData:(NSData *)data {
    unsigned short len;
    [data getBytes:&len range:NSMakeRange(sizeof(char) *2 + sizeof(unsigned short) + sizeof(unsigned int), sizeof(unsigned short))];
    NSData *strData = [data subdataWithRange:NSMakeRange(sizeof(char) * 2 + sizeof(unsigned short) * 2 + sizeof(unsigned int), len)];

    return strData;
}

- (unsigned char)getACKID:(NSData *)data {
    unsigned char ackID;
    [data getBytes:&ackID range:NSMakeRange(sizeof(char), sizeof(unsigned char))];
    
    return ackID;
}

@end
