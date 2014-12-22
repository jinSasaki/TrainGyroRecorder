//
//  GyroDataMananger.h
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/11/26.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GyroDataManager : NSObject



@property (readonly) NSArray *sections;

+ (instancetype)defaultManager;

- (BOOL)saveSectionData:(NSDictionary *)sectionData;

- (void)syncedSectionWithIndex:(NSInteger)index;

@end
