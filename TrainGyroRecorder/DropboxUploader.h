//
//  DropboxUploader.h
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/12/03.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>

@class DropboxUploader;

@protocol DropboxUploaderDelegate <NSObject>

@optional

- (void)dropboxUploader:(DropboxUploader *)uploader didUploadWithFilePath:(NSString *)filePath toDBPath:(NSString *)DBpath;
- (void)dropboxUploader:(DropboxUploader *)uploader didFailUploadingWithError:(NSError *)error;


@end

@interface DropboxUploader : NSObject
<DBRestClientDelegate>
@property (nonatomic, strong) DBRestClient *restClient;

@property (nonatomic, weak) id <DropboxUploaderDelegate>  delegate;


- (void)uploadSection:(NSDictionary *)section;

@end
