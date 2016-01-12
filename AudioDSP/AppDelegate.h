//
//  AppDelegate.h
//  AudioDSP
//
//  Created by Eric on 1/10/16.
//  Copyright © 2016 Eric. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AudioStreamPlayer.h"
#import "AudioStreamRecorder.h"
#import "GCDAsyncUdpSocket.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, AudioStreamPlayerDelegate, AudioStreamRecorderDelegate, GCDAsyncUdpSocketDelegate>

@property (strong, nonatomic) UIWindow *window;


- (void) start:(NSString*)strIP;
- (void) stop;

- (NSString *)getLocalIPAddress;

@end

