//
//  DataManager.m
//  ZXKChat_2
//
//  Created by xiaokun on 15/12/16.
//  Copyright © 2015年 xiaokun. All rights reserved.
//

#import "DataManager.h"
#import "AppDelegate.h"
#import "Friend.h"
#import "Message.h"
#import "LastMessage.h"

@interface DataManager ()

@end

@implementation DataManager

+ (instancetype)shareManager {
    DataManager *manager = nil;
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    manager = delegate.dataManager;
    manager.context = delegate.managedObjectContext;

    return manager;
}

- (NSFetchedResultsController *)fetchWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate sortKey:(NSString *)key ascending:(BOOL)ascending error:(NSError **)error {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:name];
    request.predicate = predicate;
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:key ascending:ascending];
    request.sortDescriptors = @[sort];
    NSFetchedResultsController *resultController = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:_context sectionNameKeyPath:nil cacheName:nil];
    [resultController performFetch:error];

    return resultController;
}

- (void)saveMessageWithUserID:(NSNumber *)userID time:(NSDate *)time type:(NSNumber *)type body:(NSString *)body more:(NSString *)more error:(NSError **)err isOut:(BOOL)isOut {
    Message *message = [NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:_context];
    message.userID = userID;
    message.time = time;
    message.type = type;
    message.body = body;
    message.more = more;
    message.isOut = [NSNumber numberWithBool:isOut];
    [_context save:err];
}

#pragma mark - friend
- (NSFetchedResultsController *)getFriends {
    NSError *err = nil;
    NSFetchedResultsController *resultsController = [self fetchWithEntityName:@"Friend" predicate:nil sortKey:@"userID" ascending:YES error:&err];
    if (err) {
        NSLog(@"DataManager get friends failed: %@", err);
    }
    
    return resultsController;
}

- (void)saveFriendID:(NSNumber *)userID name:(NSString *)name photoPath:(NSString *)path {
    Friend *friend = (Friend *)[NSEntityDescription insertNewObjectForEntityForName:@"Friend" inManagedObjectContext:_context];
    friend.userID = userID;
    friend.nickName = name;
    friend.photoPath = path;
    NSError *err = nil;
    [_context save:&err];
    if (err) {
        NSLog(@"DataManager save friend failed: %@", err);
    } else {
        NSLog(@"save friend success");
    }
}

- (void)deleteFriendID:(NSNumber *)userID {
    NSFetchRequest *requset = [NSFetchRequest fetchRequestWithEntityName:@"Friend"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID = %@", userID];
    requset.predicate = predicate;
    NSError *err1 = nil,*err2 = nil;
    NSArray *arr = [_context executeFetchRequest:requset error:&err1];
    if (err1) {
        NSLog(@"DataManager select failed: %@", err1);
    }
    
    NSManagedObject *obj = arr[0];
    [_context deleteObject:obj];
    [_context save:&err2];
    if (err2) {
        NSLog(@"DataManager delete friend failed: %@", err2);
    }
}

- (NSArray *)getFriendByUserID:(NSNumber *)userID {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Friend"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID = %@", userID];
    request.predicate = predicate;
    NSError *err = nil;
    NSArray *result = [_context executeFetchRequest:request error:&err];
    return result;
}

#pragma mark - message
- (NSFetchedResultsController *)getMessageByUserID:(NSNumber *)userID {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID = %@", userID];
    NSError *err = nil;
    NSFetchedResultsController *resultController = [self fetchWithEntityName:@"Message" predicate:predicate sortKey:@"time" ascending:YES error:&err];
    if (err) {
        NSLog(@"DataManager fetch message failed: %@", err);
    }
    
    return resultController;
}

- (void)saveMessageWithUserID:(NSNumber *)userID time:(NSDate *)time body:(NSString *)body isOut:(BOOL)isOut{
    NSError *err = nil;
    [self saveMessageWithUserID:userID time:time type:[NSNumber numberWithChar:0] body:body more:nil error:&err isOut:isOut];
    if (err) {
        NSLog(@"DataManager save message failed: %@", err);
    }
}

- (void)saveRecordWithUserID:(NSNumber *)userID time:(NSDate *)time path:(NSString *)path length:(NSString *)length isOut:(BOOL)isOut {
    NSError *err = nil;
    [self saveMessageWithUserID:userID time:time type:[NSNumber numberWithChar:1] body:path more:length error:&err isOut:isOut];
    if (err) {
        NSLog(@"DataManager save message failed: %@", err);
    }
}

- (void)savePhotoWithUserID:(NSNumber *)userID time:(NSDate *)time path:(NSString *)path thumbnail:(NSString *)thumbnailPath isOut:(BOOL)isOut{
    NSError *err = nil;
    [self saveMessageWithUserID:userID time:time type:[NSNumber numberWithChar:2] body:path more:thumbnailPath error:&err isOut:isOut];
    if (err) {
        NSLog(@"DataManager save message failed: %@", err);
    }
}

- (void)saveFileWithUserID:(NSNumber *)userID time:(NSDate *)time path:(NSString *)path fileName:(NSString *)name isOut:(BOOL)isOut {
    NSError *err = nil;
    [self saveMessageWithUserID:userID time:time type:[NSNumber numberWithChar:3] body:path more:name error:&err isOut:isOut];
    if (err) {
        NSLog(@"DataManager save message failed: %@", err);
    }
}

#pragma mark - last message
- (NSFetchedResultsController *)getRecent {
    NSError *err = nil;
    NSFetchedResultsController *resultController = [self fetchWithEntityName:@"LastMessage" predicate:nil sortKey:@"time" ascending:NO error:&err];
    if (err) {
        NSLog(@"DataManager fetch recent failed: %@", err);
    }
    return resultController;
}

- (void)addRecentUserID:(NSNumber *)userID time:(NSDate *)time flag:(NSNumber *)flag body:(NSString *)body isOut:(BOOL)isOut {
    LastMessage *lastMessage = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID = %@", userID];
    NSError *err = nil;
    NSFetchedResultsController *resultController = [self fetchWithEntityName:@"LastMessage" predicate:predicate sortKey:nil ascending:YES error:&err];
    if (err) {
        NSLog(@"DataManager fetch recent failed: %@", err);
    }
    if ([resultController fetchedObjects].count == 0) {
        lastMessage = [NSEntityDescription insertNewObjectForEntityForName:@"LastMessage" inManagedObjectContext:_context];
        lastMessage.userID = userID;
    } else {
        lastMessage = [resultController fetchedObjects].firstObject;
    }
    lastMessage.time = time;
    lastMessage.unread = [NSNumber numberWithUnsignedShort:1];
    lastMessage.body = body;
    lastMessage.isOut = [NSNumber numberWithBool:isOut];
    NSError *err2 = nil;
    [_context save:&err2];
    if (err2) {
        NSLog(@"DataManager save recent failed: %@", err2);
    }
}

- (void)updateUserID:(NSNumber *)userID {//已读
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID = %@", userID];
    NSError *err = nil;
    NSFetchedResultsController *resultController = [self fetchWithEntityName:@"LastMessage" predicate:predicate sortKey:nil ascending:YES error:&err];
    if (err) {
        NSLog(@"DataManager fetch recent failed: %@", err);
    }
    LastMessage *lastMessage = [resultController fetchedObjects].firstObject;
    lastMessage.unread = [NSNumber numberWithUnsignedShort:0];
    NSError *err2 = nil;
    [_context save:&err2];
    if (err2) {
        NSLog(@"DataManager save flag failed: %@", err2);
    }
}

- (void)deleteRecentUserID:(NSNumber *)userID {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID = %@", userID];
    NSError *err = nil;
    NSFetchedResultsController *resultController = [self fetchWithEntityName:@"LastMessage" predicate:predicate sortKey:nil ascending:YES error:&err];
    if (err) {
        NSLog(@"DataManager fetch recent failed: %@", err);
    }
    NSManagedObject *obj = [resultController fetchedObjects].firstObject;
    [_context deleteObject:obj];
    NSError *err2 = nil;
    [_context save:&err2];
    if (err2) {
        NSLog(@"DataManager delete recent failed: %@", err2);
    }
}
@end
