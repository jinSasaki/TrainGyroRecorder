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
    
    // frequency
    double deviceMotionFrequency;
    double accelerometerFrequency;
    
    // threshold
    double threshold;

    
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

    AVAudioPlayer *audio;
    
    UIActionSheet *actionSheet;
}

@property (nonatomic) BOOL isCurving;

@end

@implementation AddSectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // get config
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSArray *config = [ud arrayForKey:KEY_CONFIG];
    
    threshold = [config[0] doubleValue];
    accelerometerFrequency = [config[1] doubleValue];
    deviceMotionFrequency = [config[2] doubleValue];
    
    // make circle buttons
    self.switchBtn.layer.cornerRadius = self.switchBtn.frame.size.height /2;
    
    // init Motion Manager
    self.motionManager = [[CMMotionManager alloc]init];
    
    // set frequency
    self.motionManager.deviceMotionUpdateInterval = 1 / deviceMotionFrequency;
    self.motionManager.accelerometerUpdateInterval = 1 / accelerometerFrequency;
    
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
                    
                    self.fromStationField.text = @"Remote";
                    self.toStationField.text = @" ";
                    carNum = 100;
                }
                [self didPushSwitchBtn:nil];
                
                if (timestampsOfAccelaration.count > 0) {
                    [self didPushDoneBtn:nil];
                }
                
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
            case UIEventSubtypeRemoteControlNextTrack:
                NSLog(@"prev");
                
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
        
        self.switchBtn.layer.borderColor = [UIColor greenColor].CGColor;
        [self.switchBtn setTitle:@"Start" forState:UIControlStateNormal];
        [self.switchBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];

        [self stopRecording];
        
        return;
    }
    
    [self.switchBtn setTitle:@"Stop" forState:UIControlStateNormal];
    [self.switchBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.switchBtn.layer.borderColor = [UIColor redColor].CGColor;
    
    
    [self prepareForRecording];
    
    [self startRecording];
    
}

- (void)startRecording {
    
    [audio play];

    // create file name
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"MMddHHmmss";
    name = [NSString stringWithFormat:@"%@_%@-%@", [df stringFromDate:[NSDate date]],self.fromStationField.text,self.toStationField.text];
    
    // update status Label
    self.statusLabel.text = @"Recording";
    
    NSDate *startDate = [NSDate date];
    
    // start motion updates
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                            withHandler:^(CMDeviceMotion *motion, NSError *error)
     {
         
         // add attitude data
         [pitchs addObject:@(motion.attitude.pitch)];
         [rolls addObject:@(motion.attitude.roll)];
         [yaws addObject:@(motion.attitude.yaw)];
         
         // add timestamp
         NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
         [timestampsOfAttitude addObject:timestamp];

         // update time label
         self.timeLabel.text = [NSString stringWithFormat:@"%.2f",-[startDate timeIntervalSinceNow]];
         

         // detect curve
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
             
         }
         
         [curveFlags addObject:@(self.isCurving)];
         
     }];
    
    
    // start accelerometer
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData *data, NSError *error)
     {

         // add timestamp
         NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
         [timestampsOfAccelaration addObject:timestamp];
         

         // calc velocity
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
             
             // 単位をm/sに
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
                 
                 // TODO: 正面向いてる前提
                 vectorSize = ay;

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
             
             // velocity の単位は km/hのため変換
             velocity = velocity + (vectorSize * 3600 / 1000) * dt;
             
             // update speed label
             self.speedLabel.text = [NSString stringWithFormat:@"%.1f",velocity];
             
             
         }
         
         [xAccelerations addObject:@(data.acceleration.x)];
         [yAccelerations addObject:@(data.acceleration.y)];
         [zAccelerations addObject:@(data.acceleration.z)];
         
     }];

}

- (void)stopRecording {
    
    // stop motion updates
    [self.motionManager stopDeviceMotionUpdates];
    [self.motionManager stopAccelerometerUpdates];
    
    // update status Label
    self.statusLabel.text = @"Pending";
    
    // sleep unlock
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    [audio stop];

}


- (IBAction)didPushDoneBtn:(id)sender {
    
    if ([self validateInputValue] && timestampsOfAttitude.count > 0) {
        // add Recoreded Data
        
        name = [NSString stringWithFormat:@"%@_car%ld",name,carNum];
        
        NSArray *data = @[name,
                          timestampsOfAttitude,
                          pitchs,
                          rolls,
                          yaws,
                          timestampsOfAccelaration,
                          xAccelerations,
                          yAccelerations,
                          zAccelerations,
                          curveFlags];
        
        NSDictionary *sectionData = [NSDictionary dictionaryWithObjects:data forKeys:DataKeyLabels()];                
        
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
