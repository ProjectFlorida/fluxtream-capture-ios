//
//  BackgroundSessionManager.h
//  FluxtreamCapture
//
//  Created by Robert Carlsen on 9/18/14.
//  Copyright (c) 2014 BodyTrack. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Notifications are posted when each background task completes.
FOUNDATION_EXPORT NSString * const kBackgroundSessionNotificationUploadAuthFailed;
FOUNDATION_EXPORT NSString * const kBackgroundSessionNotificationUploadNetworkError;
FOUNDATION_EXPORT NSString * const kBackgroundSessionNotificationUploadSucceeded;

/**
 * The notification userInfo object will contain the batch id value. This can be used to identify which batch of samples the notification is regarding.
 *
 * Note: The userInfo block may be nil.
 */
FOUNDATION_EXPORT NSString * const kTaskBatchIdKey;

/**
 * Responsible for managing the background NSURLSession and associated callbacks.
 */
@interface BackgroundSessionManager : NSObject

+(instancetype)sharedInstance;

-(void)setBackgroundSessionCompletionHandler:(void (^)())completionHandler;
-(BOOL)queueUploadRequest:(NSURLRequest*)request withData:(NSData*)payload;

@end
