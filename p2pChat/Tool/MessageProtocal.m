//
//  MessageProtocal.m
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/16.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import "MessageProtocal.h"
#import "AppDelegate.h"

#define PIECELENGTH 9000

@implementation MessageProtocal

static unsigned char packetID = 0;

+(instancetype)shareInstance {
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    MessageProtocal *messageProtocal = delegate.messageProtocal;
    return messageProtocal;
}

- (NSData *)archiveMessageWithType:(char)type wholeLength:(int)wholeLength length:(unsigned short)length body:(NSData *)body {
    packetID = (packetID + 1) % 256;
    NSMutableData *data = [[NSMutableData alloc]init];
    NSNumber *userIDInteger = [[NSUserDefaults standardUserDefaults] objectForKey:@"userID"];
    unsigned short userID = [userIDInteger unsignedShortValue];
    [data appendBytes:&packetID length:sizeof(unsigned char)];
    [data appendBytes:&type length:sizeof(char)];
    [data appendBytes:&userID length:sizeof(unsigned short)];
    [data appendBytes:&wholeLength length:sizeof(int)];
    [data appendBytes:&length length:sizeof(unsigned short)];
    [data appendBytes:body.bytes length:body.length];
    return data;
}

- (NSData *)archiveACK:(unsigned char)receivePacketID {
    NSMutableData *data = [[NSMutableData alloc]init];
    unsigned char packetID = 0;
    char type = MessageProtocalTypeACK << 4;
    [data appendBytes:&packetID length:sizeof(unsigned char)];
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
    long length = recordData.length;
    int piece = length / PIECELENGTH;
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    float time = [during floatValue];
    
    NSMutableData *infoData = [[NSMutableData alloc]init];
    [infoData appendBytes:&time length:sizeof(float)];
    [arr addObject:[self archiveMessageWithType:MessageProtocalTypeRecord << 4 wholeLength:length length:infoData.length body:infoData]];
    
    for (int i = 0; i < piece; i++) {
        [arr addObject:[self archiveMessageWithType:MessageProtocalTypeRecord << 4 | (char)(i + 1) wholeLength:length length:PIECELENGTH body:[recordData subdataWithRange:NSMakeRange(i * PIECELENGTH, (i + 1) * PIECELENGTH)]]];
    }
    [arr addObject:[self archiveMessageWithType:MessageProtocalTypeRecord << 4 | (char)(piece + 1) wholeLength:length length:recordData.length - piece * PIECELENGTH body:[recordData subdataWithRange:NSMakeRange(piece * PIECELENGTH, recordData.length - piece * PIECELENGTH)]]];
    
    return arr;
}

- (int)getPacketID:(NSData *)data {
    int packetID;
    [data getBytes:&packetID range:NSMakeRange(0, sizeof(unsigned char))];
    
    return packetID;
}

- (char)getMessageType:(NSData *)data {
    char type;
    [data getBytes:&type range:NSMakeRange(sizeof(unsigned char), sizeof(char))];
    
    return type >> 4;
}

- (int)getPieceNum:(NSData *)data {
    char order;
    [data getBytes:&order range:NSMakeRange(sizeof(unsigned char), sizeof(char))];
    
    return order & 15;
}

- (unsigned short)getUserID:(NSData *)data {
    unsigned short userID;
    [data getBytes:&userID range:NSMakeRange(sizeof(unsigned char) + sizeof(char), sizeof(unsigned short))];
    
    return userID;
}

- (unsigned int)getWholeLength:(NSData *)data {
    unsigned int length;
    [data getBytes:&length range:NSMakeRange(sizeof(unsigned char)  + sizeof(unsigned short) + sizeof(char), sizeof(unsigned int))];
    
    return length;
}

- (NSData *)getBodyData:(NSData *)data {
    unsigned short len;
    [data getBytes:&len range:NSMakeRange(sizeof(unsigned char) + sizeof(char) + sizeof(unsigned short) + sizeof(unsigned int), sizeof(unsigned short))];
    NSData *strData = [data subdataWithRange:NSMakeRange(sizeof(unsigned char) + sizeof(char) + sizeof(unsigned short) + sizeof(unsigned int) + sizeof(unsigned short), len)];

    return strData;
}

- (unsigned char)getACKID:(NSData *)data {
    unsigned char ackID;
    [data getBytes:&ackID range:NSMakeRange(sizeof(unsigned char) + sizeof(char), sizeof(unsigned char))];
    return ackID;
}

@end
