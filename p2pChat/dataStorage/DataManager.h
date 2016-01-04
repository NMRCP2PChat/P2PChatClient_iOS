//
//  DataManager.h
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/16.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DataManager : NSObject

@property (strong, nonatomic) NSManagedObjectContext *context;

+ (instancetype)shareManager;

// 对用户的操作
- (NSFetchedResultsController *)getFriends;
- (void)saveFriendID:(NSNumber *)userID name:(NSString *)name photoPath:(NSString *)path;
- (void)deleteFriendID:(NSNumber *)userID;
- (NSArray *)getFriendByUserID:(NSNumber *)userID;

// 对message的操作
- (NSFetchedResultsController *)getMessageByUserID:(NSNumber *)userID;
- (void)saveMessageWithUserID:(NSNumber *)userID time:(NSDate *)time body:(NSString *)body isOut:(BOOL)isOut;
- (void)saveRecordWithUserID:(NSNumber *)userID time:(NSDate *)time path:(NSString *)path length:(NSString *)length isOut:(BOOL)isOut;
- (void)savePhotoWithUserID:(NSNumber *)userID time:(NSDate *)time path:(NSString *)path thumbnail:(NSString *)thumbnailPath isOut:(BOOL)isOut;
- (void)saveFileWithUserID:(NSNumber *)userID time:(NSDate *)time path:(NSString *)path fileName:(NSString *)name isOut:(BOOL)isOut;

// 对last message的操作
- (NSFetchedResultsController *)getRecent;
- (void)addRecentUserID:(NSNumber *)userID time:(NSDate *)time flag:(NSNumber *)flag body:(NSString *)body isOut:(BOOL)isOut;
- (void)updateUserID:(NSNumber *)userID;//已读
- (void)deleteRecentUserID:(NSNumber *)userID;

@end
