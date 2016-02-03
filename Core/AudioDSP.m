//
//  AudioDSP.m
//  AudioDSP
//
//  Created by Eric on 1/10/16.
//  Copyright © 2016 Eric. All rights reserved.
//

#import "AudioDSP.h"

#include "speex_echo.h"
#include "speex_preprocess.h"

@interface AudioDSP (){
    SpeexEchoState          *ses;
    SpeexPreprocessState    *sps;
    
    UInt32                  sampleRate;
    Boolean                 isRunning;
}
@end



@implementation AudioDSP

- (id)init
{
    if (self = [super init]) {
        sampleRate = DSP_SAMPLING_RATE;
        isRunning = false;
    }
    return self;
}


- (void)start{
    ses = speex_echo_state_init(DSP_FRAME_SIZE, DSP_FRAME_TAIL);
    sps = speex_preprocess_state_init(DSP_FRAME_SIZE, sampleRate);
    
    speex_echo_ctl(ses, SPEEX_ECHO_SET_SAMPLING_RATE, &sampleRate);
    
//    int denoise = 1;
//    int noiseSuppress = -5;
//    speex_preprocess_ctl(sps, SPEEX_PREPROCESS_SET_DENOISE, &denoise);// 降噪
//    speex_preprocess_ctl(sps, SPEEX_PREPROCESS_SET_NOISE_SUPPRESS, &noiseSuppress);// 噪音分贝数
    
//    int agc = 1;
//    int level = 24000;
//    //actually default is 8000(0,32768),here make it louder for voice is not loudy enough by default.
//    speex_preprocess_ctl(sps, SPEEX_PREPROCESS_SET_AGC, &agc);// 增益
//    speex_preprocess_ctl(sps, SPEEX_PREPROCESS_SET_AGC_LEVEL,&level);// 增益后的值
    
    
    speex_preprocess_ctl(sps, SPEEX_PREPROCESS_SET_ECHO_STATE, ses);
    isRunning = TRUE;
}

- (void)stop{
    isRunning = FALSE;
    speex_echo_state_destroy(ses);
    speex_preprocess_state_destroy(sps);
}

- (void) doAEC:(UInt16*)micBuffer speakerBuffer:(UInt16*)speakerBuffer outBuffer:(UInt16*)outBuffer
{
    if (!isRunning) return;
    
    speex_echo_cancellation(ses, (spx_int16_t*)micBuffer,
                            ((spx_int16_t*)speakerBuffer),
                            (spx_int16_t*)outBuffer);
    
    speex_preprocess_run(sps, (spx_int16_t*)outBuffer);
}
@end