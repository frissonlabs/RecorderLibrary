//
//  Recorder.m
//  Recorder
//
//  Created by David Li on 2/8/15.
//  Copyright (c) 2015 Euphonia Labs. All rights reserved.
//

#import "IOSRecorder.h"
#import "AudioManager.h"

static IOSRecorder *recorder = nil;

@interface IOSRecorder (){
    AudioManager *audioManager;
}

@end
@implementation IOSRecorder

#pragma mark - Singleton Methods
+ (IOSRecorder *) recorder
{
    @synchronized(self)
    {
        if (recorder == nil) {
            recorder = [[IOSRecorder alloc] init];
        }
    }
    return recorder;
}

-(id) init{
    self = [super init];
    return self;
}

-(void) startRecording
{
    if (audioManager == nil) {
        audioManager = [AudioManager audioManager];
    }
    [audioManager start];
}

-(void) stopRecording
{
    [audioManager stop];
}

-(float *) readSamples
{
    return audioManager.inData;
}

@end
