//
//  MoreView.m
//  p2pChat
//
//  Created by xiaokun on 16/1/10.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "MoreView.h"
#import "Tool.h"
#import "MessageProtocal.h"
#import "DataManager.h"
#import "AsyncUdpSocket.h"
#import "MessageQueueManager.h"

@interface MoreView ()

@property (strong, nonatomic) UIImagePickerController *imagePickerVC;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSString *originalImagePath;
@property (strong, nonatomic) NSString *thumbnailImagePath;
@property (strong, nonatomic) UIView *previewView;

@end

@implementation MoreView 

- (IBAction)pickPicture:(id)sender {
    if (_imagePickerVC == nil) {
        _imagePickerVC = [[UIImagePickerController alloc]init];
        _imagePickerVC.delegate = self;
    }
    _imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    UIViewController *superVC = [self viewController];
    [superVC presentViewController:_imagePickerVC animated:YES completion:nil];
}

- (IBAction)pickPhoto:(id)sender {
}

- (UIViewController*)viewController {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

- (void)sendPic {
    _originalImagePath = [Tool getFileName:@"original" extension:@"png"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [UIImagePNGRepresentation(_image) writeToFile:_originalImagePath atomically:YES];
    });
    [_previewView removeFromSuperview];
    [_imagePickerVC dismissViewControllerAnimated:YES completion:nil];
    [self makeThumbnail];
}

- (void)cancel {
    [_previewView removeFromSuperview];
}

- (void)makeThumbnail {
    UIImage *thumbnail = nil;
    CGFloat scale = MIN(150 / _image.size.width, 150 / _image.size.height);
    CGSize smallSize = CGSizeMake(_image.size.width * scale, _image.size.height * scale);//缩略图大小
    UIGraphicsBeginImageContextWithOptions(smallSize, NO, 1.0);
    [_image drawInRect:CGRectMake(0, 0, smallSize.width, smallSize.height)];
    thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _thumbnailImagePath = [Tool getFileName:@"thumbnail" extension:@"png"];

    [UIImagePNGRepresentation(thumbnail) writeToFile:_thumbnailImagePath atomically:YES];
    [[DataManager shareManager]savePhotoWithUserID:_userID time:[NSDate date] path:_originalImagePath thumbnail:_thumbnailImagePath isOut:YES];
    
    NSArray *arr = [[MessageProtocal shareInstance]archiveThumbnail:_thumbnailImagePath];
    for (NSData *data in arr) {
        if (![_udpSocket sendData:data toHost:_ipStr port:1234 withTimeout:-1 tag:0]) {
            NSLog(@"MoreView send pic failed");
        } else {
            [[MessageQueueManager shareInstance]addSendingMessageIP:_ipStr packetData:data];
        }
    }

}

- (void)initPreview {
    _previewView = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
    _previewView.backgroundColor = [UIColor whiteColor];
    _previewView.alpha = 0.98;
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cancelBtn.frame = CGRectMake(15, 20, 50, 30);
    [cancelBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [cancelBtn setTitle:@"cancel" forState:UIControlStateNormal];
    [_previewView addSubview:cancelBtn];
    
    UIButton *sendBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sendBtn.frame = CGRectMake(size.width - 65, 20, 50, 30);
    [sendBtn addTarget:self action:@selector(sendPic) forControlEvents:UIControlEventTouchUpInside];
    [sendBtn setTitle:@"send" forState:UIControlStateNormal];
    [_previewView addSubview:sendBtn];
}

#pragma mark -- image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(nonnull NSDictionary<NSString *,id> *)info {
    [self initPreview];
    CGSize size = [UIScreen mainScreen].bounds.size;
    _image = info[UIImagePickerControllerOriginalImage];
    CGFloat scale = MIN(size.width / _image.size.width, size.height / _image.size.height);
    UIImageView *imageView = [[UIImageView alloc]initWithImage:_image];
    imageView.frame = CGRectMake((size.width - _image.size.width * scale) / 2, (size.height - _image.size.height * scale) / 2, _image.size.width * scale, _image.size.height * scale);
    [_previewView addSubview:imageView];
    [picker.view addSubview:_previewView];
}
@end
