//
//  NotificationManager.m
//  FluxtreamCapture
//
//  Created by Robert Carlsen on 7/10/14.
//  Copyright (c) 2014 BodyTrack. All rights reserved.
//

#import "NotificationManager.h"

NSString* const FLXIdentifierKey = @"FLXIdentifierKey";
NSString* const FLXIdentifierDeviceDisconnected = @"FLXIdentifierDeviceDisconnected";
NSString* const FLXIdentifierDeviceDataNotReceived = @"FLXIdentifierDeviceDataNotReceived";
NSString* const FLXIdentifierDeviceApplicationTerminated = @"FLXIdentifierDeviceApplicationTerminated";
NSString* const FLXIdentifierDeviceBackgroundTaskExpired = @"FLXIdentifierDeviceBackgroundTaskExpired";

// these values could be tweaked...need to find a good threshold to ignore rapid reconnections
static NSTimeInterval deviceDisconnectionNotificationDelay  = 2 * 60;
static NSTimeInterval dataNotReceivedNotificationDelay      = 0.5 * 60;

@implementation NotificationManager

/// may return nil if an notification is not found for this identifier
+(UILocalNotification*)notificationForIdentifier:(NSString*)identifier;
{
    __block UILocalNotification *foundNotification = nil;

    NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    [notifications enumerateObjectsUsingBlock:^(UILocalNotification *obj, NSUInteger idx, BOOL *stop) {
        NSString *notificationId = obj.userInfo[FLXIdentifierKey];
        if (!notificationId) {
            return;
        }
        if ([notificationId isEqualToString:identifier]) {
            foundNotification = obj;
            *stop = YES;
        }
    }];

    return foundNotification;
}


+(void)scheduleNotificationWithIdentifier:(NSString*)identifier;
{
    [self scheduleNotificationWithIdentifier:identifier fireDate:nil];
}

+(void)scheduleNotificationWithIdentifier:(NSString*)identifier fireDate:(NSDate*)date;
{
    // ensure the a notification of the incoming type is not already scheduled.
    [self cancelNotificationWithIdentifier:identifier];

    // create a new notification appropriate for the type
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.userInfo = @{FLXIdentifierKey:identifier};
    notification.soundName = UILocalNotificationDefaultSoundName;

    // by scheduling the notification inside each conditional we prevent scheduling unknown notification types.
    if ([identifier isEqualToString:FLXIdentifierDeviceApplicationTerminated]) {
        notification.alertBody = NSLocalizedString(@"Logging has stopped.", nil);
        notification.fireDate = date;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        return;
    }
    // this notification is of limited value if the other notifications are more directly relevant.
    // ie. if the background task expired because the device connection was lost or the app
    // stopped receiving data, then those are the conditions we really care about.
    if ([identifier isEqualToString:FLXIdentifierDeviceBackgroundTaskExpired]) {
        notification.alertBody = NSLocalizedString(@"Background task has expired.", nil);
        notification.fireDate = date;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        return;
    }

    if ([identifier isEqualToString:FLXIdentifierDeviceDisconnected]) {
        notification.alertBody = NSLocalizedString(@"Lost the device connection.", nil);
        notification.fireDate = (date) ? date : [NSDate dateWithTimeIntervalSinceNow:deviceDisconnectionNotificationDelay];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        return;
    }

    if ([identifier isEqualToString:FLXIdentifierDeviceDataNotReceived]) {
        notification.alertBody = NSLocalizedString(@"Stopped receiving data from the device.", nil);
        notification.fireDate = (date) ? date : [NSDate dateWithTimeIntervalSinceNow:dataNotReceivedNotificationDelay];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        return;
    }
}


+(void)cancelNotificationWithIdentifier:(NSString*)identifier;
{
    UILocalNotification *existingNotification = [self notificationForIdentifier:identifier];
    if (existingNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:existingNotification];
    }
}

+(void)cancelAllNotifications;
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

@end
