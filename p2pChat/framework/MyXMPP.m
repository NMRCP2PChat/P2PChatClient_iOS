//
//  MyXMPP.m
//  p2pChat
//
//  Created by xiaokun on 16/3/4.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "MyXMPP.h"
#import "XMPPFramework.h"

@interface MyXMPP () <XMPPStreamDelegate>

@property (strong, nonatomic) XMPPStream *stream;
@property (strong, nonatomic) XMPPJID *jid;

@end

@implementation MyXMPP

- (id)init {
    self = [super init];
    
    _stream = [[XMPPStream alloc]init];
    [_stream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    _jid = [XMPPJID jidWithUser:@"test2" domain:@"10.108.136.59" resource:@"iphone"];
    _stream.myJID = _jid;
    NSError *err = nil;
    if (![_stream connectWithTimeout:XMPPStreamTimeoutNone error:&err]) {
        NSLog(@"connect failed: %@", err);
    }
    
    return self;
}

#pragma mark - xmpp delegate
- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    NSLog(@"did connect");
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    NSLog(@"DidDisconnect");
}

@end
