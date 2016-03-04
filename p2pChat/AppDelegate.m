//
//  AppDelegate.m
//  p2pChat
//
//  Created by xiaokun on 16/1/4.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "AppDelegate.h"
#import "DataManager.h"
#import "AudioCenter.h"
#import "MessageProtocal.h"
#import "Tool.h"
#import "MessageQueueManager.h"
#import "P2PUdpSocket.h"
#import "P2PTcpSocket.h"
#import "AsyncSocket.h"
#import "MyXMPP.h"

@interface AppDelegate ()

@property (strong, nonatomic) NSTimer *scanMessageQueueTimer;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   
    _audioCenter = [[AudioCenter alloc]init];
    _messageProtocal = [[MessageProtocal alloc]init];
    _dataManager = [[DataManager alloc]init];
    _dataManager.context = _managedObjectContext;
    _myXMPP = [[MyXMPP alloc]init];
    
    _tcpSocket = [[P2PTcpSocket alloc]init];
    _udpSocket = [[P2PUdpSocket alloc]init];
    [_udpSocket receiveWithTimeout:-1 tag:0];
    
    _scanMessageQueueTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(scanMessageQueue) userInfo:nil repeats:YES];
    [_scanMessageQueueTimer setFireDate:[NSDate distantFuture]];
    _messageQueueManager = [[MessageQueueManager alloc]initWithSocket:_udpSocket timer:_scanMessageQueueTimer];
    [_udpSocket setMessageQueueManager:_messageQueueManager];
    
    if ([[NSUserDefaults standardUserDefaults]stringForKey:@"name"] == nil) {
        [[NSUserDefaults standardUserDefaults]setObject:@"xiaoming" forKey:@"name"];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithUnsignedShort:121] forKey:@"id"];
    }
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:@"photoPath"];
    NSString *path = [[NSBundle mainBundle]pathForResource:@"1" ofType:@"png"];
    [[NSUserDefaults standardUserDefaults]setObject:path forKey:@"photoPath"];
    
    NSError *audioSessionError = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&audioSessionError];
    if (audioSessionError) {
        NSLog(@"audioSession failed");
    }

    return YES;
}

- (void)scanMessageQueue {
    [_messageQueueManager sendAgain];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "zxkleetcode.p2pChat" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"p2pChat" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"p2pChat.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
