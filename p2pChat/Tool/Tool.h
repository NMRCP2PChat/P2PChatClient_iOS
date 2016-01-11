//
//  Tool.h
//  ZXKChat_1
//
//  Created by xiaokun on 15/12/16.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tool : NSObject

+ (NSString *)getLocalIp;
+ (NSString *)stringFromDate:(NSDate *)date;
+ (NSString *)getFileName:(NSString *)info extension:(NSString *)extension;

@end
