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
#import "P2PUdpSocket.h"
#import "P2PTcpSocket.h"
#import "MessageQueueManager.h"
#import "PhotoLibraryCenter.h"

@interface MoreView () <PhotoLibraryCenterDelegate> {
    int imagePiecesNum;
}
@property (strong, nonatomic) PhotoLibraryCenter *photoCenter;

@property (strong, nonatomic) UIImagePickerController *imagePickerVC;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSData *imageData;
@property (strong, nonatomic) NSString *originalLocalIdentifier;
@property (strong, nonatomic) NSString *thumbnailImagePath;
@property (strong, nonatomic) UIView *previewView;

@property (strong, nonatomic) P2PUdpSocket *udpSocket;
@property (strong, nonatomic) P2PTcpSocket *tcpSocket;

@end

static char picID = 0;// 图片标识
#warning - 应当使用数组来存储缩略图的packetID，收到一个ack删除一个元素，直到数组为空，说明整个缩略图传送成功。使用简单的int类型会被其它ack混淆
static int imageSendedNum = 0;// 接收到了几个ack

@implementation MoreView
- (void) awakeFromNib {
    _udpSocket = [P2PUdpSocket shareInstance];
    _tcpSocket = [P2PTcpSocket shareInstance];
    _photoCenter = [[PhotoLibraryCenter alloc]init];
    _photoCenter.delegate = self;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(sendOriginalImageInfo:) name:P2PUdpSocketReceiveACKNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(sendOriginalImage) name:P2PTcpSocketDidWritePicInfoNotification object:nil];
}

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
    if (_imagePickerVC == nil) {
        _imagePickerVC = [[UIImagePickerController alloc]init];
        _imagePickerVC.delegate = self;
    }
    _imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    _imagePickerVC.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
    UIViewController *superVC = [self viewController];
    [superVC presentViewController:_imagePickerVC animated:YES completion:nil];
}

- (UIViewController *)viewController {
    for (UIView *next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

- (void)sendPic {
    if (_previewView != nil) {
        [_previewView removeFromSuperview];
    }
    [_imagePickerVC dismissViewControllerAnimated:YES completion:nil];
    UIImage *thumbnail = [_photoCenter makeThumbnail:_image];
    _thumbnailImagePath = [Tool getFileName:@"thumbnail" extension:@"png"];
    [UIImagePNGRepresentation(thumbnail) writeToFile:_thumbnailImagePath atomically:YES];
    [[DataManager shareManager]savePhotoWithUserID:_userID time:[NSDate date] path:_originalLocalIdentifier thumbnail:_thumbnailImagePath isOut:YES];
    picID++;
    NSArray *arr = [[MessageProtocal shareInstance]archiveThumbnail:_thumbnailImagePath picID:picID];
    imagePiecesNum = (int)arr.count;
    for (NSData *data in arr) {
        if (![_udpSocket sendData:data toHost:_ipStr port:UdpPort withTimeout:-1 tag:0]) {
            NSLog(@"MoreView send pic failed");
        } else {
            [[MessageQueueManager shareInstance]addSendingMessageIP:_ipStr packetData:data];
        }
    }
}

- (void)cancel {
    [_previewView removeFromSuperview];
}

- (void)sendOriginalImageInfo:(NSNotification *)notification {
    imageSendedNum++;
    if (imageSendedNum == imagePiecesNum) {
        NSLog(@"MoreView connect host and send original image info");
        NSError *err = nil;
        if (_tcpSocket.isOn) {
            [_tcpSocket disconnect];
        }
        if (![_tcpSocket connectToHost:_ipStr onPort:TcpPort error:&err]) {
            NSLog(@"MoreView connect host failed: %@", err);
        }
        int pic = _userID.shortValue << 16 | picID;
        NSData *picData = [NSData dataWithBytes:&pic length:sizeof(int)];
        [_tcpSocket writeData:picData withTimeout:60 tag:P2PTcpSocketTagTypeInfo];
        imageSendedNum = 0;
    }
}

- (void)sendOriginalImage {
//    while (_imageData == nil) {
//        NSLog(@"thread sleep for 0.5 sec");
//        [NSThread sleepForTimeInterval:0.5];
//    }
    NSLog(@"MoreView begin to write original image data, length: %lu", (unsigned long)_imageData.length);
    [_tcpSocket writeData:_imageData withTimeout:60 tag:P2PTcpSocketTagTypeData];
    _imageData = nil;
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

#pragma mark - image picker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(nonnull NSDictionary<NSString *,id> *)info {
    _image = info[UIImagePickerControllerOriginalImage];
    if (_imagePickerVC.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        [self initPreview];
        
        NSURL *url = info[UIImagePickerControllerReferenceURL];
        _originalLocalIdentifier = [_photoCenter getLocalIdentifierFromPath:[url absoluteString]];
        CGSize size = [UIScreen mainScreen].bounds.size;
        CGFloat scale = MIN(size.width / _image.size.width, size.height / _image.size.height);
        UIImageView *imageView = [[UIImageView alloc]initWithImage:_image];
        imageView.frame = CGRectMake((size.width - _image.size.width * scale) / 2, (size.height - _image.size.height * scale) / 2, _image.size.width * scale, _image.size.height * scale);
        [_previewView addSubview:imageView];
        [picker.view addSubview:_previewView];
        
        [_photoCenter getImageDataWithLocalIdentifier:_originalLocalIdentifier];
    } else {
        [_photoCenter saveImage:_image];
        [self sendPic];
    }
}

#pragma mark - photo library center delegate
- (void)photoLibraryCenterSavedImageWithLocalIdentifier:(NSString *)localIdentifier {
    _originalLocalIdentifier = localIdentifier;
}

- (void)photoLibraryCenterDidGetImageData:(NSData *)imageData {
    _imageData = imageData;
}

@end
