//
//  MessageCell.h
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/18.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageCell : UITableViewCell

- (void)setPhotoPath:(NSString *)path time:(NSDate *)time body:(NSString *)body more:(NSString *)more;
- (void)setPhotoPath:(NSString *)photoPath bodyPath:(NSString *)thumbnailPath;

@end
