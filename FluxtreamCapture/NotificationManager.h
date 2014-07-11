//
//  NotificationManager.h
//  FluxtreamCapture
//
//  Created by Robert Carlsen on 7/10/14.
//  Copyright (c) 2014 BodyTrack. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString* const FLXIdentifierDeviceDisconnected;
FOUNDATION_EXPORT NSString* const FLXIdentifierDeviceDataNotReceived;
FOUNDATION_EXPORT NSString* const FLXIdentifierDeviceApplicationTerminated;

/// This class handles scheduling and cancelling of local notifications.
@interface NotificationManager : NSObject

+(void)scheduleNotificationWithIdentifier:(NSString*)identifier;
+(void)cancelNotificationWithIdentifier:(NSString*)identifier;
+(void)cancelAllNotifications;

@end
