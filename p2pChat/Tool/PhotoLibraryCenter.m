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

+ (instancetype)shareInstance {
    AppDelegate *delegate = [UIApplication sharedApplication].delegate;
    return delegate.photoLibraryCenter;
}

- (void)saveImage:(UIImage *)image {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:_collection];
        PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
        [albumChangeRequest addAssets:@[assetPlaceholder]];
        
    } completionHandler:^(BOOL success, NSError *error) {
        NSLog(@"Finished adding asset. %@", (success ? @"Success" : error));
    }];
}

//- (UIImage *)getImageWithPath:(NSString *)path {
//    PHImageManager *manager = [PHImageManager defaultManager];
//}

@end
