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
@class P2PUdpSocket;
@class P2PTcpSocket;
@class AudioCenter;
@class MessageProtocal;
@class DataManager;
@class MessageQueueManager;
@class MyXMPP;

#define UdpPort 1234
#define TcpPort 2345

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (readonly, strong, nonatomic) P2PUdpSocket *udpSocket;
@property (readonly, strong, nonatomic) P2PTcpSocket *tcpSocket;
@property (readonly, strong, nonatomic) DataManager *dataManager;
@property (readonly, strong, nonatomic) AudioCenter *audioCenter;
@property (readonly, strong, nonatomic) MessageProtocal *messageProtocal;
@property (readonly, strong, nonatomic) MessageQueueManager *messageQueueManager;
@property (readonly, strong, nonatomic) MyXMPP *myXMPP;

@end

