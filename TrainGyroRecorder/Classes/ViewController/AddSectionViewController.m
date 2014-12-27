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
    
    NSInteger carNum;
    
    // data
    NSMutableArray *pitchs;
    NSMutableArray *rolls;
    NSMutableArray *yaws;
    
    NSMutableArray *timestampsOfAttitude;
    NSMutableArray *timestampsOfAccelaration;
    
    NSMutableArray *xAccelerations;
    NSMutableArray *yAccelerations;
    NSMutableArray *zAccelerations;
    
    NSMutableArray *xAccelerationsNonGravity;
    NSMutableArray *yAccelerationsNonGravity;
    NSMutableArray *zAccelerationsNonGravity;
    
    NSMutableArray *vectorSizes;
    
    NSMutableArray *curveFlags;
    
    NSString *name;
    
    NSString *stringBuffer;
    CLLocation *location;
    
    AVAudioPlayer *audio;
    
    UIActionSheet *actionSheet;
}

@property (nonatomic) BOOL isCurving;

@property NSData *buffer;
@property NSOutputStream *stream;

@end

@implementation AddSectionViewController

// frequency
const double frequencyAttribute        = 30; // Hz
const double frequencyAccelaration     = 30; // Hz

// threshold
const double threshold = 0.4;

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
    
    self.switchBtn.layer.backgroundColor = [UIColor whiteColor].CGColor;
    self.switchBtn.layer.borderWidth = 1.0;
    
    self.switchBtn.layer.borderColor = [UIColor greenColor].CGColor;
    [self.switchBtn setTitle:@"Start" forState:UIControlStateNormal];
    [self.switchBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"bgm" ofType:@"mp3"]];
    audio = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
    [audio play];
    [audio stop];
    
    [self prepareForRecording];
    
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated {
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    [super viewWillDisappear:animated];
}


- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeRemoteControl) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlPlay:
            case UIEventSubtypeRemoteControlPause:
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if (self.toStationField.text.length == 0) {
                    
                    self.fromStationField.text = @"remote";
                    carNum = 100;
                    
                    NSDateFormatter *df = [NSDateFormatter new];
                    df.dateFormat = @"yyyyMMdd_HHmm";
                    self.toStationField.text = [df stringFromDate:[NSDate date]];
                }
                [self didPushSwitchBtn:nil];
                
                if (timestampsOfAccelaration.count > 0) {
                    [self didPushDoneBtn:nil];
                }
                
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                
                break;
            default:
                break;
        }
    }
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
    
    xAccelerationsNonGravity  = [NSMutableArray array];
    yAccelerationsNonGravity  = [NSMutableArray array];
    zAccelerationsNonGravity  = [NSMutableArray array];
    
    curveFlags = [NSMutableArray array];
    
    vectorSizes = [NSMutableArray array];
    
}

- (BOOL)validateInputValue {
    
    if (self.toStationField.text.length == 0) {
        return NO;
    }
    if (self.fromStationField.text.length == 0) {
        return NO;
    }
    if (carNum == 0) {
        return NO;
    }
    return YES;
    
}

#pragma mark - IBAction methods

- (IBAction)didPushSwitchBtn:(id)sender {
    
    if (![self validateInputValue]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Validation Error"
                                                       message:@"入力項目が足りません"
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (!self.motionManager.deviceMotionAvailable || !self.motionManager.deviceMotionAvailable) {
        return;
    }
    
    if (self.motionManager.deviceMotionActive || self.motionManager.accelerometerActive) {
        
        // Stop--------------------------------
        
        self.switchBtn.layer.borderColor = [UIColor greenColor].CGColor;
        [self.switchBtn setTitle:@"Start" forState:UIControlStateNormal];
        [self.switchBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        
        // stop motion updates
        [self.motionManager stopDeviceMotionUpdates];
        [self.motionManager stopAccelerometerUpdates];
        
        // update status Label
        self.statusLabel.text = @"Pending";
        
        // sleep unlock
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        
        [audio stop];
        
        return;
    }
    
    
    [audio play];
    
    // Start--------------------------------
    
    
    
    [self.switchBtn setTitle:@"Stop" forState:UIControlStateNormal];
    [self.switchBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.switchBtn.layer.borderColor = [UIColor redColor].CGColor;
    
    
    
    [self prepareForRecording];
    
    
    name = [NSString stringWithFormat:@"%@ → %@", self.fromStationField.text,self.toStationField.text];
    
    // update status Label
    self.statusLabel.text = @"Recording";
    
    NSDate *startDate = [NSDate date];
    
    // start motion updates
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                            withHandler:^(CMDeviceMotion *motion, NSError *error)
     {
         
         [pitchs addObject:@(motion.attitude.pitch)];
         [rolls addObject:@(motion.attitude.roll)];
         [yaws addObject:@(motion.attitude.yaw)];
         NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
         [timestampsOfAttitude addObject:timestamp];
         
         self.timeLabel.text = [NSString stringWithFormat:@"%.2f",-[startDate timeIntervalSinceNow]];
         
         
         if (timestampsOfAttitude.count >= 2) {
             
             double dt = (timestamp.doubleValue - [timestampsOfAttitude[timestampsOfAttitude.count-2] doubleValue]);
             
             double dYaw = motion.attitude.yaw - [yaws[yaws.count-2] doubleValue];
             
             double gradient = dYaw / dt;
             
             if (gradient > threshold || gradient < -threshold) {
                 self.isCurving = YES;
                 self.curveLabel.text = StringCurveStatus(CurveStatusCurving);
             }else {
                 self.isCurving = NO;
                 self.curveLabel.text = StringCurveStatus(CurveStatusNoCurve);
             }
             
             NSLog(@"%.2f",gradient);
             
         }
         
         [curveFlags addObject:@(self.isCurving)];
         
     }];
    
    
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData *data, NSError *error)
     {
         
         NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
         [timestampsOfAccelaration addObject:timestamp];
         
         
         if (timestampsOfAccelaration.count > 1) {
             
             /**
              * 加速度成分から重力成分を除去
              * 正面向いているという仮定のもと
              */
             
             // ローパスフィルタのフィルタ値
             double alpha = 0.1;
             
             // 加速度成分をローパスフィルタに通し、重力成分をとる
             double gx = data.acceleration.x * alpha + [xAccelerations[xAccelerations.count - 1] doubleValue] * (1.0 - alpha);
             double gy = data.acceleration.y * alpha + [yAccelerations[yAccelerations.count - 1] doubleValue] * (1.0 - alpha);
             double gz = data.acceleration.z * alpha + [zAccelerations[zAccelerations.count - 1] doubleValue] * (1.0 - alpha);
             
             
             
             // 重力成分を省いた加速度
             double ax = data.acceleration.x - gx;
             double ay = data.acceleration.y - gy;
             double az = data.acceleration.z - gz;
             
             ax *= 10;
             ay *= 10;
             az *= 10;
             
             double vectorSize;
             
             if (xAccelerationsNonGravity.count > 0) {
                 // 差分算出
                 double dx = ax - [xAccelerationsNonGravity[xAccelerationsNonGravity.count-1] doubleValue];
                 double dy = ay - [yAccelerationsNonGravity[yAccelerationsNonGravity.count-1] doubleValue];
                 double dz = az - [zAccelerationsNonGravity[zAccelerationsNonGravity.count-1] doubleValue];
                 
                 
                 // ベクトルの大きさ
                 vectorSize = sqrt(dx * dx + dy * dy + dz * dz);
                 
                 // y方向向きが負だったら ベクトルも負に
                 if (ay < 0.0) {
                     vectorSize *= -1;
                 }
                 [vectorSizes addObject:@(vectorSize)];
             }
             
             // 配列に追加
             [xAccelerationsNonGravity addObject:@(ax)];
             [yAccelerationsNonGravity addObject:@(ay)];
             [zAccelerationsNonGravity addObject:@(az)];
             
             /**
              * 速度の計算
              */
             
             double dt = (timestamp.doubleValue - [timestampsOfAccelaration[timestampsOfAccelaration.count - 2] doubleValue]);
             
             velocity = velocity + vectorSize * dt;
             NSLog(@"%f",velocity);
             
             //                 // 正面を向いている仮定
             //                 averageV = (averageV * (yAccelerations.count) + data.acceleration.y) / yAccelerations.count;
             //                 double revision = data.acceleration.y - averageV;
             //                 if (revision < 0.0 ) {
             //                     revision = data.acceleration.y;
             //                 }
             //                 velocity = velocity + revision * dt * 10;
             
             // update speed label
             self.speedLabel.text = [NSString stringWithFormat:@"%.2f",velocity];
             
             
         }
         
         [xAccelerations addObject:@(data.acceleration.x)];
         [yAccelerations addObject:@(data.acceleration.y)];
         [zAccelerations addObject:@(data.acceleration.z)];
         
         
     }];
    
}


- (IBAction)didPushDoneBtn:(id)sender {
    
    if ([self validateInputValue] && timestampsOfAttitude.count > 0) {
        // add Recoreded Data
        
        name = [NSString stringWithFormat:@"%@_car%ld",name,carNum];
        
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
    
    
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    // dismiss View
    [self dismissViewControllerAnimated:YES completion:nil];
    
}


- (IBAction)didPushCarNumBtn:(id)sender {
    // アクションシートの作成
    actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    // ツールバーの作成
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolBar.barStyle = UIBarStyleBlackOpaque;
    [toolBar sizeToFit];
    // ピッカーの作成
    UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 44, 0, 0)];
    pickerView.delegate = self;
    pickerView.showsSelectionIndicator = YES;
    // Cancelボタンの作成
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelDidPush)];
    // フレキシブルスペースの作成
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    // Doneボタンの作成
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneDidPush)];
    NSArray *items = [NSArray arrayWithObjects:cancel, spacer, done, nil];
    [toolBar setItems:items animated:YES];
    // アクションシートへの埋め込みと表示
    [actionSheet addSubview:toolBar];
    [actionSheet addSubview:pickerView];
    [actionSheet showInView:self.view];
    [actionSheet setBounds:CGRectMake(0, 0, 320, 464)];
    
}

#pragma mark - Action Sheet selectors

- (void)cancelDidPush {
    // アクションシートの非表示
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
}
- (void)doneDidPush {
    /* 処理 */
    
    [self.carNumBtn setTitle:[NSString stringWithFormat:@"%ld両目",carNum] forState:UIControlStateNormal];
    // アクションシートの非表示
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
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

#pragma mark - Picker View Delegates

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)picker {
    
    // ピッカーの列数
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    // ピッカーの行数
    return 10;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return @(row + 1).stringValue;
}
- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    carNum = row + 1;
}

@end
