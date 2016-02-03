//
//  AudioDSP.h
//  AudioDSP
//
//  Created by Eric on 1/10/16.
//  Copyright © 2016 Eric. All rights reserved.
//

#ifndef AudioDSP_h
#define AudioDSP_h

#import <Foundation/Foundation.h>

#define DSP_SAMPLING_RATE       8000
#define DSP_FRAME_SIZE          160         //PCM Frame Size
#define DSP_FRAME_TAIL          16000*0.3

@interface AudioDSP : NSObject

- (void)start;
- (void)stop;

- (void) doAEC:(UInt16*)micBuffer
 speakerBuffer:(UInt16*)speakerBuffer
     outBuffer:(UInt16*)outBuffer;

@end

#endif /* AudioDSP_h */
