//
//  Defines.h
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/11/26.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEY_NAME            @"NAME"

#define KEY_ATTITUDE_PITCH  @"ATTITUDE_PITCH"
#define KEY_ATTITUDE_ROLL   @"ATTITUDE_ROLL"
#define KEY_ATTITUDE_YAW    @"ATTITUDE_YAW"

#define KEY_ACCELARATION_X  @"ACCELARATION_X"
#define KEY_ACCELARATION_Y  @"ACCELARATION_Y"
#define KEY_ACCELARATION_Z  @"ACCELARATION_Z"

#define KEY_VECTOR_SIZE       @"VECTOR_SIZE"
#define KEY_VELOCITIES        @"VELOCITIES"

#define KEY_CURVE_FLAG        @"CURVE_FLAG"
#define KEY_TRAIN_STATUS        @"TRAIN_STATUS"

#define KEY_TIMESTAMP_ATTITUDE          @"TIMESTAMP_ATTITUDE"
#define KEY_TIMESTAMP_ACCELARATION      @"TIMESTAMP_ACCELARATION"

#define APP_KEY             @"u3apsrq2g4c5m9f"
#define APP_SECRET          @"teymmsoumx9zov7"
#define destDir             @"/BandaiLab/data"
#define FILE_FORMAT         @".csv"

#define KEY_CONFIG         @"CONFIG"

typedef NS_ENUM (NSInteger ,RecordingStatus){
    RecordingStatusPending     = 0,
    RecordingStatusRecording   = 1,
    RecordingStatusError       = 9
};
typedef NS_ENUM (NSInteger ,TrainStatus){
    TrainStatusStopping     = 0,
    TrainStatusRunning      = 1,
    TrainStatusAccel        = 2,
    TrainStatusDecel        = 3,
    TrainStatusError        = 9
};
typedef NS_ENUM (NSInteger ,CurveStatus){
    CurveStatusNoCurve      = 0,
    CurveStatusCurving      = 1,
    CurveStatusError        = 9
};

NSString *StringRecordingStatus(RecordingStatus status);
NSString *StringTrainStatus(TrainStatus status);
NSString *StringCurveStatus(CurveStatus status);

NSArray *DataKeyLabels();