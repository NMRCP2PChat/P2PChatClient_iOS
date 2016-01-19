//
//  PhotoLibraryCenter.h
//  p2pChat
//
//  Created by xiaokun on 16/1/18.
//  Copyright © 2016年 xiaokun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@protocol PhotoLibraryCenterDelegate <NSObject>

@optional
- (void)photoLibraryCenterDidGetImage:(UIImage *)image;
- (void)photoLibraryCenterDidGetImageData:(NSData *)imageData;
- (void)photoLibraryCenterSaveImageWithLocalIdentifier:(NSString *)localIdentifier;

@end

@interface PhotoLibraryCenter : NSObject

@property (weak, nonatomic) id<PhotoLibraryCenterDelegate> delegate;

- (void)saveImage:(UIImage *)image;
- (UIImage *)makeThumbnail:(UIImage *)originalImage;
- (NSString *)getLocalIdentifierFromPath:(NSString *)path;

- (void)getImageDataWithLocalIdentifier:(NSString *)identifier;
- (void)getImageWithLocalIdentifier:(NSString *)identifier;

@end
