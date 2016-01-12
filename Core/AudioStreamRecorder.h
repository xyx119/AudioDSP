//
//  AudioStreamRecorder.h
//  AudioDSP
//
//  Created by Eric on 1/10/16.
//  Copyright © 2016 Eric. All rights reserved.
//

#ifndef AudioStreamRecorder_h
#define AudioStreamRecorder_h

#import "AudioStreamBase.h"

@protocol AudioStreamRecorderDelegate <NSObject>

@required
- (void)feedSamples:(UInt32)audioDataBytesCapacity audioData:(void *)audioData;
@end


@interface AudioStreamRecorder : NSObject <AudioStreamBase>

@property(nonatomic,assign)id delegate;

- (void)setupAudioFormat:(AudioStreamBasicDescription*)format;
- (void)start;
- (void)stop;

@end


#endif /* AudioStreamRecorder_h */
