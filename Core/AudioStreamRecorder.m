//
//  AudioStreamRecorder.m
//  AudioDSP
//
//  Created by Eric on 1/10/16.
//  Copyright © 2016 Eric. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioStreamRecorder.h"

static AudioStreamRecorder *refToSelf = nil;

static void AudioInputCallback(void * inUserData,  // Custom audio metadata
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumberPacketDescriptions,
                        const AudioStreamPacketDescription * inPacketDescs) {
    
    RecordState * recordState = (RecordState*)inUserData;
    
    if([refToSelf.delegate respondsToSelector:@selector(feedSamples:audioData:)])
    {
        [refToSelf.delegate feedSamples:inBuffer->mAudioDataBytesCapacity audioData:inBuffer->mAudioData];
    }
    
    AudioQueueEnqueueBuffer(recordState->queue, inBuffer, 0, NULL);
}


@interface AudioStreamRecorder(){
    RecordState recordState;
}
@end

@implementation AudioStreamRecorder

- (id)init
{
    self = [super init];
    if (self) {
        refToSelf = self;
    }
    return self;
}

- (void)setupAudioFormat:(AudioStreamBasicDescription*)format {
    format->mSampleRate         = 8000.0;
    format->mFormatID           = kAudioFormatLinearPCM;
    format->mFormatFlags        = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    format->mFramesPerPacket    = 1;
    format->mChannelsPerFrame   = 1;
    format->mBitsPerChannel     = 16;
    format->mBytesPerFrame      = (format->mBitsPerChannel/8) * format->mChannelsPerFrame;
    format->mBytesPerPacket     = format->mBytesPerFrame * format->mFramesPerPacket;
}

- (void)start {
    
    [self setupAudioFormat:&recordState.dataFormat];
    UInt32 bufersize =  recordState.dataFormat.mSampleRate * recordState.dataFormat.mBytesPerFrame * PAYLOAD_TIME/1000;
    recordState.currentPacket = 0;
    
    OSStatus status = AudioQueueNewInput(&recordState.dataFormat,
                                AudioInputCallback,
                                &recordState,
                                NULL,
                                NULL,
                                0,
                                &recordState.queue);
    
    if (status == 0) {
        
        for (int i = 0; i < NUM_BUFFERS; i++) {
            AudioQueueAllocateBuffer(recordState.queue, bufersize, &recordState.buffers[i]);
            
            bzero(recordState.buffers[i]->mAudioData, bufersize);
            recordState.buffers[i]->mAudioDataByteSize = bufersize;
            
            AudioQueueEnqueueBuffer(recordState.queue, recordState.buffers[i], 0, nil);
        }
        
        recordState.running = true;
        
        status = AudioQueueStart(recordState.queue, NULL);
    }
}

- (void)stop {
    recordState.running = false;
    
    AudioQueueStop(recordState.queue, true);
    
    for (int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueFreeBuffer(recordState.queue, recordState.buffers[i]);
    }
    
    AudioQueueDispose(recordState.queue, true);
    AudioFileClose(recordState.audioFile);
}

@end