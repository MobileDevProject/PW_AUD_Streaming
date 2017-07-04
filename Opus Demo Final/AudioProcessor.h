//
//  AudioProcessor.h
//  MicInput
//
//  Created by Stefan Popp on 21.09.11.
//  Copyright 2011 http://http://www.stefanpopp.de/2011/capture-iphone-microphone//2011/capture-iphone-microphone/ . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CSIOpusEncoder.h"
#import "CSIOpusDecoder.h"
#import "ViewController.h"
#import "TCPSocketChat.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

// return max value for given values
#define max(a, b) (((a) > (b)) ? (a) : (b))
// return min value for given values
#define min(a, b) (((a) < (b)) ? (a) : (b))

#define kOutputBus 0
#define kInputBus 1

// our default sample rate
#define SAMPLE_RATE 8000.00


@protocol socketDemo <NSObject>

-(void)connectionStatus:(NSString *)status;

@end


@interface AudioProcessor : NSObject
{
    // Audio unit
    AudioComponentInstance audioUnit;
    
    // Audio buffers
	AudioBuffer audioBuffer;
    
    // gain
    float gain;
}

@property (nonatomic,retain) id<socketDemo> delegate;


@property (readonly) AudioBuffer audioBuffer;
@property (readonly) AudioComponentInstance audioUnit;
@property (nonatomic) float gain;

@property (nonatomic) NSInteger audioType;
@property (strong) NSString *strPort;
@property (strong) NSString *strIp;


@property (strong,nonatomic) NSMutableData *dataAudioTemp;


@property (strong) CSIOpusEncoder *encoder;
@property (strong) CSIOpusDecoder *decoder;
@property (strong) dispatch_queue_t decodeQueue;
@property (nonatomic,strong) TCPSocketChat* chatSocket;

@property (nonatomic,strong) NSMutableData *dataAudioBytes;
@property (nonatomic,strong) NSMutableData *dataEncodeServerBytes;
@property (nonatomic,strong) NSMutableData *dataReceiveAudioBytes;
@property (assign) AudioBufferList *ioData;

-(AudioProcessor*)init;

-(void)initializeAudio;
-(void)processBuffer: (AudioBufferList*) audioBufferList;

// control object
-(void)start;
-(void)stop;


// Socket
- (void)connect;
- (void)disconnect;
-(void)playAudioInQueue;



// gain
-(void)setGain:(float)gainValue;
-(float)getGain;

// error managment
-(void)hasError:(int)statusCode:(char*)file:(int)line;



@end
