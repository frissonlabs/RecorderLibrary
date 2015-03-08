//
//  Recorder.m
//  Recorder
//
//  Created by David Li on 2/8/15.
//  Copyright (c) 2015 Euphonia Labs. All rights reserved.
//

#import "Recorder.h"
#import "AudioManager.h"

static Recorder *recorder = nil;

@interface Recorder (){
    AudioManager *audioManager;
}

@end
@implementation Recorder

#pragma mark - Singleton Methods
+ (Recorder *) recorder
{
    @synchronized(self)
    {
        if (recorder == nil) {
            recorder = [[Recorder alloc] init];
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
