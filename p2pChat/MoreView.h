//
//  MoreView.h
//  p2pChat
//
//  Created by xiaokun on 16/1/10.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MoreView : UIView <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) NSNumber *userID;
@property (strong, nonatomic) NSString *ipStr;

@end
