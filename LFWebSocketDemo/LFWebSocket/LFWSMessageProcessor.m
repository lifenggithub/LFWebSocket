//
//  LFWSMessageProcessor.m
//  LFWebSocketDemo
//
//  Created by 李丰 on 16/9/26.
//  Copyright © 2016年 李丰. All rights reserved.
//

#import "LFWSMessageProcessor.h"

#import "LFWSFrame.h"
#import "LFWSMessage.h"

@implementation LFWSMessageProcessor
{
    NSMutableArray *messagesToSend;
    NSMutableArray *framesToSend;
    
    LFWSMessage *messageConstructed;
    LFWSMessage *messageProcessed;
    NSMutableData *constructedData;
    
    NSUInteger bytesProcessed;
    BOOL isNewMessage;
}

@synthesize bytesConstructed;
@synthesize fragmentSize;


#pragma mark - Object lifecycle
- (id)init {
    self = [super init];
    if (self) {
        messagesToSend = [[NSMutableArray alloc] init];
        framesToSend = [[NSMutableArray alloc] init];
    }
    return self;
}


#pragma mark - Helper methods
- (LFWSMessage *)messageWithStatusCode:(NSInteger)code text:(NSString *)text {
    LFWSMessage *message = [[LFWSMessage alloc] init];
    message.opcode = LFWSWebSocketOpcodeClose;
    message.statusCode = code;
    message.text = text;
    return message;
}

- (LFWSMessage *)messageWithStatusCode:(NSInteger)code{
    return [self messageWithStatusCode:code text:nil];
}


#pragma mark - Public interface
- (LFWSMessage *)constructMessageFromData:(NSData *)data {
    if (!messageConstructed) {
        messageConstructed = [[LFWSMessage alloc] init];
        constructedData = [[NSMutableData alloc] init];
        isNewMessage = YES;
    }
    
    LFWSMessage *currentMessage;
    
    uint8_t *dataBytes = (uint8_t *)[data bytes];
    dataBytes += bytesConstructed;
    
    NSUInteger frameSize = 2;
    uint64_t payloadLength = 0;
    
    // Frame is not received fully
    if (frameSize > data.length - bytesConstructed) {
        return nil;
    }
    
    // Mask bit must be clear
    if (dataBytes[1] & 0b10000000) {
        return [self messageWithStatusCode:1002];
    }
    
    uint8_t opcode = dataBytes[0] & 0b01111111;
    
    // Continuation frame received first
    if (isNewMessage && opcode == LFWSWebSocketOpcodeContinuation) {
        return [self messageWithStatusCode:1002];
    }
    
    // Opcode should not be a reserved code
    if (opcode != LFWSWebSocketOpcodeContinuation && opcode != LFWSWebSocketOpcodeText && opcode != LFWSWebSocketOpcodeBinary && opcode != LFWSWebSocketOpcodeClose && opcode != LFWSWebSocketOpcodePing && opcode != LFWSWebSocketOpcodePong ) {
        return [self messageWithStatusCode:1002];
    }
    
    // Determine message type
    if (opcode == LFWSWebSocketOpcodeText || opcode == LFWSWebSocketOpcodeBinary) {
        
        // Opcode should be continuation
        if (!isNewMessage) {
            return [self messageWithStatusCode:1002];
        }
        
        messageConstructed.opcode = opcode;
    }
    
    // Determine payload length
    if (dataBytes[1] < 126) {
        payloadLength = dataBytes[1];
    }
    else if (dataBytes[1] == 126) {
        frameSize += 2;
        
        // Frame is not received fully
        if (frameSize > data.length - bytesConstructed) {
            return nil;
        }
        
        uint16_t *payloadLength16 = (uint16_t *)(dataBytes + 2);
        payloadLength = CFSwapInt16BigToHost(*payloadLength16);
    }
    else {
        frameSize += 8;
        
        // Frame is not received fully
        if (frameSize > data.length - bytesConstructed) {
            return nil;
        }
        
        uint64_t *payloadLength64 = (uint64_t *)(dataBytes + 2);
        payloadLength = CFSwapInt64BigToHost(*payloadLength64);
    }
    
    // Frame is not received fully
    if (payloadLength + frameSize > data.length - bytesConstructed) {
        return nil;
    }
    
    uint8_t *payloadData = (uint8_t *)(dataBytes + frameSize);
    
    // Control frames
    if (opcode & 0b00001000) {
        
        currentMessage = [[LFWSMessage alloc] init];
        currentMessage.opcode = opcode;
        
        // Maximum payload length is 125
        if (payloadLength > 125) {
            return [self messageWithStatusCode:1002];
        }
        
        // Fin bit must be set
        if (~dataBytes[0] & 0b10000000) {
            return [self messageWithStatusCode:1002];
        }
        
        // Close frame
        if (opcode == LFWSWebSocketOpcodeClose) {
            uint16_t code = 0;
            
            if (payloadLength) {
                
                // Status code must be 2 byte long
                if (payloadLength == 1) {
                    code = 1002;
                }
                else {
                    uint16_t *code16 = (uint16_t *)payloadData;
                    code = CFSwapInt16BigToHost(*code16);
                    payloadData += 2;
                    currentMessage.text = [[NSString alloc] initWithBytes:payloadData length:payloadLength - 2 encoding:NSUTF8StringEncoding];
                    
                    // Invalid UTF8 message
                    if (!currentMessage.text && payloadLength > 2) {
                        code = 1007;
                    }
                }
            }
            currentMessage.statusCode = code;
        }
        
        // Ping frame
        if (opcode == LFWSWebSocketOpcodePing) {
            currentMessage.data = [NSData dataWithBytes:payloadData length:payloadLength];
        }
        
        // Pong frame
        if (opcode == LFWSWebSocketOpcodePong) {
            currentMessage.data = [NSData dataWithBytes:payloadData length:payloadLength];
        }
    }
    // Data frames
    else {
        
        // Get payload data
        [constructedData appendBytes:payloadData length:payloadLength];
        isNewMessage = NO;
        
        // In case it was the final fragment
        if (dataBytes[0] & 0b10000000) {
            
            // Text message
            if (messageConstructed.opcode == LFWSWebSocketOpcodeText) {
                messageConstructed.text = [[NSString alloc] initWithData:constructedData encoding:NSUTF8StringEncoding];
                
                // Invalid UTF8 message
                if (!messageConstructed.text && constructedData.length) {
                    return [self messageWithStatusCode:1007];
                }
            }
            // Binary message
            else if (messageConstructed.opcode == LFWSWebSocketOpcodeBinary) {
                messageConstructed.data = constructedData;
            }
            
            currentMessage = messageConstructed;
            messageConstructed = nil;
            constructedData = nil;
        }
    }
    
    bytesConstructed += (payloadLength + frameSize);
    
    return currentMessage;
}

- (void)queueMessage:(LFWSMessage *)message {
    if (message.text) {
        message.data = [message.text dataUsingEncoding:NSUTF8StringEncoding];
        message.text = nil;
    }
    
    [messagesToSend addObject:message];
}


- (void)scheduleNextMessage {
    if (!messageProcessed && messagesToSend.count) {
        messageProcessed = [messagesToSend objectAtIndex:0];
        [messagesToSend removeObjectAtIndex:0];
    }
}

- (void)processMessage {
    // If no message to process then return
    if (!messageProcessed) {
        return;
    }
    
    uint8_t *dataBytes = (uint8_t *)[messageProcessed.data bytes];
    dataBytes += bytesProcessed;
    
    uint8_t opcode = messageProcessed.opcode;
    
    if (bytesProcessed) {
        opcode = LFWSWebSocketOpcodeContinuation;
    }
    
    NSData *data =[NSData dataWithBytesNoCopy:dataBytes length:messageProcessed.data.length - bytesProcessed freeWhenDone:NO];
    
    LFWSFrame *frame = [[LFWSFrame alloc] initWithOpcode:opcode data:data maxSize:fragmentSize];
    bytesProcessed += frame.payloadLength;
    [self queueFrame:frame];
    
    // All has been processed
    if (messageProcessed.data.length == bytesProcessed) {
        messageProcessed = nil;
        bytesProcessed = 0;
    }
}

- (void)queueFrame:(LFWSFrame *)frame {
    
    // Prioritize ping/pong frames
    if (frame.opcode == LFWSWebSocketOpcodePing || frame.opcode == LFWSWebSocketOpcodePong) {
        
        int index = 0;
        for (int i = framesToSend.count - 1; i >= 0; i--) {
            LFWSFrame *aFrame = [framesToSend objectAtIndex:i];
            if (aFrame.opcode == frame.opcode) {
                index = i + 1;
                break;
            }
        }
        [framesToSend insertObject:frame atIndex:index];
    }
    else {
        [framesToSend addObject:frame];
    }
}

- (LFWSFrame *)nextFrame {
    if (framesToSend.count) {
        LFWSFrame *nextFrame = [framesToSend objectAtIndex:0];
        [framesToSend removeObjectAtIndex:0];
        return nextFrame;
    }
    
    return nil;
}


@end
