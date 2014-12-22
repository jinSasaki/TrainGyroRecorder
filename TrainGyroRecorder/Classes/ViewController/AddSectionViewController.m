//
//  AddSectionViewController.m
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/11/26.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import "AddSectionViewController.h"

@interface AddSectionViewController ()
{
    double time;
    double speed;
    
    // data
    NSMutableArray *pitchs;
    NSMutableArray *rolls;
    NSMutableArray *yaws;
    
    NSMutableArray *timestampsOfAttitude;
    NSMutableArray *timestampsOfAccelaration;
    
    NSMutableArray *xAccelerations;
    NSMutableArray *yAccelerations;
    NSMutableArray *zAccelerations;

    NSMutableArray *curveFlags;

    NSString *name;
    
    NSString *stringBuffer;
    CLLocation *location;
}

@property (nonatomic) BOOL isCurving;

@property NSData *buffer;
@property NSOutputStream *stream;

@end

@implementation AddSectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // make circle buttons
    self.switchBtn.layer.cornerRadius = self.switchBtn.frame.size.height /2;
    
    // init Motion Manager
    self.motionManager = [[CMMotionManager alloc]init];
    
    
    self.fromStationField.delegate = self;
    self.toStationField.delegate = self;

    [self.switchBtn setTitle:@"Start" forState:UIControlStateNormal];
    self.switchBtn.layer.backgroundColor = [UIColor greenColor].CGColor;

    [self prepareForRecording];
}

- (void)prepareForRecording {

    // init time
    time = 0;

    // init speed
    speed = 0;

    // init status label
    self.statusLabel.text = StringRecordingStatus(RecordingStatusRecording);
    
    // init time label
    self.timeLabel.text = [NSString stringWithFormat:@"%g",time];

    // init trainStatus label
    self.trainStatusLabel.text = StringTrainStatus(TrainStatusStopping);

    // init speed label
    self.speedLabel.text = [NSString stringWithFormat:@"%g",speed];
    
    
    // init Arrays
    pitchs  = [NSMutableArray array];
    rolls   = [NSMutableArray array];
    yaws    = [NSMutableArray array];

    timestampsOfAttitude        = [NSMutableArray array];
    timestampsOfAccelaration    = [NSMutableArray array];

    xAccelerations  = [NSMutableArray array];
    yAccelerations  = [NSMutableArray array];
    zAccelerations  = [NSMutableArray array];

    curveFlags = [NSMutableArray array];
    
}


#pragma mark - IBAction methods

- (IBAction)didPushSwitchBtn:(id)sender {
    
    if (self.motionManager.deviceMotionActive || self.motionManager.accelerometerActive) {

        // Stop--------------------------------
        
        [self.switchBtn setTitle:@"Start" forState:UIControlStateNormal];
        self.switchBtn.layer.backgroundColor = [UIColor greenColor].CGColor;

        // stop motion updates
        [self.motionManager stopDeviceMotionUpdates];
        [self.motionManager stopAccelerometerUpdates];
        
        // update status Label
        self.statusLabel.text = @"Pending";
        
        // sleep unlock
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    
        return;
    }

    
    // Start--------------------------------

    [self.switchBtn setTitle:@"Stop" forState:UIControlStateNormal];
    self.switchBtn.layer.backgroundColor = [UIColor redColor].CGColor;
    
    [self prepareForRecording];
    
    // sleep lock
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    name = [NSString stringWithFormat:@"%@ → %@", self.fromStationField.text,self.toStationField.text];
    
    // update status Label
    self.statusLabel.text = @"Recording";
    
    NSDate *startDate = [NSDate date];
    
    // start motion updates
    if (self.motionManager.deviceMotionAvailable) {
        
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                                withHandler:^(CMDeviceMotion *motion, NSError *error)
         {

             [pitchs addObject:@(motion.attitude.pitch)];
             [rolls addObject:@(motion.attitude.roll)];
             [yaws addObject:@(motion.attitude.yaw)];
             NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000];
             [timestampsOfAttitude addObject:timestamp];
             
             [curveFlags addObject:@(self.isCurving)];
             
             self.timeLabel.text = [NSString stringWithFormat:@"%.2f",-[startDate timeIntervalSinceNow]];

         }];
    }
    
        if (self.motionManager.accelerometerAvailable) {
        
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                                 withHandler:^(CMAccelerometerData *data, NSError *error)
         {

             [xAccelerations addObject:@(data.acceleration.x)];
             [yAccelerations addObject:@(data.acceleration.y)];
             [zAccelerations addObject:@(data.acceleration.z)];
             NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000];
             [timestampsOfAccelaration addObject:timestamp];

             
         }];
    }
}


- (IBAction)didPushDoneBtn:(id)sender {
    
    if (name) {
        // add Recoreded Data
        
        NSDictionary *sectionData = @{KEY_NAME                      : name,
                                      KEY_TIMESTAMP_ATTITUDE        : timestampsOfAttitude,
                                      KEY_ATTITUDE_PITCH            : pitchs,
                                      KEY_ATTITUDE_ROLL             : rolls,
                                      KEY_ATTITUDE_YAW              : yaws,

                                      KEY_TIMESTAMP_ACCELARATION    : timestampsOfAccelaration,
                                      KEY_ACCELARATION_X            : xAccelerations,
                                      KEY_ACCELARATION_Y            : yAccelerations,
                                      KEY_ACCELARATION_Z            : zAccelerations,
                                      
                                      KEY_CURVE_FLAG                : curveFlags
                                      };

        
        GyroDataManager *gyroManager = [GyroDataManager defaultManager];
        [gyroManager saveSectionData:sectionData];
        
    }
    // dismiss View
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - delegate methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.toStationField resignFirstResponder];
    [self.fromStationField resignFirstResponder];
}



@end
