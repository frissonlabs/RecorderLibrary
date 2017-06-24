#import <CoreFoundation/CoreFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Accelerate/Accelerate.h>
#include <AVFoundation/AVFoundation.h>

FOUNDATION_EXTERN void CheckError(OSStatus error, const char *operation);

@interface AudioManager : NSObject

// these should be readonly in public interface - no need for public write access
@property (nonatomic, assign, readonly) AudioUnit audioUnit;
@property (nonatomic, assign, readonly) UInt32 numChannels;
@property (nonatomic, assign, readonly) BOOL isInterleaved;
@property (nonatomic, assign, readonly) float *inData;

// Singleton methods
+ (AudioManager *) audioManager;

// Audio Unit methods
- (void)start;
- (void)stop;

@end
