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

@interface AppDelegate () <AsyncUdpSocketDelegate>

@property (strong, nonatomic) NSMutableArray *buffArr;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _udpSocket = [[AsyncUdpSocket alloc]initWithDelegate:self];
    [_udpSocket bindToPort:1234 error:nil];
    [_udpSocket setMaxReceiveBufferSize:65535];
    [_udpSocket receiveWithTimeout:-1 tag:0];
   
    _audioCenter = [[AudioCenter alloc]init];
    _messageProtocal = [[MessageProtocal alloc]init];
    _dataManager = [[DataManager alloc]init];
    
    _buffArr = [[NSMutableArray alloc]initWithCapacity:15];
    
    _messageQueueManager = [[MessageQueueManager alloc]initWithSocket:_udpSocket];
    NSTimeInterval period = 1.0;
    dispatch_queue_t messageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, messageQueue);
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_timer, ^{
        [_messageQueueManager sendAgain];
    });
    dispatch_resume(_timer);
    
    //
    //    NSString *path2 = [[NSBundle mainBundle]pathForResource:@"0" ofType:@"png"];
    //    [_dataManager saveFriendID:[NSNumber numberWithInt:123] name:@"xiaohong" photoPath:path2];
    //
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

#pragma mark - async udp socket delegate

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"didNotSendDataWithTag: %@", error);
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock
     didReceiveData:(NSData *)data
            withTag:(long)tag
           fromHost:(NSString *)host
               port:(UInt16)port {
    NSLog(@"%@", host);
    if (_dataManager.context == nil) {
        _dataManager.context = _managedObjectContext;
    }
    
    NSMutableData *wholeData = [[NSMutableData alloc]init];
    NSString *more = nil;
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSDate *date = [NSDate date];
    //解析data，存储message
    unsigned char packetID = [_messageProtocal getPacketID:data];
    MessageProtocalType type = [_messageProtocal getMessageType:data];
    unsigned int wholeLength = type == MessageProtocalTypeACK ? 0 : [_messageProtocal getWholeLength:data];
    int pieceNum = type == MessageProtocalTypeACK ? 0 : [_messageProtocal getPieceNum:data];
//    unsigned short userId = [_messageProtocal getUserID:data];
    unsigned short userId = 234;
    NSData *bodyData = type == MessageProtocalTypeACK ? 0 : [_messageProtocal getBodyData:data];
    
    if (type != MessageProtocalTypeACK) {
        [_udpSocket sendData:[_messageProtocal archiveACK:packetID] toHost:host port:1234 withTimeout:-1 tag:0];
//        NSLog(@"send ack");
    }
    
    switch (type) {
        case MessageProtocalTypeMessage:
            [_dataManager saveMessageWithUserID:[NSNumber numberWithUnsignedShort:userId] time:date body:[[NSString alloc]initWithData:bodyData encoding:NSUTF8StringEncoding] isOut:NO];
            break;
        case MessageProtocalTypeRecord:
            _buffArr[pieceNum] = bodyData;
            if ([_buffArr count] == wholeLength / 9000 + 2) {
                float during;
                [_buffArr[0] getBytes:&during range:NSMakeRange(0, sizeof(float))];
                more = [[NSString alloc]initWithFormat:@"%0.2f", during];
                for (int i = 1; i < wholeLength / 9000 + 2; i++) {
                    [wholeData appendData:_buffArr[i]];
                }
                path = [path stringByAppendingPathComponent:[[Tool stringFromDate:date]stringByAppendingPathExtension:@"caf"]];
                [wholeData writeToFile:path atomically:YES];
                [_dataManager saveRecordWithUserID:[NSNumber numberWithUnsignedShort:userId] time:date path:path length:more isOut:NO];
                [_buffArr removeObjectsAtIndexes:[[NSIndexSet alloc]initWithIndexesInRange:NSMakeRange(0, wholeLength / 9000 + 2)]];
                _audioCenter.path = path;
                [_audioCenter startPlay];
            }
            break;
        case MessageProtocalTypePicture:
        case MessageProtocalTypeFile:
        case MessageProtocalTypeAudio:
        case MessageProtocalTypeVideo:
        case MessageProtocalTypeACK:
//            NSLog(@"received ack!");
            [_messageQueueManager messageSended:[_messageProtocal getACKID:data]];
            break;
    }
    [sock receiveWithTimeout:-1 tag:0];
    return YES;
}

@end
