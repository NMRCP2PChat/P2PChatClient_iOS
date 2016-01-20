//
//  ChatViewController.m
//  p2pChat
//
//  Created by xiaokun on 16/1/4.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "ChatViewController.h"
#import "P2PUdpSocket.h"
#import "Friend.h"
#import "MessageProtocal.h"
#import "DataManager.h"
#import "Message.h"
#import "MyFetchedResultsControllerDelegate.h"
#import "MessageCell.h"
#import "AudioCenter.h"
#import "Tool.h"
#import "MessageQueueManager.h"
#import "RecordView.h"
#import "MoreView.h"

#define VIEWHEIGHT 100

#define MyMessageCell @"my message"
#define FriendMessageCell @"friend message"
#define MyRecordCell @"my record"
#define FriendRecordCell @"friend record"
#define MyPhotoCell @"my photo"
#define FriendPhotoCell @"friend photo"

@interface ChatViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    NSString *_name;
    NSNumber *_userID;
    NSString *_photoPath;
    BOOL _showRecordView;
    BOOL _showMoreView;
    CGSize _screenSize;
}

@property (weak, nonatomic) IBOutlet UIView *baseView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *baseBottomConstraint;
@property (weak, nonatomic) IBOutlet UITextField *messageTF;
@property (weak, nonatomic) IBOutlet UITableView *historyTableView;

@property (strong, nonatomic) RecordView *recordView;
@property (strong, nonatomic) MoreView *moreView;

@property (strong, nonatomic) NSFetchedResultsController *historyController;
@property (strong, nonatomic) MyFetchedResultsControllerDelegate *historyControllerDelegate;

@property (strong, nonatomic) P2PUdpSocket *udpSocket;
@property (strong, nonatomic) MessageQueueManager *messageQueueManager;

@property (strong, nonatomic) NSString *myPhotoPath;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // init socket
    _udpSocket = [P2PUdpSocket shareInstance];
    _ipStr = @"10.8.53.156";
//    _ipStr = @"127.0.0.1";
    
    _messageQueueManager = [MessageQueueManager shareInstance];
    
    //--------
    _userID = [NSNumber numberWithUnsignedShort:234];
    _photoPath = [[NSBundle mainBundle]pathForResource:@"0" ofType:@"png"];
    
    // init table view
    _historyTableView.dataSource = self;
    _historyTableView.delegate = self;
    _historyTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _historyController = [[DataManager shareManager]getMessageByUserID:_userID];
    _historyControllerDelegate = [[MyFetchedResultsControllerDelegate alloc]initWithTableView:_historyTableView];
    _historyController.delegate = _historyControllerDelegate;

    // init text field
    _messageTF.delegate = self;
    
    // init cells
    [_historyTableView registerNib:[UINib nibWithNibName:@"MyMessageCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:MyMessageCell];
    [_historyTableView registerNib:[UINib nibWithNibName:@"FriendMessageCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:FriendMessageCell];
    [_historyTableView registerNib:[UINib nibWithNibName:@"MyRecordCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:MyRecordCell];
    [_historyTableView registerNib:[UINib nibWithNibName:@"FriendRecordCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:FriendRecordCell];
    [_historyTableView registerNib:[UINib nibWithNibName:@"MyPhotoCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:MyPhotoCell];
    [_historyTableView registerNib:[UINib nibWithNibName:@"FriendPhotoCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:FriendPhotoCell];
    _myPhotoPath = [[NSUserDefaults standardUserDefaults]stringForKey:@"photoPath"];
    
    // init record view
    _screenSize = [UIScreen mainScreen].bounds.size;
    _showRecordView = NO;
    _recordView = [[NSBundle mainBundle]loadNibNamed:@"RecordView" owner:self options:nil].lastObject;
    _recordView.frame = CGRectMake(0, _screenSize.height, _screenSize.width, VIEWHEIGHT);
    _recordView.ipStr = _ipStr;
    _recordView.userID = _userID;
    [self.view addSubview:_recordView];
    
    // init more view
    _showMoreView = NO;
    _moreView = [[NSBundle mainBundle]loadNibNamed:@"MoreView" owner:self options:nil].lastObject;
    _moreView.frame = CGRectMake(0, _screenSize.height, _screenSize.width, VIEWHEIGHT);
    _moreView.ipStr = _ipStr;
    _moreView.userID = _userID;
    [self.view addSubview:_moreView];
}

- (void)viewWillAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = YES;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - IB actions
- (IBAction)record:(id)sender {
    [_messageTF resignFirstResponder];
    if (_showMoreView) {
        _baseBottomConstraint.constant = 0;
        [UIView animateWithDuration:0.5 animations:^{
            _moreView.frame = CGRectMake(0, _screenSize.height, _screenSize.width, VIEWHEIGHT);
            [self.view layoutIfNeeded];
        }];
        _showMoreView = NO;
    }
    if (_showRecordView) {
        _baseBottomConstraint.constant = 0;
        [UIView animateWithDuration:0.5 animations:^{
            _recordView.frame = CGRectMake(0, _screenSize.height, _screenSize.width, VIEWHEIGHT);
            [self.view layoutIfNeeded];
        }];
        _showRecordView = NO;
    } else {
        _baseBottomConstraint.constant = VIEWHEIGHT * -1;
        [UIView animateWithDuration:0.5 animations:^{
            _recordView.frame = CGRectMake(0, _screenSize.height - VIEWHEIGHT, _screenSize.width, VIEWHEIGHT);
            [self.view layoutIfNeeded];
        }];
        _showRecordView = YES;
    }
}

- (IBAction)send:(id)sender {
    NSString *message = _messageTF.text;
    if (![message isEqualToString:@""]) {
        NSDate *date = [NSDate date];
        _messageTF.text = @"";
        [[DataManager shareManager]saveMessageWithUserID:_userID time:date body:message isOut:YES];
    
        NSData *data = [[MessageProtocal shareInstance] archiveText:message];
        if(![_udpSocket sendData:data toHost:_ipStr port:UdpPort withTimeout:-1 tag:1]) {
            NSLog(@"ChatVC send text failed");
        } else {
            [_messageQueueManager addSendingMessageIP:_ipStr packetData:data];
        }
    }
}

- (IBAction)more:(id)sender {
    [_messageTF resignFirstResponder];
    if (_showRecordView) {
        _baseBottomConstraint.constant = 0;
        [UIView animateWithDuration:0.5 animations:^{
            _recordView.frame = CGRectMake(0, _screenSize.height, _screenSize.width, VIEWHEIGHT);
            [self.view layoutIfNeeded];
        }];
        _showRecordView = NO;
    }
    if (_showMoreView) {
        _baseBottomConstraint.constant = 0;
        [UIView animateWithDuration:0.5 animations:^{
            _moreView.frame = CGRectMake(0, _screenSize.height, _screenSize.width, VIEWHEIGHT);
            [self.view layoutIfNeeded];
        }];
        _showMoreView = NO;
    } else {
        _baseBottomConstraint.constant = VIEWHEIGHT * -1;
        [UIView animateWithDuration:0.5 animations:^{
            _moreView.frame = CGRectMake(0, _screenSize.height - VIEWHEIGHT, _screenSize.width, VIEWHEIGHT);
            [self.view layoutIfNeeded];
        }];
        _showMoreView = YES;
    }
}

#pragma mark -table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = _historyController.sections[section];
    return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageCell *cell = nil;
    Message *message = [_historyController objectAtIndexPath:indexPath];
    MessageProtocalType type = message.type.charValue;
    switch (type) {
        case MessageProtocalTypeMessage:
            if (message.isOut.boolValue) {
                cell = (MessageCell *)[_historyTableView dequeueReusableCellWithIdentifier:MyMessageCell forIndexPath:indexPath];
                [cell setPhotoPath:_myPhotoPath time:message.time body:message.body more:nil];
            } else {
                cell = (MessageCell *)[_historyTableView dequeueReusableCellWithIdentifier:FriendMessageCell forIndexPath:indexPath];
                [cell setPhotoPath:_photoPath time:message.time body:message.body more:nil];
            }
            break;
        case MessageProtocalTypeRecord:
            if (message.isOut.boolValue) {
                cell = (MessageCell *)[_historyTableView dequeueReusableCellWithIdentifier:MyRecordCell forIndexPath:indexPath];
                [cell setPhotoPath:_myPhotoPath time:message.time body:nil more:message.more];
            } else {
                cell = (MessageCell *)[_historyTableView dequeueReusableCellWithIdentifier:FriendRecordCell forIndexPath:indexPath];
                [cell setPhotoPath:_photoPath time:message.time body:nil more:message.more];
            }
        case MessageProtocalTypePicture:
            if (message.isOut.boolValue) {
                cell = (MessageCell *)[_historyTableView dequeueReusableCellWithIdentifier:MyPhotoCell forIndexPath:indexPath];
                [cell setPhotoPath:_myPhotoPath bodyPath:message.more];
            } else {
                cell = (MessageCell *)[_historyTableView dequeueReusableCellWithIdentifier:FriendPhotoCell forIndexPath:indexPath];
                [cell setPhotoPath:_photoPath bodyPath:message.more];
            }
        default:
            break;
    }
    
    return cell;
}

#pragma mark - table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

#pragma mark -keyboard notification
- (void)keyboardShow:(NSNotification *)notification {
    _showMoreView = NO;
    _showRecordView = NO;
    CGFloat height = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    _baseBottomConstraint.constant = height * -1;
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardHidden:(NSNotification *)notification {
    _baseBottomConstraint.constant = 0;
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark -text field delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self send:nil];
    
    return YES;
}
@end
