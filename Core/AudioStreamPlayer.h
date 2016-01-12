//
//  AudioStreamPlayer.h
//  AudioDSP
//
//  Created by Eric on 1/10/16.
//  Copyright © 2016 Eric. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AudioStreamBase.h"

@protocol AudioStreamPlayerDelegate <NSObject>

@required
- (void)fillBuffer:(AudioQueueBufferRef)inBuffer;
@end

@interface AudioStreamPlayer :NSObject <AudioStreamBase>

@property(nonatomic,assign)id delegate;
@property(nonatomic,assign)Boolean isRunning;

- (void)setupAudioFormat:(AudioStreamBasicDescription*)format;
- (void)start;
- (void)stop;

@end
