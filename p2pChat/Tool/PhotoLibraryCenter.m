//
//  PhotoLibraryCenter.m
//  p2pChat
//
//  Created by xiaokun on 16/1/18.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import "PhotoLibraryCenter.h"
#import "AppDelegate.h"

@interface PhotoLibraryCenter ()

@property (strong, nonatomic) PHAssetCollection *collection;
@property (strong, nonatomic) NSString *localIdentifier;

@end

@implementation PhotoLibraryCenter

- (id)init {
    self = [super init];
    
    PHFetchOptions *phOptions = [[PHFetchOptions alloc]init];
    NSString *albumName = @"test";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title=%@", albumName];
    phOptions.predicate = predicate;
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:phOptions];
    if (result.count <= 0) {
        [[PHPhotoLibrary sharedPhotoLibrary]performChanges:^{
            [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
            PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:phOptions];
            _collection = result.firstObject;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"creat album: %@", success ? @"success" : error);
        }];
    } else {
        _collection = result.firstObject;
    }
    
    return self;
}

- (void)saveImage:(UIImage *)image {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:_collection];
        PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
        _localIdentifier = [assetPlaceholder.localIdentifier substringWithRange:NSMakeRange(0, 36)];
        [albumChangeRequest addAssets:@[assetPlaceholder]];
        if ([_delegate respondsToSelector:@selector(photoLibraryCenterSavedImageWithLocalIdentifier:)]) {
            [_delegate photoLibraryCenterSavedImageWithLocalIdentifier:_localIdentifier];
        }
    } completionHandler:^(BOOL success, NSError *error) {
        NSLog(@"Finished adding asset. %@", (success ? @"Success" : error));
        if ([_delegate respondsToSelector:@selector(photoLibraryCenterDidGetImageData:)]) {
            [self getImageDataWithLocalIdentifier:_localIdentifier];
        }        
    }];
}

- (UIImage *)makeThumbnail:(UIImage *)originalImage {
    UIImage *thumbnail = nil;
    CGFloat scale = MIN(150 / originalImage.size.width, 150 / originalImage.size.height);
    CGSize smallSize = CGSizeMake(originalImage.size.width * scale, originalImage.size.height * scale);//缩略图大小
    UIGraphicsBeginImageContextWithOptions(smallSize, NO, 1.0);
    [originalImage drawInRect:CGRectMake(0, 0, smallSize.width, smallSize.height)];
    thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumbnail;
}

- (void)getImageWithLocalIdentifier:(NSString *)identifier {
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil].lastObject;
    [[PHImageManager defaultManager]requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if ([_delegate respondsToSelector:@selector(photoLibraryCenterDidGetImage:)]) {
            [_delegate photoLibraryCenterDidGetImage:result];
        }
    }];
}

- (void)getImageDataWithLocalIdentifier:(NSString *)identifier { //得到原图data
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil].lastObject;
    [[PHImageManager defaultManager]requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if ([_delegate respondsToSelector:@selector(photoLibraryCenterDidGetImageData:)]) {
            [_delegate photoLibraryCenterDidGetImageData:imageData];
        }
        NSLog(@"PhotoLibraryCenter get image data success");
    }];
}

- (NSString *)getLocalIdentifierFromPath:(NSString *)path {
    NSRange beginRange = [path rangeOfString:@"?id="];
    NSUInteger beginLocation = beginRange.location + 4;
    NSRange endRange = [path rangeOfString:@"&ext"];
    NSUInteger endLocation = endRange.location;
    NSString *localIdentifier = [path substringWithRange:NSMakeRange(beginLocation, endLocation - beginLocation)];
    return localIdentifier;
}

@end
