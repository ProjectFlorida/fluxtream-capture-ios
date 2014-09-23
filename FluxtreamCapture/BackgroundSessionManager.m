//
//  BackgroundSessionManager.m
//  FluxtreamCapture
//
//  Created by Robert Carlsen on 9/18/14.
//  Copyright (c) 2014 BodyTrack. All rights reserved.
//

#import "BackgroundSessionManager.h"

static NSString *kBackgroundSessionIdentifier = @"org.bodytrack.fluxtream-capture.background.session";

// presumed to be in the Caches directory
static NSString *kTaskStateDictionaryFileName = @"org.bodytrack.fluxtream-capture.background.task.state.plist";

// don't want to provide a full url to risk modification by external parties
// we will *only* modify data in the tmp directory
static NSString *kTaskTemporaryFileNameKey = @"kTaskTemporaryFileNameKey";
static NSString *kTaskResponseDataKey = @"kTaskResponseDataKey";


@interface BackgroundSessionManager()
<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
@property(nonatomic, copy) void(^backgroundSessionCompletionHandler)();

/// Dictionary of dictionaries keyed by task identifiers.
@property(nonatomic, strong) NSMutableDictionary *taskDictionary;
@end

@implementation BackgroundSessionManager

#pragma mark - Initializers
+ (instancetype) sharedInstance;
{
    static id sharedInstance;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initShared];
    });
    return sharedInstance;
}

- (instancetype)init;
{
    NSAssert(0, @"Must use the singleton +sharedInstance");
    return nil;
}

- (instancetype)initShared;
{
    if ((self = [super init])) {

        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesPath = [paths firstObject];
        _taskDictionary = [[NSDictionary dictionaryWithContentsOfFile:[cachesPath stringByAppendingPathComponent:kTaskStateDictionaryFileName]] mutableCopy];
        if (!_taskDictionary) {
            _taskDictionary = [NSMutableDictionary new];
        }

    }
    return self;
}


#pragma mark - Methods

// this is intended to be called each time the dictionary is updated
// and/or whenever the application suspends.
// this is potentially a lot of filesystem access and mutating of a file.
-(void)updateTaskDictionary;
{
    // simply write the current state to disk
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesPath = [paths firstObject];
    NSString *taskDictionaryPath = [cachesPath stringByAppendingPathComponent:kTaskStateDictionaryFileName];

    BOOL result = [self.taskDictionary writeToFile:taskDictionaryPath atomically:YES];
    if (!result) {
        NSLog(@"error writing tasks dictionary file");
    }
}

#pragma mark - Background URL Session Handling
// something seems off about all this...there is one background session (by apple design)
// but many instances of this uploader class...so, how do we ensure that the correct delegate
// is called, rather than just the first one that registered the static session object?
-(NSURLSession*)backgroundSession
{
    static NSURLSession *staticSession;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // this is deprecated on iOS 8.
        NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:kBackgroundSessionIdentifier];
        backgroundConfiguration.discretionary  = NO; // this should flip to "YES" when uploads initiate in the background
        backgroundConfiguration.allowsCellularAccess = YES;

        staticSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration
                                                      delegate:self
                                                 delegateQueue:nil];
    });
    return staticSession;
}

-(void)setBackgroundSessionCompletionHandler:(void (^)())completionHandler;
{
    _backgroundSessionCompletionHandler = completionHandler;
    [self backgroundSession]; // configures the session and delegates. must be done *after* storing the completion handler.
}

#pragma mark - NSURLSessionDelegate
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.backgroundSessionCompletionHandler) {
        self.backgroundSessionCompletionHandler();
        self.backgroundSessionCompletionHandler = nil;
    }
}

#pragma mark - NSURLSessionTaskDelegate
//- (void)URLSession:(NSURLSession *)session
//              task:(NSURLSessionTask *)task
//didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
// completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
//{
//    // what to do with this callback?
//    // nop
//}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error;
{
    // register a background task to ensure that we can delete the file.
    __block UIBackgroundTaskIdentifier backgroundTask = UIBackgroundTaskInvalid;
    backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    }];

    NSInteger statusCode = [(NSHTTPURLResponse*)task.response statusCode];

    // clean up the temporary file after looking up the task identifier
    NSString *taskKey = [@(task.taskIdentifier) stringValue];
    NSDictionary *taskMetaData = self.taskDictionary[taskKey];
    NSString *taskFileName = taskMetaData[kTaskTemporaryFileNameKey];
    NSURL *fileURL = nil;
    if (taskFileName) {
        fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:taskFileName]];
    }

    NSString *batchId = (NSString*)[NSURLProtocol propertyForKey:@"kBatchId" inRequest:task.originalRequest];
    NSLog(@"request batch id: %@", (batchId) ? batchId : @"batch id property missing");

    if (error) {
        NSLog(@"got error code %ld", (long)[error code]);

        // from Apple docs:
        /* 
         If the task failed, most apps should retry the request until either the user cancels the download 
         or the server returns an error indicating that the request will never succeed. 
         Your app should not retry immediately, however. Instead, it should use reachability APIs to 
         determine whether the server is reachable, and should make a new request only when it 
         receives a notification that reachability has changed.
        */
        switch ([error code]) {
            case NSURLErrorUserCancelledAuthentication:
            case NSURLErrorUserAuthenticationRequired:
                NSLog(@"Authentication error");
//                [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_UPLOAD_AUTH_FAILED object:self];
                break;
            default:
                NSLog(@"Unknown server error");
//                [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_UPLOAD_NETWORK_ERROR object:self];
                // TODO: try to re-queue this request?
                break;
        }
    }
    else {
        NSLog(@"success with HTTP status %ld", (long)statusCode);
//        [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_UPLOAD_SUCCEEDED object:self];

        // and then? tell any callers about the result?
        // this only matters if the app has not crashed or been terminated and there is still an
        // in-memory samples 'database' to update.
    }

    // I think we always want to clean up...regardless if there was an error.
    // if we get an authentication challenge...I believe that a different callback will occur.
    if (fileURL) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *fileError = nil;
        BOOL result = [fm removeItemAtURL:fileURL error:&fileError];
        if (!result) {
            NSLog(@"error removing temporary upload file: %@", [fileError localizedDescription]);
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // regardless of what has happened...the task is done...remove it from the dictionary
        [self.taskDictionary removeObjectForKey:taskKey];
        [self updateTaskDictionary];

        [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    });

    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    // store this in our request tracking object / persistent store?
    NSString *taskKey = [@(dataTask.taskIdentifier) stringValue];
    NSString *responsePayload = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (responsePayload) {
        NSMutableDictionary *taskMetaData = [self.taskDictionary[taskKey] mutableCopy];
        if (taskMetaData) {
            NSMutableString *existingData = [[taskMetaData objectForKey:kTaskResponseDataKey] mutableCopy];
            if (existingData) {
                [existingData appendString:responsePayload];
            }
            else {
                existingData = [NSMutableString stringWithString:responsePayload];
            }
            [taskMetaData setObject:existingData forKey:kTaskResponseDataKey];

            dispatch_async(dispatch_get_main_queue(), ^{
                // replace this updated object:
                [self.taskDictionary setObject:taskMetaData forKey:taskKey];
                [self updateTaskDictionary];
            });
        }
    }
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, responsePayload);
}


#pragma mark - Methods
-(BOOL)queueUploadRequest:(NSURLRequest*)request withData:(NSData*)payload;
{
    // write json to a (temporary) file?
    NSString *uidString = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", uidString, @"samples.bin"];
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    BOOL status = [payload writeToURL:fileURL atomically:YES];
    if(!status) { return NO; }

    NSMutableURLRequest *mutableRequest = [request mutableCopy];

    // can we use the URLProtocol class method to attach additional data?
    // this will be carried along by the task.
    [NSURLProtocol setProperty:uidString forKey:@"kBatchId" inRequest:mutableRequest];

    NSURLSessionUploadTask *task = [[self backgroundSession] uploadTaskWithRequest:mutableRequest
                                                                          fromFile:fileURL];
    // maybe we don't need to rely on the taskDictionary if we can embed the identifier here?
    // although, this is intended to be a user-facing string, according to docs.
    task.taskDescription = uidString;


    dispatch_async(dispatch_get_main_queue(), ^{
        // TODO: store this task (identifier), the file handle, and optionally any follow-up work.
        [self.taskDictionary setObject:@{kTaskTemporaryFileNameKey: fileName} forKey:[@(task.taskIdentifier) stringValue]];
        [self updateTaskDictionary];
    });

    // does this resume have to happen *after* the taskDictionary has been modified?
    [task resume];
    return YES;
}

@end
