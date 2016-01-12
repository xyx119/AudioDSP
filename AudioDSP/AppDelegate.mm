//
//  AppDelegate.m
//  AudioDSP
//
//  Created by Eric on 1/10/16.
//  Copyright © 2016 Eric. All rights reserved.
//

#import "AppDelegate.h"
#import "AudioStreamRecorder.h"
#import "AudioDSP.h"
#include "RingBuffer.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

#define UDP_TRANSLAYER_PORT         8878
#define ECHO_DELAY_OPTIONAL         10

@interface AppDelegate (){
    RingBuffer<UInt16>  *_playerBuffer;
    AudioStreamRecorder *_recorder;
    AudioStreamPlayer   *_player;
    AudioDSP            *_audioDSP;
    RingBuffer<UInt16>  *_echoBuffer;
    
    long                _tag;
    GCDAsyncUdpSocket   *_udpSocket;
    NSString            *_remoteIPAddress;
}

@end

@implementation AppDelegate

- (id) init{
    if (self = [super init]){
        
        _playerBuffer       = new RingBuffer<UInt16>(160*50*5);
        _echoBuffer         = new RingBuffer<UInt16>(160*50);
        _audioDSP           = [[AudioDSP alloc] init];
        
        _recorder           = [[AudioStreamRecorder alloc] init];
        _recorder.delegate  = self;
        
        _player             = [[AudioStreamPlayer alloc] init];
        _player.delegate    = self;
        
    }
    
    return self;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [self _setupSocket];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark --- Audio Stream's delegate.

- (void)fillBuffer:(AudioQueueBufferRef)inBuffer{
    int count = inBuffer->mAudioDataByteSize / sizeof(UInt16);
    UInt16* pdata = (UInt16*)inBuffer->mAudioData;
    
    for ( int i = 0; i < count; i++) {
        _playerBuffer->empty() ? pdata[i] = 0 : _playerBuffer->pop(pdata[i]);
    }
    
    NSLog(@"<--- fillBuffer ...");
}

- (void)feedSamples:(UInt32)audioDataBytesCapacity audioData:(void *)audioData{
    int sampleCount         = audioDataBytesCapacity / sizeof(UInt16);
    UInt16 *samples         = (UInt16*)audioData;
    
    UInt16 *speakerBuffer   = new UInt16[sampleCount];
    UInt16 *outBuffer       = new UInt16[sampleCount];
    bzero(speakerBuffer, sampleCount);
    bzero(outBuffer, sampleCount);
    
    for ( int i = 0; i < sampleCount; i++) {
        _echoBuffer->pop(speakerBuffer[i]);
    }
    
    [_audioDSP doAEC:samples speakerBuffer:speakerBuffer outBuffer:outBuffer];
    

//    for ( int i = 0; i < sampleCount; i++) {
//        _playerBuffer->push(samples[i]);
//    }
    
    if ([_remoteIPAddress length] > 0){
        NSData *data = [NSData dataWithBytes:outBuffer length:audioDataBytesCapacity];
        [_udpSocket sendData:data
                      toHost:_remoteIPAddress
                        port:UDP_TRANSLAYER_PORT
                 withTimeout:-1
                         tag:_tag++];
    }
    
    delete[] speakerBuffer;
    delete[] outBuffer;
    
    NSLog(@"---> feedSamples ###");
}

#pragma mark --- UDP socket

- (void)_setupSocket
{
    
    _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    
    if (![_udpSocket bindToPort:8878 error:&error])
    {
        NSLog(@"Error binding: %@", error);
        return;
    }
    if (![_udpSocket beginReceiving:&error])
    {
        NSLog(@"Error receiving: %@", error);
        return;
    }
    
    NSLog(@"Ready");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    // You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    // You could add checks here
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    if (!_player.isRunning) return;

    NSString *host = nil;
    uint16_t port = 0;
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
    NSLog(@"RECV: message from: %@:%hu", host, port);
    
    UInt16 count =  [data length] / sizeof(UInt16);

    UInt16 temp = 0;
    for ( int i = 0; i < count; i++) {
        [data getBytes:&temp range: NSMakeRange(i*sizeof(UInt16), sizeof(UInt16))];
        _playerBuffer->push(temp);
        temp = 0;
    }
    
    static UInt16 nop = 0;
    if (nop++ == 0){
        for (int n = 0; n < ECHO_DELAY_OPTIONAL; n++){
            for ( int i = 0; i < count; i++) {
                [data getBytes:&temp range: NSMakeRange(i*sizeof(UInt16), sizeof(UInt16))];
                _echoBuffer->push(temp);
                temp = 0;
            }
        }
    }
    else if (nop == ECHO_DELAY_OPTIONAL){
        nop = 0;
    }
}

#pragma mark --- Outer interfaces

- (void) start:(NSString*)strIP{
    _tag = 0;
    
//    UInt16 size = DSP_FRAME_TAIL/sizeof(UInt16);
//    UInt16 empty = 0;
//    for (int i=0; i< size; i++) {
//        _echoBuffer->push(empty);
//    }
    
    _remoteIPAddress = [[NSString alloc] initWithString:strIP];
    [_audioDSP start];
    [_player start];
    [_recorder start];
}

- (void) stop{
    [_audioDSP stop];
    [_recorder stop];
    [_player stop];
    
    _echoBuffer->reset();
    _playerBuffer->reset();
}

- (NSString *)getLocalIPAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

@end
