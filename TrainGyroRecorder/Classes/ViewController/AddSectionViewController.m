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
    
    double averageV;
    double velocity;
    
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

// frequency
const int frequencyAttribute        = 10; // Hz
const int frequencyAccelaration     = 10; // Hz

// threshold
const double threshold = 0.04;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // make circle buttons
    self.switchBtn.layer.cornerRadius = self.switchBtn.frame.size.height /2;
    
    // init Motion Manager
    self.motionManager = [[CMMotionManager alloc]init];
    
    
    
    // set frequency
    self.motionManager.deviceMotionUpdateInterval = 1 / frequencyAttribute;
    self.motionManager.accelerometerUpdateInterval = 1 / frequencyAccelaration;

    self.fromStationField.delegate = self;
    self.toStationField.delegate = self;

    [self.switchBtn setTitle:@"Start" forState:UIControlStateNormal];
//    self.switchBtn.layer.backgroundColor = [UIColor greenColor].CGColor;
    self.switchBtn.layer.borderColor = [UIColor greenColor].CGColor;

    [self prepareForRecording];
}

- (void)prepareForRecording {

    // init time
    time = 0;

    // init params
    velocity = 0;
    averageV = 0;
    
    self.isCurving = NO;
    self.curveLabel.text = StringCurveStatus(CurveStatusNoCurve);

    // reset status label
    self.statusLabel.text = StringRecordingStatus(RecordingStatusRecording);
    
    // reset time label
    self.timeLabel.text = [NSString stringWithFormat:@"%g",time];

    // reset trainStatus label
    self.trainStatusLabel.text = StringTrainStatus(TrainStatusStopping);

    // reset speed label
    self.speedLabel.text = [NSString stringWithFormat:@"%g",velocity];
    
    
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
//        self.switchBtn.layer.backgroundColor = [UIColor greenColor].CGColor;
        self.switchBtn.layer.borderColor = [UIColor greenColor].CGColor;

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
//    self.switchBtn.layer.backgroundColor = [UIColor redColor].CGColor;
    self.switchBtn.layer.borderColor = [UIColor redColor].CGColor;
    
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
             
             self.timeLabel.text = [NSString stringWithFormat:@"%.2f",-[startDate timeIntervalSinceNow]];


             if (timestampsOfAttitude.count >= 2) {
      
                 double dt = (timestamp.doubleValue - [timestampsOfAttitude[timestampsOfAttitude.count-2] doubleValue]) / 1000;
                 
                 double dYaw = motion.attitude.yaw - [yaws[yaws.count-2] doubleValue];
                 
                 double gradient = dYaw / dt;

                 if (gradient > threshold) {
                     self.isCurving = YES;
                     self.curveLabel.text = StringCurveStatus(CurveStatusCurving);
                 }else {
                     self.isCurving = NO;
                     self.curveLabel.text = StringCurveStatus(CurveStatusNoCurve);
                 }
                 
             }
             
             [curveFlags addObject:@(self.isCurving)];

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
             

             if (timestampsOfAccelaration.count >= 2) {

                 
                 // 速度の計算
                 double dt = (timestamp.doubleValue - [timestampsOfAccelaration[timestampsOfAccelaration.count-2] doubleValue])/1000;
                 
                 // 正面を向いている仮定
                 averageV = (averageV * (yAccelerations.count-1) + data.acceleration.y) / yAccelerations.count;
                 velocity = velocity + (data.acceleration.y - averageV) * dt * 10;
                 
                 // update speed label
                 self.speedLabel.text = [NSString stringWithFormat:@"%.2f",velocity];

             }
             
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
