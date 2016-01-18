//
//  PhotoLibraryCenter.h
//  p2pChat
//
//  Created by xiaokun on 16/1/18.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface PhotoLibraryCenter : NSObject

+ (instancetype)shareInstance;

- (void)saveImage:(UIImage *)image;
- (UIImage *)getImageWithPath:(NSString *)path;

@end
