//
//  TCPSocketChat.h
//  sampleNodejsChat
//
//  Created by saturngod
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

@protocol TCPSocketChatDelegate <NSObject>

@required

-(void)receivedAudio:(NSData*)audioData;

@end

@interface TCPSocketChat : NSObject <GCDAsyncSocketDelegate>
@property (nonatomic,assign) id<TCPSocketChatDelegate> delegate;

/**
 Init Object
 !param host Connection HOST Name
 !param port Connection Port Number
 */

-(id)initWithDelegate:(id)delegateObject AndSocketHost:(NSString*)host AndPort:(NSInteger)port;

/**
 Send the message to TCP Chat Server
 */
-(void)sendAudio:(NSData *)audioData;

/**
 Disconnect the current status
 */
-(void)disconnect;
-(void)reconnect;

/**
 Diagnostics
 */
- (BOOL)isDisconnected;
- (BOOL)isConnected;
@end
