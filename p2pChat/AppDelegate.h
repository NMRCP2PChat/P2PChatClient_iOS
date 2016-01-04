//
//  AppDelegate.h
//  p2pChat
//
//  Created by xiaokun on 16/1/4.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <AVFoundation/AVFoundation.h>
#import "AsyncUdpSocket.h"
@class AudioCenter;
@class MessageProtocal;
@class DataManager;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (strong, nonatomic) AsyncUdpSocket *udpSocket;
@property (strong, nonatomic) DataManager *dataManager;
@property (strong, nonatomic) AudioCenter *audioCenter;
@property (strong, nonatomic) MessageProtocal *messageProtocal;

@end

