#import "AudioManager.h"
#define kOutputBus 0
#define kInputBus 1

#define SAMPLE_RATE 16000.00

#ifdef __cplusplus
extern "C" {
#endif
    
    void CheckError(OSStatus error, const char *operation)
    {
        if (error == noErr) return;
        
        char str[20];
        // see if it appears to be a 4-char-code
        *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
        if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
            str[0] = str[5] = '\'';
            str[6] = '\0';
        } else
            // no, format it as an integer
            sprintf(str, "%d", (int)error);
        
        fprintf(stderr, "Error: %s (%s)\n", operation, str);
        
        exit(1);
    }
    
    
    OSStatus inputCallback (void						*inRefCon,
                            AudioUnitRenderActionFlags	* ioActionFlags,
                            const AudioTimeStamp 		* inTimeStamp,
                            UInt32						inOutputBusNumber,
                            UInt32						inNumberFrames,
                            AudioBufferList				* ioData);
#ifdef __cplusplus
}
#endif

static AudioManager *audioManager = nil;

@interface AudioManager()

@property (nonatomic, assign, readwrite) AudioUnit audioUnit;
@property (nonatomic, assign, readwrite) UInt32 numChannels;
@property (nonatomic, assign, readwrite) BOOL isInterleaved;
@property (nonatomic, assign, readwrite) float *inData;

- (void)setupAudioSession;
- (void)setupAudioUnits;

@end

@implementation AudioManager

+ (AudioManager *)audioManager
{
    @synchronized(self)
    {
        if (audioManager == nil) {
            audioManager = [[AudioManager alloc] init];
        }
    }
    return audioManager;
    
}

- (id)init
{
    if (self = [super init])
    {
        self.inData  = (float *)calloc(512, sizeof(float));
        [self setupAudioSession];
        [self setupAudioUnits];
        return self;
    }
    return nil;
}


- (void)dealloc
{
    free(self.inData);
}

#pragma mark - Audio Methods
- (void)setupAudioSession
{
    NSError *err = nil;
    if (![[AVAudioSession sharedInstance] setActive:YES error:&err]){
        NSLog(@"Couldn't activate audio session: %@", err);
    }
}

-(void)setupAudioUnits
{
    // --- Audio Session Setup ---
    // ---------------------------
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    

    
    Float32 preferredBufferSize = 0.0232;
    CheckError( AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize), "Couldn't set the preferred buffer duration");
    
    // We define the audio component
    AudioComponentDescription desc = {0};
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // find the AU component by description
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    CheckError( AudioComponentInstanceNew(inputComponent, &_audioUnit), "Couldn't create the output audio unit");
    
    // define that we want record io on the input bus
    UInt32 one = 1;
    CheckError( AudioUnitSetProperty(_audioUnit,
                                     kAudioOutputUnitProperty_EnableIO,
                                     kAudioUnitScope_Input,
                                     kInputBus,
                                     &one,
                                     sizeof(one)), "Couldn't enable IO on the input scope of output unit");
    
    /*
     We need to specifie our format on which we want to work.
     We use Linear PCM cause its uncompressed and we work on raw data.
     for more informations check.
     
     We want 16 bits, 2 bytes per packet/frames at 44khz
     */
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate			= SAMPLE_RATE;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 1;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 2;
    audioFormat.mBytesPerFrame		= 2;
    
    self.numChannels = audioFormat.mChannelsPerFrame;
    
    // set the format on the output stream
    UInt32 size = sizeof(AudioStreamBasicDescription);
    CheckError(AudioUnitSetProperty(_audioUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    kInputBus,
                                    &audioFormat,
                                    size),
               "Couldn't set the ASBD on the audio unit (after setting its sampling rate)");
    
    if (audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved) {
        // The audio is non-interleaved
        printf("Not interleaved!\n");
        self.isInterleaved = NO;
    } else {
        printf ("Format is interleaved\n");
        self.isInterleaved = YES;
    }
    
    /**
     We need to define a callback structure which holds
     a pointer to the recordingCallback and a reference to
     the audio processor object
     */
    AURenderCallbackStruct callbackStruct;

    // set recording callback
    callbackStruct.inputProc = inputCallback; // recordingCallback pointer
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    // set input callback to recording callback on the input bus
    CheckError( AudioUnitSetProperty(_audioUnit,
                                     kAudioOutputUnitProperty_SetInputCallback,
                                     kAudioUnitScope_Global,
                                     0,
                                     &callbackStruct,
                                     sizeof(callbackStruct)), "Couldn't set the callback on the input unit");
    
    CheckError(AudioUnitInitialize(_audioUnit), "Couldn't initialize the output unit");
    
    NSLog(@"Initialized.");
}

#pragma mark controll stream

- (void)stop {
    CheckError( AudioOutputUnitStop(_audioUnit), "Couldn't stop the output unit");
}

- (void)start {
    CheckError( AudioOutputUnitStart(_audioUnit), "Couldn't start the output unit");
}

OSStatus inputCallback   (void						*inRefCon,
                          AudioUnitRenderActionFlags	* ioActionFlags,
                          const AudioTimeStamp 		* inTimeStamp,
                          UInt32						inOutputBusNumber,
                          UInt32						inNumberFrames,
                          AudioBufferList			* ioData)
{
    @autoreleasepool {
        
        // the data gets rendered here
        AudioBuffer buffer;
        
        /**
         This is the reference to the object who owns the callback.
         */
        AudioManager *audioManager = (__bridge AudioManager*) inRefCon;
        
        /**
         on this point we define the number of channels, which is mono
         for the iphone. the number of frames is usally 512 or 1024.
         */
        buffer.mDataByteSize = inNumberFrames * 2; // sample size
        buffer.mNumberChannels = 1; // one channel
        buffer.mData = malloc( inNumberFrames * 2 ); // buffer size
        
        // we put our buffer into a bufferlist array for rendering
        AudioBufferList bufferList;
        bufferList.mNumberBuffers = 1;
        bufferList.mBuffers[0] = buffer;
        
        // render input and check for error
        CheckError( AudioUnitRender([audioManager audioUnit], ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, &bufferList), "Couldn't render the output unit");

        
        // Convert the audio in something manageable
        
        // For SInt16s ...
        if ( ! audioManager.isInterleaved ) {
            for (int i=0; i < audioManager.numChannels; ++i) {
                vDSP_vflt16((SInt16 *)bufferList.mBuffers[i].mData, 1, audioManager.inData+i, audioManager.numChannels, inNumberFrames);
            }
        }
        else {
            vDSP_vflt16((SInt16 *)bufferList.mBuffers[0].mData, 1, audioManager.inData, 1, inNumberFrames*audioManager.numChannels);
        }
        
        float scale = 1.0 / (float)INT16_MAX;
        vDSP_vsmul(audioManager.inData, 1, &scale, audioManager.inData, 1, inNumberFrames*audioManager.numChannels);
        
        // clean up the buffer
        free(bufferList.mBuffers[0].mData);
        
        return noErr;
    }
}

@end
