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

+(instancetype)shareInstance {
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    MessageProtocal *messageProtocal = delegate.messageProtocal;
    return messageProtocal;
}

- (NSData *)archiveMessageWithType:(char)type length:(unsigned short)length body:(NSData *)body {
    NSMutableData *data = [[NSMutableData alloc]init];
    NSNumber *userIDInteger = [[NSUserDefaults standardUserDefaults] objectForKey:@"userID"];
    unsigned short userID = [userIDInteger unsignedShortValue];
    [data appendBytes:&userID length:sizeof(unsigned short)];
    [data appendBytes:&type length:sizeof(char)];
    [data appendBytes:&length length:sizeof(unsigned short)];
    [data appendBytes:body.bytes length:body.length];
    return data;
}

- (NSData *)archiveText:(NSString *)bodyStr {
    NSData *strData = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
    return [self archiveMessageWithType:2 length:strData.length body:strData];
}

- (NSArray *)archiveRecord:(NSString *)path during:(NSNumber *)during{
    NSData *recordData = [NSData dataWithContentsOfFile:path];
    long length = recordData.length;
    int piece = recordData.length / PIECELENGTH;
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    float time = [during floatValue];
    
    NSMutableData *infoData = [[NSMutableData alloc]init];
    [infoData appendBytes:&time length:sizeof(float)];
    [infoData appendBytes:&length length:sizeof(long)];
    [arr addObject:[self archiveMessageWithType:MessageProtocalTypeRecord << 4 length:sizeof(infoData) body:infoData]];
    
    for (int i = 0; i < piece; i++) {
        [arr addObject:[self archiveMessageWithType:MessageProtocalTypeRecord << 4 | (char)(i + 1) length:PIECELENGTH body:[recordData subdataWithRange:NSMakeRange(i * PIECELENGTH, (i + 1) * PIECELENGTH)]]];
    }
    [arr addObject:[self archiveMessageWithType:MessageProtocalTypeRecord << 4 | (char)piece length:recordData.length - piece * PIECELENGTH body:[recordData subdataWithRange:NSMakeRange(piece * PIECELENGTH, recordData.length - piece * PIECELENGTH)]]];
    
    return arr;
}

- (unsigned short)getUserID:(NSData *)data {
    unsigned short userID;
    [data getBytes:&userID range:NSMakeRange(0, sizeof(unsigned short))];
    
    return userID;
}

- (char)getMessageType:(NSData *)data {
    char type;
    [data getBytes:&type range:NSMakeRange(sizeof(unsigned short), sizeof(char))];
    
    return type >> 4;
}

- (int)getPieceNum:(NSData *)data {
    char order;
    [data getBytes:&order range:NSMakeRange(sizeof(unsigned short), sizeof(char))];
    
    return order & 15;
}

- (NSData *)getBodyData:(NSData *)data {
    unsigned short len;
    [data getBytes:&len range:NSMakeRange(sizeof(char) + sizeof(unsigned short), sizeof(unsigned short))];
    NSData *strData = [data subdataWithRange:NSMakeRange(sizeof(char) + sizeof(short) + sizeof(unsigned short), len)];

    return strData;
}

@end
