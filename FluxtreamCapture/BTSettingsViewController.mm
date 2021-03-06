//
//  BTSettingsViewController.m
//  Stetho
//
//  Created by Rich Henderson on 1/7/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import "BTSettingsViewController.h"
#import "BTPulseTracker.h"
#import "BTPhoneTracker.h"
#import "BTAppDelegate.h"
#import "Constants.h"

#define kPhotosToBeUploaded 1
#define kServerWillChange   2
#define kUsernameIsEmailAddress 3

@interface BTSettingsViewController ()

@end

@implementation BTSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //
    }
    return self;
}

- (void)configureView
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [_username setText:[defaults objectForKey:DEFAULTS_USERNAME]];
    [_password setText:[defaults objectForKey:DEFAULTS_PASSWORD]];
    [_server setText:[defaults objectForKey:DEFAULTS_SERVER]];

    _backgroundSwitch = [[UISwitch alloc] init];
    [_backgroundSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_backgroundCell setAccessoryView:_backgroundSwitch];
    [_backgroundSwitch setOn:[defaults boolForKey:DEFAULTS_BACKGROUND_UPLOAD]];
    
    _locationSwitch = [[UISwitch alloc] init];
    [_locationSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_locationCell setAccessoryView:_locationSwitch];
    [_locationSwitch setOn:[defaults boolForKey:DEFAULTS_RECORD_LOCATION]];
    
    _motionSwitch = [[UISwitch alloc] init];
    [_motionSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_motionCell setAccessoryView:_motionSwitch];
    [_motionSwitch setOn:[defaults boolForKey:DEFAULTS_RECORD_MOTION]];
    
    _appStatsSwitch = [[UISwitch alloc] init];
    [_appStatsSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_appStatsCell setAccessoryView:_appStatsSwitch];
    [_appStatsSwitch setOn:[defaults boolForKey:DEFAULTS_RECORD_APP_STATS]];
    
    _heartRateSwitch = [[UISwitch alloc] init];
    [_heartRateSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_recordHeartRateCell setAccessoryView:_heartRateSwitch];
    [_heartRateSwitch setOn:[defaults boolForKey:DEFAULTS_RECORD_HEARTRATE]];

    _filterConnectionModeSwitch = [[UISwitch alloc] init];
    [_filterConnectionModeSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_filterConnectionModeCell setAccessoryView:_filterConnectionModeSwitch];
    [_filterConnectionModeSwitch setOn:[defaults boolForKey:DEFAULTS_FILTER_DEVICES]];
    
    _heartbeatSoundSwitch = [[UISwitch alloc] init];
    [_heartbeatSoundSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_heartbeatSoundCell setAccessoryView:_heartbeatSoundSwitch];
    [_heartbeatSoundSwitch setOn:[defaults boolForKey:DEFAULTS_HEARTBEAT_SOUND]];
    
    _portraitUploadSwitch = [[UISwitch alloc] init];
    [_portraitUploadSwitch setTag:200];
    [_portraitUploadSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_portraitUploadSwitch addTarget:self action:@selector(orientationSettingsChanged:) forControlEvents:UIControlEventValueChanged];
    [_portraitCell setAccessoryView:_portraitUploadSwitch];
    [_portraitUploadSwitch setOn:[defaults boolForKey:DEFAULTS_PHOTO_ORIENTATION_PORTRAIT]];
    
    _upsideDownUploadSwitch = [[UISwitch alloc] init];
    [_upsideDownUploadSwitch setTag:201];
    [_upsideDownUploadSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_upsideDownUploadSwitch addTarget:self action:@selector(orientationSettingsChanged:) forControlEvents:UIControlEventValueChanged];
    [_upsideDownCell setAccessoryView:_upsideDownUploadSwitch];
    [_upsideDownUploadSwitch setOn:[defaults boolForKey:DEFAULTS_PHOTO_ORIENTATION_UPSIDE_DOWN]];
    
    _landscapeLeftUploadSwitch = [[UISwitch alloc] init];
    [_landscapeLeftUploadSwitch setTag:202];
    [_landscapeLeftUploadSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_landscapeLeftUploadSwitch addTarget:self action:@selector(orientationSettingsChanged:) forControlEvents:UIControlEventValueChanged];
    [_landscapeLeftCell setAccessoryView:_landscapeLeftUploadSwitch];
    [_landscapeLeftUploadSwitch setOn:[defaults boolForKey:DEFAULTS_PHOTO_ORIENTATION_LANDSCAPE_LEFT]];
    
    _landscapeRightUploadSwitch = [[UISwitch alloc] init];
    [_landscapeRightUploadSwitch setTag:203];
    [_landscapeRightUploadSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_landscapeRightUploadSwitch addTarget:self action:@selector(orientationSettingsChanged:) forControlEvents:UIControlEventValueChanged];
    [_landscapeRightCell setAccessoryView:_landscapeRightUploadSwitch];
    [_landscapeRightUploadSwitch setOn:[defaults boolForKey:DEFAULTS_PHOTO_ORIENTATION_LANDSCAPE_RIGHT]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosToBeUploaded:) name:BT_NOTIFICATION_PHOTOS_TO_BE_UPLOADED object:nil];
	[self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)updateUploaderFromUI:(FluxtreamUploaderObjc*)uploader {
    if (![uploader.username isEqualToString: _username.text] ||
        ![uploader.password isEqualToString: _password.text]) {
        uploader.username = _username.text;
        uploader.password = _password.text;
        [uploader uploadNow];
    }
}

- (IBAction)updateFromUI:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_username.text forKey:DEFAULTS_USERNAME];
    [defaults setObject:_password.text forKey:DEFAULTS_PASSWORD];
    [defaults setObject:_server.text forKey:DEFAULTS_SERVER];
    [defaults setBool:_locationSwitch.isOn forKey:DEFAULTS_RECORD_LOCATION];
    [defaults setBool:_motionSwitch.isOn forKey:DEFAULTS_RECORD_MOTION];
    [defaults setBool:_appStatsSwitch.isOn forKey:DEFAULTS_RECORD_APP_STATS];
    [defaults setBool:_heartRateSwitch.isOn forKey:DEFAULTS_RECORD_HEARTRATE];
    [defaults setBool:_heartbeatSoundSwitch.isOn forKey:DEFAULTS_HEARTBEAT_SOUND];
    [defaults setBool:_portraitUploadSwitch.isOn forKey:DEFAULTS_PHOTO_ORIENTATION_PORTRAIT];
    [defaults setBool:_upsideDownUploadSwitch.isOn forKey:DEFAULTS_PHOTO_ORIENTATION_UPSIDE_DOWN];
    [defaults setBool:_landscapeLeftUploadSwitch.isOn forKey:DEFAULTS_PHOTO_ORIENTATION_LANDSCAPE_LEFT];
    [defaults setBool:_landscapeRightUploadSwitch.isOn forKey:DEFAULTS_PHOTO_ORIENTATION_LANDSCAPE_RIGHT];
    [defaults setBool:_filterConnectionModeSwitch.isOn forKey:DEFAULTS_FILTER_DEVICES];
    [defaults setBool:_backgroundSwitch.isOn forKey:DEFAULTS_BACKGROUND_UPLOAD];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // this will only work if the uploaders exist already.
    BTPulseTracker *pulseTracker = [(BTAppDelegate *)[[UIApplication sharedApplication] delegate] pulseTracker];
    [self updateUploaderFromUI:pulseTracker.heartRateUploader];
    [self updateUploaderFromUI:pulseTracker.activityUploader];

    pulseTracker.connectMode = (_filterConnectionModeSwitch.isOn) ? kConnectUUIDMode : kConnectBestSignalMode;
    
    BTPhoneTracker *phoneTracker = [(BTAppDelegate *)[[UIApplication sharedApplication] delegate] phoneTracker];
    [self updateUploaderFromUI:phoneTracker.batteryUploader];
    [self updateUploaderFromUI:phoneTracker.timeZoneUploader];
    [self updateUploaderFromUI:phoneTracker.appStatsUploader];
    [self updateUploaderFromUI:phoneTracker.locationUploader];
    [self updateUploaderFromUI:phoneTracker.motionUploader];

    phoneTracker.recordBatteryEnabled = [defaults boolForKey:DEFAULTS_RECORD_APP_STATS];
    phoneTracker.recordAppStatsEnabled = [defaults boolForKey:DEFAULTS_RECORD_APP_STATS];
    phoneTracker.recordLocationEnabled = [defaults boolForKey:DEFAULTS_RECORD_LOCATION];
    phoneTracker.recordMotionEnabled = [defaults boolForKey:DEFAULTS_RECORD_MOTION];
}


- (IBAction)orientationSettingsChanged:(id)sender
{
    if ([sender isOn]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSDate date] forKey:DEFAULTS_PHOTO_ORIENTATION_SETTINGS_CHANGED];
        
        BTPhotoUploader *photoUploader = [BTPhotoUploader sharedPhotoUploader];
        ALAssetOrientation orientation;
        switch ([sender tag]) {
            case 200: // Portrait
                orientation = ALAssetOrientationRight;
                break;
                
            case 201: // Upside down
                orientation = ALAssetOrientationLeft;
                break;
                
            case 202: // Landscape left
                orientation = ALAssetOrientationDown;
                break;
                
            case 203: // Landscape right
                orientation = ALAssetOrientationUp;
                break;
                
            default:
                NSLog(@"orientation not handled");
                orientation = ALAssetOrientationUp;
                break;
        }
        
        [photoUploader unuploadedPhotosWithOrientation:orientation];
    }
}

- (IBAction)serverWillChange:(id)sender
{
    NSString *messageBody = @"You shouldn't usually have to change this setting. Are you sure you want to proceed?";
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Fluxtream Server"
                                                      message:messageBody
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Proceed", nil];
    message.tag = kServerWillChange;
    [message show];
}

- (void)usernameContainsEmailAddress;
{
    static BOOL hasBeenPresented = NO;
    if (hasBeenPresented) {
        return;
    }

    NSString *message = @"The username is usually not an e-mail address. Please confirm the username in your profile at fluxtream.com";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fluxtream Username"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    alert.tag = kUsernameIsEmailAddress;
    [alert show];
    hasBeenPresented = YES;
}

#pragma mark - Photo uploader notifications

- (void)photosToBeUploaded:(NSNotification *)notification
{
    _photosForUpload = [notification.userInfo objectForKey:@"urls"];
    
    if ([_photosForUpload count] > 0) {
        _orientationForUpload = (ALAssetOrientation)[[notification.userInfo objectForKey:@"orientation"] intValue];
        NSString *messageBody = [NSString stringWithFormat:@"You have %@ existing photos with this orientation. Upload them now?", [notification.userInfo objectForKey:@"count"]];
        
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Photo Upload"
                                                          message:messageBody
                                                         delegate:self
                                                cancelButtonTitle:@"No"
                                                otherButtonTitles:@"Upload", nil];
        message.tag = kPhotosToBeUploaded;
        [message show];
    }

}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // check the tag property on the alertview to determine which of the two possible UIAlertViews we are dealing with
    
    switch (alertView.tag) {
        case kPhotosToBeUploaded:
            if (buttonIndex == 1) {
                [[BTPhotoUploader sharedPhotoUploader] markPhotosForUpload:_photosForUpload];
            } else {
                _photosForUpload = nil;
            }
            break;
            
        case kServerWillChange:
            if (buttonIndex == 1) {
                // the user wants to edit the server - proceed
            } else {
                // leave it
                [_server resignFirstResponder];
            }

        case kUsernameIsEmailAddress:
            // NOP
        default:
            break;
    }

}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self updateFromUI:self];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isEqual:_username]) {
        NSString *replacementString = [textField text];
        BOOL result = [self containsEmailAddress:replacementString];
        if (result) {
            NSLog(@"e-mail address detected in: %@", replacementString);
            [self usernameContainsEmailAddress];
        }
    }
}

// adapted from: http://www.cocoawithlove.com/2009/06/verifying-that-string-is-email-address.html
- (BOOL)containsEmailAddress:(NSString*)haystack;
{
    static NSString * const emailRegEx =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";

    static NSPredicate * const regExPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];

    return [regExPredicate evaluateWithObject:haystack];
}

@end
