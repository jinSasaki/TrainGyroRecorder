//
//  GyroDataMananger.m
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/11/26.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import "GyroDataManager.h"

@implementation GyroDataManager

static NSMutableArray *__sections;

// singleton
static GyroDataManager *shareInstance = nil;
+ (instancetype)defaultManager
{
    
    if (!shareInstance) {
        shareInstance = [GyroDataManager new];
    }
    return shareInstance;
}

-(id)init
{
    self = [super init];
    if (self) {
        
        // find csv
        __sections = [self fileNamesInDocumentDirectory];
        
    }
    
    return self;
}

- (NSMutableArray *)fileNamesInDocumentDirectory
{
    NSString *directoryPath;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    directoryPath = [paths objectAtIndex:0];
    
    NSString *extension = @"csv";
    
    NSFileManager *fileManager=[[NSFileManager alloc] init];
    NSError *error = nil;
    /* 全てのファイル名 */
    NSArray *allFileName = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) return nil;
    NSMutableArray *hitFileNames = [[NSMutableArray alloc] init];
    for (NSString *fileName in allFileName) {
        /* 拡張子が一致するか */
        if ([[fileName pathExtension] isEqualToString:extension]) {
            [hitFileNames addObject:fileName];
        }
    }
    return hitFileNames;
    
}


#pragma mark - getter

- (NSArray *)sections
{
    __sections = [self fileNamesInDocumentDirectory];
    return __sections;
}

#pragma mark - setter

- (void)setSections:(NSMutableArray *)sections
{
    __sections = sections;
}

#pragma mark - public methods

- (BOOL)saveSectionData:(NSDictionary *)sectionData
{
    
    
    [__sections addObject:sectionData[KEY_NAME]];
    self.sections = __sections;
    
    // create CSV file
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSArray *keys = DataKeyLabels();
        
        NSString *filename = [sectionData[KEY_NAME] stringByAppendingString:FILE_FORMAT];
        NSString *localDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *localPath = [localDir stringByAppendingPathComponent:filename];
        
        // generate file manager
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        // checking file is exist
        if (![fileManager fileExistsAtPath:localPath]) { // yes
            // create a file
            BOOL result = [fileManager createFileAtPath:localPath
                                               contents:[NSData data] attributes:nil];
            if (!result) {
                NSLog(@"ファイルの作成に失敗");
                return;
            }
        }
        
        // generate file handle
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:localPath];
        if (!fileHandle) {
            NSLog(@"ファイルハンドルの作成に失敗");
            return;
        }
        
        NSLog(@"createing csv file");
        
        NSMutableArray *elements;
        NSString *writeLine;
        NSData *data;
        
        elements = [NSMutableArray array];
        
        for (int j=0; j<sectionData.count ; j++) {
            if ([keys[j] isEqualToString:KEY_NAME]) {
                continue;
            }
            [elements addObject:keys[j]];
        }
        
        
        
        writeLine = [[elements componentsJoinedByString:@","] stringByAppendingString:@",\n "];
        data = [NSData dataWithBytes:writeLine.UTF8String
                              length:writeLine.length];
        // writing to file title
        NSLog(@"writing title");
        [fileHandle writeData:data];
        
        NSInteger num = 0;
        if ([sectionData[KEY_TIMESTAMP_ACCELARATION] count] > [sectionData[KEY_TIMESTAMP_ATTITUDE] count]) {
            num = [sectionData[KEY_TIMESTAMP_ATTITUDE] count];
        } else {
            num = [sectionData[KEY_TIMESTAMP_ACCELARATION] count];
        }
        
        for(int i=0; i< num ;i++){
            
            elements = [NSMutableArray array];
            
            
            for (int j=0; j<sectionData.count ; j++) {
                if ([keys[j] isEqualToString:KEY_NAME]) {
                    continue;
                }
                
                [elements addObject:[sectionData[keys[j]] objectAtIndex:i]];
            }
            
            writeLine = [[elements componentsJoinedByString:@","] stringByAppendingString:@", \n "];
            
            data = [NSData dataWithBytes:writeLine.UTF8String
                                  length:writeLine.length];
            // writing to file
            [fileHandle writeData:data];
        }
        [fileHandle synchronizeFile];
        
        // close the file handle
        [fileHandle closeFile];
        
        NSLog(@"Did Create csv file");
        
    });
    
    return YES;
}

- (void)syncedSectionWithFilePath:(NSString *)filePath
{
    
    
    [self removeSectionDataWithFilePath:filePath];
    
    
}

- (BOOL)removeSectionDataWithFilePath:(NSString *)filePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:filePath];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error;
    [fileManager removeItemAtPath:path error:&error];

    
    if (error) {
        NSLog(@"%@",error);
        return NO;
    }
    
    [__sections removeObject:filePath];
    
    self.sections = __sections;

    
    return YES;
}


@end
