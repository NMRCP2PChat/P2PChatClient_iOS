//
//  MyFetchedResultsControllerDelegate.h
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/20.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MyFetchedResultsControllerDelegate : NSObject <NSFetchedResultsControllerDelegate>

- (id)initWithTableView:(UITableView *)tableView;

@end
