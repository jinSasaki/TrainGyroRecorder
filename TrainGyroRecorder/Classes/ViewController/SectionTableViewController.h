//
//  SectionTableViewController.h
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/11/26.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GyroDataManager.h"

#import "DropboxUploader.h"
#import <AVFoundation/AVFoundation.h>


@interface SectionTableViewController : UITableViewController
<UIAlertViewDelegate,DropboxUploaderDelegate>

@property GyroDataManager *gyroManager;
@property DropboxUploader *uploader;

@end


typedef NS_ENUM(NSInteger, AlertButton){
    AlertButtonCancel = 0,
    AlertButtonOK
};