//
//  LastMessage+CoreDataProperties.h
//  p2pChat
//
//  Created by xiaokun on 16/1/4.
//  Copyright © 2016年 xiaokun. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "LastMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface LastMessage (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *body;
@property (nullable, nonatomic, retain) NSNumber *isOut;
@property (nullable, nonatomic, retain) NSDate *time;
@property (nullable, nonatomic, retain) NSNumber *unread;
@property (nullable, nonatomic, retain) NSNumber *userID;
@property (nullable, nonatomic, retain) Friend *friend;

@end

NS_ASSUME_NONNULL_END
