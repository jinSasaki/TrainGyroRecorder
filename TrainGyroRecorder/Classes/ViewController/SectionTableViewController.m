//
//  SectionTableViewController.m
//  TrainGyroRecorder
//
//  Created by Jin Sasaki on 2014/11/26.
//  Copyright (c) 2014年 Jin Sasaki. All rights reserved.
//

#import "SectionTableViewController.h"

@interface SectionTableViewController (){
    AVAudioPlayer *audio;
}
@property NSInteger selectedRow;

@end

@implementation SectionTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.gyroManager = [GyroDataManager defaultManager];
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case AlertButtonOK:
            // ok
            [self performSelector:@selector(syncToDropbox) withObject:nil afterDelay:0.1];
            
            break;
        case AlertButtonCancel:
            // cancel
            
            break;
    }
}

- (void)syncToDropbox
{
    self.uploader = [[DropboxUploader alloc]init];
    self.uploader.delegate = self;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.uploader uploadSection:self.gyroManager.sections[self.selectedRow]];
    
}

- (void)dropboxUploader:(DropboxUploader *)uploader didUploadWithFilePath:(NSString *)filePath
{
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.gyroManager syncedSectionWithIndex:self.selectedRow];
    [self.tableView reloadData];
}

- (void)dropboxUploader:(DropboxUploader *)uploader didFailUploadingWithError:(NSError *)error
{
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Error"
                                                   message:[NSString stringWithFormat:@"%@",error]
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
    [alert show];
    
    
}

- (void)confirmToSync
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Sync" message:@"Do you send this section data?" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"Yes", nil];
    [alert show];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
    
    
    [self becomeFirstResponder];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    NSURL *url = [NSURL URLWithString:[[NSBundle mainBundle] pathForResource:@"bgm" ofType:@"mp3"]];
    audio = [[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];
    [audio play];
    [audio stop];
    
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.gyroManager.sections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"section" forIndexPath:indexPath];
    
    cell.textLabel.text = self.gyroManager.sections[indexPath.row];
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // confirm to sync
    [self confirmToSync];
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        if(![self.gyroManager removeSectionDataWithFilePath:self.gyroManager.sections[indexPath.row]]){
            return;
        }
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
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
                [self performSegueWithIdentifier:@"add" sender:self];
                break;
            default:
                break;
        }
    }
}

@end
