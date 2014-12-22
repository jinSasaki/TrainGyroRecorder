//
//  GyroTableViewController.h
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/11/26.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GyroDataManager.h"

#import "MapViewController.h"

@interface GyroTableViewController : UITableViewController

@property GyroDataManager *gyroManager;
@property NSDictionary *section;
@end
