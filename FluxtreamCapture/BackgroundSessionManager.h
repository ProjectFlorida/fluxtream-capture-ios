//
//  BackgroundSessionManager.h
//  FluxtreamCapture
//
//  Created by Robert Carlsen on 9/18/14.
//  Copyright (c) 2014 BodyTrack. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Responsible for managing the background NSURLSession and associated callbacks.
 */
@interface BackgroundSessionManager : NSObject

+(instancetype)sharedInstance;

-(void)setBackgroundSessionCompletionHandler:(void (^)())completionHandler;
-(BOOL)queueUploadRequest:(NSURLRequest*)request withData:(NSData*)payload;

@end
