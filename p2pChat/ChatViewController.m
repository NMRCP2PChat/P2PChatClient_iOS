//
//  ChatViewController.m
//  p2pChat
//
//  Created by xiaokun on 16/1/4.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "ChatViewController.h"
#import "AppDelegate.h"
#import "Friend.h"
#import "MessageProtocal.h"
#import "DataManager.h"
#import "Message.h"
#import "MyFetchedResultsControllerDelegate.h"
#import "MessageCell.h"
#import "AudioCenter.h"
#import "Tool.h"

#define RECORDVIEWHEIGHT 100

@interface ChatViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    NSString *_name;
    NSNumber *_userID;
    NSString *_photoPath;
    BOOL _showRecordView;
    CGSize _screenSize;
}

@property (weak, nonatomic) IBOutlet UIView *baseView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *baseBottomConstraint;
@property (weak, nonatomic) IBOutlet UITextField *messageTF;
@property (weak, nonatomic) IBOutlet UITableView *historyTableView;

@property (strong, nonatomic) UIView *recordView;

@property (strong, nonatomic) NSFetchedResultsController *historyController;
@property (strong, nonatomic) MyFetchedResultsControllerDelegate *historyControllerDelegate;

@property (strong, nonatomic) AsyncUdpSocket *udpSocket;

@property (strong, nonatomic) NSString *myPhotoPath;

@property (strong, nonatomic) AudioCenter *audioCenter;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // init socket
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    _udpSocket = appDelegate.udpSocket;
    _ipStr = @"127.0.0.1";
    
    //--------
    _userID = [NSNumber numberWithUnsignedShort:234];
    _photoPath = [[NSBundle mainBundle]pathForResource:@"0" ofType:@"png"];
    
    // init table view
    _historyTableView.dataSource = self;
    _historyTableView.delegate = self;
    _historyController = [[DataManager shareManager]getMessageByUserID:_userID];
    _historyControllerDelegate = [[MyFetchedResultsControllerDelegate alloc]initWithTableView:_historyTableView];
    _historyController.delegate = _historyControllerDelegate;
    
//    for (Message *msg in _historyController.fetchedObjects) {
//        NSLog(@"%@", msg.isOut);
//    }
    
    // init text field
    _messageTF.delegate = self;
    
    // init cells
    [_historyTableView registerNib:[UINib nibWithNibName:@"MyMessageCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"my message"];
    [_historyTableView registerNib:[UINib nibWithNibName:@"FriendMessageCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"friend message"];
    [_historyTableView registerNib:[UINib nibWithNibName:@"MyRecordCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"my record"];
    [_historyTableView registerNib:[UINib nibWithNibName:@"FriendRecordCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"friend record"];
    _myPhotoPath = [[NSUserDefaults standardUserDefaults]stringForKey:@"photoPath"];
    
    // init record view
    _screenSize = [UIScreen mainScreen].bounds.size;
    _showRecordView = NO;
    _recordView = [[UIView alloc]initWithFrame:CGRectMake(0, _screenSize.height, _screenSize.width, RECORDVIEWHEIGHT)];
    UIButton *recordBtn = [UIButton buttonWithType:UIButtonTypeContactAdd];
    recordBtn.frame = CGRectMake(_screenSize.width / 2 - 10, RECORDVIEWHEIGHT / 2 - 10, 20, 20);
    [recordBtn addTarget:self action:@selector(startRecord) forControlEvents:UIControlEventTouchDown];
    [recordBtn addTarget:self action:@selector(stopRecord) forControlEvents:UIControlEventTouchUpInside];
    [_recordView addSubview:recordBtn];
    [self.view addSubview:_recordView];
    _audioCenter = [AudioCenter shareInstance];
}

- (void)viewWillAppear:(BOOL)animated {
    self.tabBarController.tabBar.hidden = YES;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark -- IB actions
- (IBAction)record:(id)sender {
    if (_showRecordView) {
        _baseBottomConstraint.constant = 0;
        [UIView animateWithDuration:0.5 animations:^{
            _recordView.frame = CGRectMake(0, _screenSize.height, _screenSize.width, RECORDVIEWHEIGHT);
            [self.view layoutIfNeeded];
        }];
        _showRecordView = NO;
    } else {
        _baseBottomConstraint.constant = RECORDVIEWHEIGHT * -1;
        [UIView animateWithDuration:0.5 animations:^{
            _recordView.frame = CGRectMake(0, _screenSize.height - RECORDVIEWHEIGHT, _screenSize.width, RECORDVIEWHEIGHT);
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
    }
    if(![_udpSocket sendData:[[MessageProtocal shareInstance] archiveText:message] toHost:_ipStr port:1234 withTimeout:-1 tag:1]) {
        NSLog(@"BaseView send failed");
    }

}

- (IBAction)more:(id)sender {
    
}

- (void)startRecord {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    path = [path stringByAppendingPathComponent:[[Tool stringFromDate:[NSDate date]]stringByAppendingPathExtension:@"caf"]];
    _audioCenter.path = path;
    [_audioCenter startRecord];
}

- (void)stopRecord {
    CGFloat during = [_audioCenter stopRecord];
    [[DataManager shareManager]saveRecordWithUserID:_userID time:[NSDate date] path:_audioCenter.path length:[NSString stringWithFormat:@"%f", during] isOut:YES];
    [_udpSocket sendData:[[MessageProtocal shareInstance] archiveRecord:_audioCenter.path] toHost:_ipStr port:1234 withTimeout:-1 tag:1];
}

#pragma mark --table view data source
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
                cell = (MessageCell *)[_historyTableView dequeueReusableCellWithIdentifier:@"my message" forIndexPath:indexPath];
                [cell setPhotoPath:_myPhotoPath time:message.time body:message.body more:nil];
            } else {
                cell = (MessageCell *)[_historyTableView dequeueReusableCellWithIdentifier:@"friend message" forIndexPath:indexPath];
                [cell setPhotoPath:_photoPath time:message.time body:message.body more:nil];
            }
            break;
        case MessageProtocalTypeRecord:
            if (message.isOut.boolValue) {
                cell = (MessageCell *)[_historyTableView dequeueReusableCellWithIdentifier:@"my record" forIndexPath:indexPath];
                [cell setPhotoPath:_myPhotoPath time:message.time body:nil more:message.more];
            } else {
                cell = (MessageCell *)[_historyTableView dequeueReusableCellWithIdentifier:@"friend record" forIndexPath:indexPath];
                [cell setPhotoPath:_photoPath time:message.time body:nil more:message.more];
            }
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark -- table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

#pragma mark --keyboard notification
- (void)keyboardShow:(NSNotification *)notification {
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

#pragma mark --text field delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self send:nil];
    
    return YES;
}
@end
