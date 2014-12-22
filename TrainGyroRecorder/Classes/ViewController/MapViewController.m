//
//  MapViewController.m
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/11/26.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import "MapViewController.h"

@interface MapViewController ()

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSArray *locations = self.section[KEY_LOCATION];
    CLLocation *centerLocation = locations[0];
    
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;
    
    [_mapView setCenterCoordinate:centerLocation.coordinate animated:NO];

    MKCoordinateRegion cr = _mapView.region;
    cr.center = centerLocation.coordinate;
    cr.span.latitudeDelta = 0.5;
    cr.span.longitudeDelta = 0.5;
    [_mapView setRegion:cr animated:NO];
    
}

@end
