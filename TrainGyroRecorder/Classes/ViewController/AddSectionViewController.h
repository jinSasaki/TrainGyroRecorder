//
//  AddSectionViewController.h
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/11/26.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

#import "GyroDataManager.h"

#import <AVFoundation/AVFoundation.h>

@interface AddSectionViewController : UIViewController
<UITextFieldDelegate , UIPickerViewDelegate , UIPickerViewDataSource , UIActionSheetDelegate>

@property (nonatomic ,weak) IBOutlet UITextField *fromStationField;
@property (nonatomic ,weak) IBOutlet UITextField *toStationField;

@property (nonatomic ,weak) IBOutlet UILabel *statusLabel;
@property (nonatomic ,weak) IBOutlet UILabel *timeLabel;
@property (nonatomic ,weak) IBOutlet UILabel *curveLabel;
@property (nonatomic ,weak) IBOutlet UILabel *trainStatusLabel;
@property (nonatomic ,weak) IBOutlet UILabel *speedLabel;


@property (nonatomic ,weak) IBOutlet UIButton *switchBtn;
@property (nonatomic ,weak) IBOutlet UIButton *carNumBtn;

@property CMMotionManager *motionManager;


- (IBAction)didPushSwitchBtn:(id)sender;

- (IBAction)didPushDoneBtn:(id)sender;

- (IBAction)didPushCarNumBtn:(id)sender;

@end
