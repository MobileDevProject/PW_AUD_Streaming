//
//  TCPSocketChat.m
//  sampleNodejsChat
//
//  Created by saturngod
//

#import "TCPSocketChat.h"


@interface TCPSocketChat()
@property(nonatomic,strong) GCDAsyncSocket* asyncSocket;
@property(nonatomic,strong) NSString* HOST;
@property(nonatomic) NSInteger PORT;
@end

@implementation TCPSocketChat
@synthesize delegate = _delegate;
@synthesize asyncSocket = _asyncSocket;
-(id)initWithDelegate:(id)delegateObject AndSocketHost:(NSString*)host AndPort:(NSInteger)port {
    
    self = [super init];
    if(self)
    {
        _HOST = host;
        _PORT = port;
        _delegate = delegateObject;
        _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        NSError* err;
        if([self.asyncSocket connectToHost:_HOST onPort:_PORT error:&err])
        {
            
        }
        else {
            NSLog(@"ERROR %@",[err description]);
        }
            
    }
    return self;
}

-(void)sendMessage:(NSString *)str
{
    //[self.asyncSocket writeData:[str dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] withTimeout:-1 tag:0];
      [self.asyncSocket writeData:[str dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
}

-(void)sendAudio:(NSData *)audioData
{
    [self.asyncSocket writeData:audioData withTimeout:-1 tag:0];
}


-(void)disconnect {
    [self.asyncSocket disconnect];
}

-(void)reconnect {
    NSError* err;
    if([self isDisconnected]) {
        if([self.asyncSocket connectToHost:_HOST onPort:_PORT error:&err])
        {
            
        }
        else {
            NSLog(@"ERROR %@",[err description]);
        }
    }
}

#pragma mark - AsyncDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [self.asyncSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    if([self.delegate respondsToSelector:@selector(receivedAudio:)])
    {
//        NSString *strLength = [NSString stringWithFormat:@"%lu",(unsigned long)[data length]];
//        NSLog(@"Receive Audio & Text Length: %@",strLength);
        
        [self.delegate receivedAudio:data];
        
    }
    [self.asyncSocket readDataWithTimeout:-1 tag:0];
}

#pragma mark - Diagnostics

- (BOOL)isDisconnected {
    return [self.asyncSocket isDisconnected];
}
- (BOOL)isConnected {
    return [self.asyncSocket isConnected];
}
@end
