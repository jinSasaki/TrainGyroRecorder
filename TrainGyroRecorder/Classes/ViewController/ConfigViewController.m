//
//  ConfigViewController.m
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/12/27.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import "ConfigViewController.h"

@interface ConfigViewController ()

@end

@implementation ConfigViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSArray *config = [ud arrayForKey:KEY_CONFIG];
    for (int i=0; i<config.count; i++) {
        UITextField *tf = textfields[i];
        tf.text = config[i];
        tf.delegate = self;
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (![self validateInputValues]) {
        return;
    }

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableArray *config = [NSMutableArray array];
    for (int i=0; i<config.count; i++) {
        UITextField *tf = textfields[i];
        [config addObject:tf.text];
    }
    [ud setObject:config forKey:KEY_CONFIG];

}

- (BOOL)validateInputValues
{
    double curveThreshold            = [[textfields[0] text] doubleValue];
    double accelerometerFrequency    = [[textfields[1] text] doubleValue];
    double devicemotionFrequency     = [[textfields[2] text] doubleValue];
//    double accelarationThreshold     = [[textfields[3] text] doubleValue];
//    double decelarationThreshold     = [[textfields[4] text] doubleValue];
    
    NSString *message;
    BOOL flag = YES;
    
    if (curveThreshold <= 0.0 || curveThreshold > 10.0) {
        message = @"閾値は 0 ~ 10 である必要があります";
        flag = NO;
    }
    if (accelerometerFrequency <= 0.0 || accelerometerFrequency > 100.0) {
        message = @"周波数は 0 ~ 100 である必要があります";
        flag = NO;
    }
    if (devicemotionFrequency <= 0.0 || devicemotionFrequency > 100.0) {
        message = @"周波数は 0 ~ 100 である必要があります";
        flag = NO;
    }
//    if (accelarationThreshold <= 0.0 || accelarationThreshold > 10.0) {
//        message = @"閾値は 0 ~ 10 である必要があります";
//        flag = NO;
//    }
//    if (decelarationThreshold <= 0.0 || decelarationThreshold > 10.0) {
//        message = @"閾値は 0 ~ 10 である必要があります";
//        flag = NO;
//    }
    
    if (!flag) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Not Complete"
                                                       message:message
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
        [alert show];
    }
    
    return flag;
    
}

@end
