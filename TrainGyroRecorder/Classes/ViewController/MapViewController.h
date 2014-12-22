//
//  MapViewController.h
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/11/26.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "GyroDataManager.h"

@interface MapViewController : UIViewController
<MKMapViewDelegate>

@property (nonatomic , weak) IBOutlet MKMapView *mapView;
@property GyroDataManager *gyroManager;

@property NSDictionary *section;

@end
