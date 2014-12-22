//
//  Defines.m
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/11/26.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

NSString * StringRecordingStatus(RecordingStatus status) {
    NSArray *statusString = @[@"Pending",
                              @"Recording",
                              @"",
                              @"",
                              @"",
                              @"",
                              @"",
                              @"",
                              @"Error"];
    return statusString[status];
}

NSString *StringTrainStatus(TrainStatus status) {
    NSArray *statusString = @[@"Stopping",
                              @"Running",
                              @"",
                              @"",
                              @"",
                              @"",
                              @"",
                              @"",
                              @"Error"];
    return statusString[status];
}

NSArray *DataKeyLabels() {
    NSArray *keys = @[KEY_NAME,
                      
                      KEY_TIMESTAMP_ATTITUDE,
                      KEY_ATTITUDE_PITCH,
                      KEY_ATTITUDE_ROLL,
                      KEY_ATTITUDE_YAW,
                      
                      KEY_TIMESTAMP_ACCELARATION,
                      KEY_ACCELARATION_X,
                      KEY_ACCELARATION_Y,
                      KEY_ACCELARATION_Z,
                      
                      KEY_CURVE_FLAG,
                      
                      ];
    return keys;
}