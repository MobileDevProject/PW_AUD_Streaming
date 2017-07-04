//
//  AudioProcessor.m
//  MicInput
//
//  Created by Stefan Popp on 21.09.11.
//  Copyright 2011 http://www.stefanpopp.de/2011/capture-iphone-microphone/ . All rights reserved.
//

#import "AudioProcessor.h"

#pragma mark Recording callback

static OSStatus recordingCallback(void *inRefCon, 
                                  AudioUnitRenderActionFlags *ioActionFlags, 
                                  const AudioTimeStamp *inTimeStamp, 
                                  UInt32 inBusNumber, 
                                  UInt32 inNumberFrames, 
                                  AudioBufferList *ioData) {
	
	// the data gets rendered here
    AudioBuffer buffer;
    
    // a variable where we check the status
    OSStatus status;
    
    /**
     This is the reference to the object who owns the callback.
     */
    AudioProcessor *audioProcessor = (__bridge AudioProcessor*) inRefCon;   
    
    /**
     on this point we define the number of channels, which is mono
     for the iphone. the number of frames is usally 512 or 1024.
     */
    buffer.mDataByteSize = inNumberFrames * 2; // sample size
    buffer.mNumberChannels = 1; // one channel
	buffer.mData = malloc( inNumberFrames * 2 ); // buffer size
	
    // we put our buffer into a bufferlist array for rendering
	AudioBufferList bufferList;
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0] = buffer;
    
    //================== Encode Process =========================
    
    if(audioProcessor.audioType == 1 || audioProcessor.audioType == 2)
    {
     
        NSData *localAudioBytes = [NSData dataWithBytes:bufferList.mBuffers[0].mData length:bufferList.mBuffers[0].mDataByteSize];

        //================== Audio Bytes Append Here! =========================
        
           [audioProcessor.dataAudioBytes appendData:localAudioBytes];
        
        //=====================================================================
        
        if ([audioProcessor.dataAudioBytes length] > 1250)
        {
            
            //====================== Get Audio bytes ========================
            
            NSData *bytes372 = [audioProcessor.dataAudioBytes subdataWithRange:NSMakeRange(0, 372)];
            
            //===============================================================
            
            //====================== Remove Audio 372 bytes =================
            
            NSRange remove372Bytes = NSMakeRange(372, [audioProcessor.dataAudioBytes length] - 372);
            NSData *remainingBytes = [audioProcessor.dataAudioBytes subdataWithRange:remove372Bytes];
            audioProcessor.dataAudioBytes = [[NSMutableData alloc]initWithData:remainingBytes];
            
            //===============================================================
            
            //====================== Update AudioBufferList =================
            
            NSUInteger len = [bytes372 length];
            Byte *byteData = (Byte*)malloc(len);
            memcpy(byteData, [bytes372 bytes], len);
        
            buffer.mDataByteSize = bufferList.mBuffers[0].mDataByteSize; // sample size
            buffer.mNumberChannels = bufferList.mBuffers[0].mNumberChannels; // one channel
            buffer.mData = byteData; // buffer size

            
            bufferList.mNumberBuffers = 1;
            bufferList.mBuffers[0] = bufferList.mBuffers[0];
            //===============================================================
            
            // render input and check for error
            status = AudioUnitRender([audioProcessor audioUnit], ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
            [audioProcessor hasError:status:__FILE__:__LINE__];
            
            [audioProcessor processBuffer:&bufferList];
            
            
        }
    }
    else if (audioProcessor.audioType == 0)
    {
        // render input and check for error
        status = AudioUnitRender([audioProcessor audioUnit], ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
        [audioProcessor hasError:status:__FILE__:__LINE__];
        
        // process the bufferlist in the audio processor
        [audioProcessor processBuffer:&bufferList];
    }

	
    // clean up the buffer
	free(bufferList.mBuffers[0].mData);
	
    return noErr;
}

#pragma mark Playback callback

static OSStatus playbackCallback(void *inRefCon, 
								 AudioUnitRenderActionFlags *ioActionFlags, 
								 const AudioTimeStamp *inTimeStamp, 
								 UInt32 inBusNumber, 
								 UInt32 inNumberFrames, 
								 AudioBufferList *ioData) {    

    /**
     This is the reference to the object who owns the callback.
     */
    
    AudioProcessor *audioProcessor = (__bridge AudioProcessor*) inRefCon;

    
    if (audioProcessor.audioType == 0)
    {
        //Local
     
            AudioProcessor *audioProcessor = (__bridge AudioProcessor*) inRefCon;
        
            // iterate over incoming stream an copy to output stream
        	for (int i=0; i < ioData->mNumberBuffers; i++) {
        		AudioBuffer buffer = ioData->mBuffers[i];
        
                // find minimum size
        		UInt32 size = min(buffer.mDataByteSize, [audioProcessor audioBuffer].mDataByteSize);
                
                // copy buffer to audio buffer which gets played after function return
        		memcpy(buffer.mData, [audioProcessor audioBuffer].mData, size);
                
                // set data size
        		buffer.mDataByteSize = size; 
            }

    }
    else if (audioProcessor.audioType == 1)
    {
        //Encode
        int bytesFilled = [audioProcessor.decoder tryFillBuffer:ioData];
        
        if(bytesFilled <= 0)
        {

        // iterate over incoming stream an copy to output stream
        for (int i=0; i < ioData->mNumberBuffers; i++) {
            AudioBuffer buffer = ioData->mBuffers[i];

            // find minimum size
            UInt32 size = min(buffer.mDataByteSize, [audioProcessor audioBuffer].mDataByteSize);

            // copy buffer to audio buffer which gets played after function return
            memcpy(buffer.mData, [audioProcessor audioBuffer].mData, size);

            // set data size
            buffer.mDataByteSize = size;
        }
      }
    }
    else if (audioProcessor.audioType == 2)
    {
        
        //Socket
        [audioProcessor playAudioInQueue];
        
        //Encode
        int bytesFilled = [audioProcessor.decoder tryFillBuffer:ioData];
        
        if(bytesFilled <= 0)
        {
            
            // iterate over incoming stream an copy to output stream
            for (int i=0; i < ioData->mNumberBuffers; i++) {
                AudioBuffer buffer = ioData->mBuffers[i];
                
                // find minimum size
                UInt32 size = min(buffer.mDataByteSize, [audioProcessor audioBuffer].mDataByteSize);
                
                // copy buffer to audio buffer which gets played after function return
                memcpy(buffer.mData, [audioProcessor audioBuffer].mData, size);
                
                // set data size
                buffer.mDataByteSize = size;
            }
        }
    }
    
    return noErr;
}

#pragma mark objective-c class

@implementation AudioProcessor
@synthesize audioUnit, audioBuffer, gain,audioType,dataAudioBytes,dataEncodeServerBytes,dataReceiveAudioBytes;

-(AudioProcessor*)init
{
    self = [super init];
    if (self) {
        gain = 0;
        [self initializeAudio];
        [self setupEncoder];
        [self setupDecoder];
        
        dataAudioBytes = [[NSMutableData alloc]init];
        dataEncodeServerBytes = [[NSMutableData alloc]init];
        dataReceiveAudioBytes = [[NSMutableData alloc]init];
    }
    return self;
}

#pragma makr - Encoder Decoder
- (void)setupEncoder
{
    self.encoder = [CSIOpusEncoder encoderWithSampleRate:SAMPLE_RATE channels:1 frameDuration:0.01];
}

- (void)setupDecoder
{
    self.decoder = [CSIOpusDecoder decoderWithSampleRate:SAMPLE_RATE channels:1 frameDuration:0.01];
    self.decodeQueue = dispatch_queue_create("Decode Queue", nil);
}


-(void)initializeAudio
{    
    OSStatus status;
	
	// We define the audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output; // we want to ouput
	desc.componentSubType = kAudioUnitSubType_RemoteIO; // we want in and ouput
	desc.componentFlags = 0; // must be zero
	desc.componentFlagsMask = 0; // must be zero
	desc.componentManufacturer = kAudioUnitManufacturer_Apple; // select provider
	
	// find the AU component by description
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// create audio unit by component
	status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    
	[self hasError:status:__FILE__:__LINE__];
	
    // define that we want record io on the input bus
    UInt32 flag = 1;
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, // use io
								  kAudioUnitScope_Input, // scope to input
								  kInputBus, // select input bus (1)
								  &flag, // set flag
								  sizeof(flag));
	[self hasError:status:__FILE__:__LINE__];
	
	// define that we want play on io on the output bus
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_EnableIO, // use io
								  kAudioUnitScope_Output, // scope to output
								  kOutputBus, // select output bus (0)
								  &flag, // set flag
								  sizeof(flag));
	[self hasError:status:__FILE__:__LINE__];
	
	/* 
     We need to specifie our format on which we want to work.
     We use Linear PCM cause its uncompressed and we work on raw data.
     for more informations check.
     
     We want 16 bits, 2 bytes per packet/frames at 44khz 
     */
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate			= SAMPLE_RATE;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 1;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
    
    
	// set the format on the output stream
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Output, 
								  kInputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
    
	[self hasError:status:__FILE__:__LINE__];
    
    // set the format on the input stream
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Input, 
								  kOutputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	[self hasError:status:__FILE__:__LINE__];
	
	
	
    /**
        We need to define a callback structure which holds
        a pointer to the recordingCallback and a reference to
        the audio processor object
     */
	AURenderCallbackStruct callbackStruct;
    
    // set recording callback
	callbackStruct.inputProc = recordingCallback; // recordingCallback pointer
	callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);

    // set input callback to recording callback on the input bus
	status = AudioUnitSetProperty(audioUnit, 
                                  kAudioOutputUnitProperty_SetInputCallback, 
								  kAudioUnitScope_Global, 
								  kInputBus, 
								  &callbackStruct, 
								  sizeof(callbackStruct));
    
    [self hasError:status:__FILE__:__LINE__];
	
    /*
     We do the same on the output stream to hear what is coming
     from the input stream
     */
	callbackStruct.inputProc = playbackCallback;
	callbackStruct.inputProcRefCon = (__bridge void * _Nullable)(self);
    
    // set playbackCallback as callback on our renderer for the output bus
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_SetRenderCallback, 
								  kAudioUnitScope_Global, 
								  kOutputBus,
								  &callbackStruct, 
								  sizeof(callbackStruct));
	[self hasError:status:__FILE__:__LINE__];
	
    // reset flag to 0
	flag = 0;
    
    /*
     we need to tell the audio unit to allocate the render buffer,
     that we can directly write into it.
     */
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_ShouldAllocateBuffer,
								  kAudioUnitScope_Output, 
								  kInputBus,
								  &flag, 
								  sizeof(flag));
	

    /*
     we set the number of channels to mono and allocate our block size to
     1024 bytes.
    */
	audioBuffer.mNumberChannels = 1;
	audioBuffer.mDataByteSize = 400 * 2;
	audioBuffer.mData = malloc( 400 * 2 );
	
	// Initialize the Audio Unit and cross fingers =)
	status = AudioUnitInitialize(audioUnit);
	[self hasError:status:__FILE__:__LINE__];
    
    NSLog(@"Started");
    
}

#pragma mark controll stream

-(void)start;
{
    // start the audio unit. You should hear something, hopefully :)
    OSStatus status = AudioOutputUnitStart(audioUnit);
    [self hasError:status:__FILE__:__LINE__];
}


-(void)stop;
{
    // stop the audio unit
    OSStatus status = AudioOutputUnitStop(audioUnit);
    [self hasError:status:__FILE__:__LINE__];
}


-(void)setGain:(float)gainValue 
{
    gain = gainValue;
}

-(float)getGain
{
    return gain;
}

#pragma mark processing

-(void)processBuffer: (AudioBufferList*) audioBufferList
{
    
        //====================== Encode Audio Bytes from opus  =================
        
        NSArray *encodedSamples = [self.encoder encodeBufferList:audioBufferList];
        
        //===============================================================
        
        for (NSData *encodedSample in encodedSamples) {
            
            //====================== Encode audio bytes opus ================
            
            const char *lengthOfBytes = [[NSString stringWithFormat:@"%lu",(unsigned long)[encodedSample length]] UTF8String];
            
            NSMutableData *dataEncoded = [NSMutableData dataWithBytes:lengthOfBytes length:4];
            
            [dataEncoded appendData:encodedSample];
            
            [self addReminingEncodeBytes:50 - (int)[dataEncoded length] encodeBytes:dataEncoded];
            
            //===============================================================
            
            if(audioType == 1){
                
                
                //Local Encode Decode
                dispatch_async(self.decodeQueue, ^{
                    
                    if ([dataEncodeServerBytes length] >= 1250) {
                        
                        
                        //====================== Get Audio bytes ========================
                        
                        NSData *dataBytes50 = [dataEncodeServerBytes subdataWithRange:NSMakeRange(0, 50)];
                        
                        NSData *lengthOfBytes = [dataBytes50 subdataWithRange:NSMakeRange(0, 4)];
                        
                        NSString* strLengthOfBytes = [[NSString alloc] initWithData:lengthOfBytes encoding:NSUTF8StringEncoding];
                        
                        NSData *dataDecodeFinalAudio  = [dataBytes50 subdataWithRange:NSMakeRange(4, [strLengthOfBytes integerValue])];
                        
                        //===============================================================
                        
                        
                        //====================== Remove Audio bytes =====================
                        
                        NSRange remove50Bytes = NSMakeRange(50, [dataEncodeServerBytes length] - 50);
                        NSData *remainingBytes = [dataEncodeServerBytes subdataWithRange:remove50Bytes];
                        dataEncodeServerBytes = [[NSMutableData alloc]initWithData:remainingBytes];
                        
                        
                        //===============================================================
                        
                        [self.decoder decode:dataDecodeFinalAudio];
                        
                    }
                    
                });
            }
            else if(audioType == 2)
            {
                //Socket
                
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.23 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    if ([dataEncodeServerBytes length] >= 1250) {
                        
                        //====================== Send Audio bytes from Server ==========
                        
                        NSData *sendAudioBytes = [dataEncodeServerBytes subdataWithRange:NSMakeRange(0, 1250)];
                        
                        //====================== Remove From local Audio bytes =====================
                        
                        NSRange removeBytes = NSMakeRange(1250, [dataEncodeServerBytes length] - 1250);
                        NSData *remainingBytes = [[NSData alloc]initWithData:[dataEncodeServerBytes subdataWithRange:removeBytes]];
                        dataEncodeServerBytes = [[NSMutableData alloc]initWithData:remainingBytes];
                        
                        //===============================================================
                        
                        if ([sendAudioBytes length] == 1250) {
                            
                            
                                [self.chatSocket sendAudio:sendAudioBytes];
                                
                               // NSLog(@"Send bytes from server: %lu",(unsigned long)[sendAudioBytes length]);
                            
                            
                        }
                        
                        //===============================================================
                        
                    }
                    
                });
                
            }
        }

        //Local Play
        if(audioType == 0){
            //Local
            
            AudioBuffer sourceBuffer = audioBufferList->mBuffers[0];
            
            // we check here if the input data byte size has changed
            if (audioBuffer.mDataByteSize != sourceBuffer.mDataByteSize) {
                // clear old buffer
                free(audioBuffer.mData);
                // assing new byte size and allocate them on mData
                audioBuffer.mDataByteSize = sourceBuffer.mDataByteSize;
                audioBuffer.mData = malloc(sourceBuffer.mDataByteSize);
            }
            
            /**
             Here we modify the raw data buffer now.
             In my example this is a simple input volume gain.
             iOS 5 has this on board now, but as example quite good.
             */
            SInt16 *editBuffer = audioBufferList->mBuffers[0].mData;
            
            // loop over every packet
            for (int nb = 0; nb < (audioBufferList->mBuffers[0].mDataByteSize / 2); nb++) {
                
                // we check if the gain has been modified to save resoures
                if (gain != 0) {
                    // we need more accuracy in our calculation so we calculate with doubles
                    double gainSample = ((double)editBuffer[nb]) / 32767.0;
                    
                    /*
                     at this point we multiply with our gain factor
                     we dont make a addition to prevent generation of sound where no sound is.
                     
                     no noise
                     0*10=0
                     
                     noise if zero
                     0+10=10
                     */
                    gainSample *= gain;
                    
                    /**
                     our signal range cant be higher or lesser -1.0/1.0
                     we prevent that the signal got outside our range
                     */
                    gainSample = (gainSample < -1.0) ? -1.0 : (gainSample > 1.0) ? 1.0 : gainSample;
                    
                    /*
                     This thing here is a little helper to shape our incoming wave.
                     The sound gets pretty warm and better and the noise is reduced a lot.
                     Feel free to outcomment this line and here again.
                     
                     You can see here what happens here http://silentmatt.com/javascript-function-plotter/
                     Copy this to the command line and hit enter: plot y=(1.5*x)-0.5*x*x*x
                     */
                    
                    gainSample = (1.5 * gainSample) - 0.5 * gainSample * gainSample * gainSample;
                    
                    // multiply the new signal back to short
                    gainSample = gainSample * 32767.0;
                    
                    // write calculate sample back to the buffer
                    editBuffer[nb] = (SInt16)gainSample;
                }
            }
            
            // copy incoming audio data to the audio buffer
            memcpy(audioBuffer.mData, audioBufferList->mBuffers[0].mData, audioBufferList->mBuffers[0].mDataByteSize);
            
            
        }
}


#pragma mark - Remaing Bytes Add from Junk
-(void)addReminingEncodeBytes:(int)remainingBytes encodeBytes:(NSMutableData* )encodeBytes
{
    //===================== Add Junk =======================
    
    //    for( unsigned int i = 0 ; i < remainingBytes/4 ; ++i )
    //    {
    const char *junk = [[NSString stringWithFormat:@"1"] UTF8String];
    
    [encodeBytes appendBytes:junk length:remainingBytes];
    
    NSUInteger len = [encodeBytes length];
    Byte *byteData = (Byte*)malloc(len);
    memcpy(byteData, [encodeBytes bytes], len);
    
    //    }
    //
    //    //Add Remainig bytes
    //    if ([encodeBytes length] < 50)
    //    {
    //
    //        toNumber ++;
    //        uint32_t randomNumber = (arc4random()%(toNumber-fromNumber))+fromNumber;
    //        const char * junk = [[NSString stringWithFormat:@"%u",randomNumber] UTF8String];
    //        [encodeBytes appendBytes:junk length:50 - [encodeBytes length]];
    //    }
    //
    //    NSUInteger len = [encodeBytes length];
    //    Byte *byteData = (Byte*)malloc(len);
    //    memcpy(byteData, [encodeBytes bytes], len);
    
    [dataEncodeServerBytes appendData:encodeBytes];
    
    //   NSLog(@"Local 50 Bytes: %@", encodeBytes); //doesn't work
}

-(void)receivedAudio:(NSData *)audioData{
    
   // NSLog(@"Size of server bytes: %lu",(unsigned long)[audioData length]);
    
    if(audioType ==  2)
    {
        [dataReceiveAudioBytes appendBytes:[audioData bytes] length:[audioData length]];
    }
}


-(void)playAudioInQueue
{
    //the amount of data for 2 sec is 7500
    if ([dataReceiveAudioBytes length] > 7550) {
        
        
        for (int i = 0; i < ([dataReceiveAudioBytes length] - 7500)/50; i++) {
            
            NSData *dataBytes50 = [dataReceiveAudioBytes subdataWithRange:NSMakeRange(0, 50)];
            
            // NSLog(@"Receieve 50 Server: %@", dataBytes50); //doesn't work
            
            
            NSData *lengthOfBytes = [dataBytes50 subdataWithRange:NSMakeRange(0, 4)];
            
            NSString* strLengthOfBytes = [[NSString alloc] initWithData:lengthOfBytes encoding:NSUTF8StringEncoding];
            
            
            NSData *dataDecodeFinalAudio  = [dataBytes50 subdataWithRange:NSMakeRange(4, [strLengthOfBytes integerValue])];
            
            //NSEC_PER_SEC
            //  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.28 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            
            dispatch_async(self.decodeQueue, ^{
                
                [self.decoder decode:dataDecodeFinalAudio];
                
            });
            
            // });
            
            //===============================================================
            
            //====================== Remove Server Audio 50 bytes =====================
            
            NSRange remove50Bytes1 = NSMakeRange(50, [dataReceiveAudioBytes length] - 50);
            NSData *remainingBytes1 = [dataReceiveAudioBytes subdataWithRange:remove50Bytes1];
            dataReceiveAudioBytes = [[NSMutableData alloc]initWithData:remainingBytes1];
            
            //===============================================================
            
        }
    }
}


#pragma mark - Socket
- (void)connect
{

    if (![_chatSocket isConnected])
    {
        _chatSocket = [[TCPSocketChat alloc] initWithDelegate:self AndSocketHost:_strIp AndPort:[_strPort integerValue]];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if([_chatSocket isConnected]) {
                
                NSLog(@"Connected");

                [self.delegate connectionStatus:@"Connect"];
            }
            
        });
    }
}




- (void)disconnect
{
    
    if([_chatSocket isConnected]) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if([_chatSocket isConnected]) {
                
                [_chatSocket disconnect];
                
                [self.delegate connectionStatus:@"Disconnect"];
                
                NSLog(@"Disconnect");
            }
            
        });
        
    }
}

#pragma mark Error handling

-(void)hasError:(int)statusCode:(char*)file:(int)line 
{
	if (statusCode) {
		printf("Error Code responded %d in file %s on line %d\n", statusCode, file, line);
        exit(-1);
	}
}


@end
