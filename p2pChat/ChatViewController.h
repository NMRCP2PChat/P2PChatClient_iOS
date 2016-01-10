//
//  ChatViewController.h
//  p2pChat
//
//  Created by xiaokun on 16/1/4.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Friend;

@interface ChatViewController : UIViewController

@property (strong, nonatomic, readonly) NSString *ipStr;
@property (strong, nonatomic, readonly) Friend *friendInfo;

@end
