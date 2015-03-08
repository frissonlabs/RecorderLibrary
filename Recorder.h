//
//  Recorder.h
//  Recorder
//
//  Created by David Li on 2/8/15.
//  Copyright (c) 2015 Euphonia Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Recorder : NSObject

+ (Recorder *) recorder;

-(id) init;
-(void) startRecording;
-(void) stopRecording;
-(float*) readSamples;

@end
