//
//  DropboxUploader.m
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/12/03.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import "DropboxUploader.h"

@implementation DropboxUploader

- (void)uploadSection:(NSString *)section {
    
    // Write a file to the local documents directory
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
 
    NSString *filename = section;
    NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *localPath = [localDir stringByAppendingPathComponent:filename];

    // generate file manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // checking file is exist
    if (![fileManager fileExistsAtPath:localPath]) {
        
        NSLog(@"file did not exist");
        NSError *error = [NSError errorWithDomain:@"file did not exist" code:0 userInfo:nil];
        if ([self.delegate respondsToSelector:@selector(dropboxUploader:didFailUploadingWithError:)]) {
            [self.delegate dropboxUploader:self didFailUploadingWithError:error];
        }

        return;
    }

    
    [self.restClient uploadFile:filename toPath:destDir withParentRev:nil fromPath:localPath];
    
}

- (void)uploadOnMainThread {
}


#pragma mark - DBRestClientDelegate methods

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
    
    if ([self.delegate respondsToSelector:@selector(dropboxUploader:didUploadWithFilePath:toDBPath:)]) {
        [self.delegate dropboxUploader:self didUploadWithFilePath:srcPath toDBPath:metadata.path];
    }
    
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    NSLog(@"File upload failed with error: %@", error);
    if ([self.delegate respondsToSelector:@selector(dropboxUploader:didFailUploadingWithError:)]) {
        [self.delegate dropboxUploader:self didFailUploadingWithError:error];
    }
    
}

@end

