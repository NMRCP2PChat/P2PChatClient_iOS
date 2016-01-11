//
//  MessageCell.m
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/18.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import "MessageCell.h"
#import "Tool.h"

@interface MessageCell ()

@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;
@property (weak, nonatomic) IBOutlet UILabel *moreLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bodyImage;

@end

@implementation MessageCell

- (void)setPhotoPath:(NSString *)path time:(NSDate *)time body:(NSString *)body more:(NSString *)more {
    [_photoImageView setImage:[UIImage imageWithContentsOfFile:path]];
    [_timeLabel setText:[Tool stringFromDate:time]];
    [_moreLabel setText:more];
    if (body != nil) {
        [_bodyLabel setText:body];
    } else {
        [self setDisplayLabel];
    }
}

- (void)setDisplayLabel {
    float during = [_moreLabel.text floatValue];
    CGRect screenFrame = [UIScreen mainScreen].bounds;
    CGRect photoFrame = _photoImageView.frame;
    CGRect frame;
    if (photoFrame.origin.x < screenFrame.size.width / 2) {//friend's
        CGPoint right_bottom = CGPointMake(photoFrame.origin.x + photoFrame.size.width, photoFrame.origin.y + photoFrame.size.height);
        frame = CGRectMake(right_bottom.x + 5, right_bottom.y - 20, 20 * during + 20, 20);
    } else {
        CGPoint left_bottom = CGPointMake(photoFrame.origin.x, photoFrame.origin.y + photoFrame.size.height);
        frame = CGRectMake(left_bottom.x - 25 - 20 * during, left_bottom.y - 20, 20 * during + 20, 20);
    }
    UILabel *label = [[UILabel alloc]initWithFrame:frame];
    label.backgroundColor = [UIColor greenColor];
    [self addSubview:label];
}

- (void)setPhotoPath:(NSString *)photoPath bodyPath:(NSString *)thumbnailPath {
    [_photoImageView setImage:[UIImage imageWithContentsOfFile:photoPath]];
    [_bodyImage setImage:[UIImage imageWithContentsOfFile:thumbnailPath]];
}
@end
