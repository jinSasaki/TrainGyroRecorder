//
//  ConfigViewController.h
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/12/27.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConfigViewController : UITableViewController
<UITextFieldDelegate>
{
    IBOutletCollection(UITextField) NSArray *textfields;
}


@end
