//
//  AudioStreamBase.h
//  AudioDSP
//
//  Created by Eric on 1/10/16.
//  Copyright © 2016 Eric. All rights reserved.
//

#ifndef AudioStreamBase_h
#define AudioStreamBase_h

#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFile.h>

#define NUM_BUFFERS 10

#define PAYLOAD_TIME 20

typedef struct
{
    AudioStreamBasicDescription dataFormat;
    AudioQueueRef               queue;
    AudioQueueBufferRef         buffers[NUM_BUFFERS];
    AudioFileID                 audioFile;
    SInt64                      currentPacket;
    bool                        running;
}RecordState;

@protocol AudioStreamBase <NSObject>

@required
- (void)setupAudioFormat:(AudioStreamBasicDescription*)format;

- (void)start;
- (void)stop;
@end

#endif /* AudioStreamBase_h */
