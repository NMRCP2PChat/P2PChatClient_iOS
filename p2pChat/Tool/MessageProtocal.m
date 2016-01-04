//
//  MessageProtocal.m
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/16.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import "MessageProtocal.h"
#import "AppDelegate.h"

// 0000 文字 0001 语音 0010 图片 0011 文件 0100 音频请求 0101 视频请求 0000 pc 0001 web 0010 ios 0011 android
// 客户端版本有没有必要？

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

- (NSData *)archiveRecord:(NSString *)path {
    NSData *recordData = [NSData dataWithContentsOfFile:path];
    return [self archiveMessageWithType:18 length:recordData.length body:recordData];
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

- (NSData *)getBodyData:(NSData *)data {
    unsigned short len;
    [data getBytes:&len range:NSMakeRange(sizeof(char) + sizeof(unsigned short), sizeof(unsigned short))];
    NSData *strData = [data subdataWithRange:NSMakeRange(sizeof(char) + sizeof(short) + sizeof(unsigned short), len)];

    return strData;
}

@end
