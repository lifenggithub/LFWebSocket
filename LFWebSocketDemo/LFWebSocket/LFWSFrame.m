//
//  LFWSFrame.m
//  LFWebSocketDemo
//
//  Created by 李丰 on 16/9/26.
//  Copyright © 2016年 李丰. All rights reserved.
//

#import "LFWSFrame.h"
#import <Security/Security.h>

static const NSUInteger LFWSMaskSize = 4;

@implementation LFWSFrame

@synthesize opcode;
@synthesize data;
@synthesize payloadLength;

- (BOOL)isControlFrame {
    if (opcode & 0b00001000) {
        return YES;
    }
    return NO;
}

/**
 *  Frame construction
 */
- (void)constructFrameWithOpcode:(LFWSWebSocketOpcodeType)anOpcode data:(NSData *)payloadData maxSize:(NSUInteger)maxSize {
    opcode = anOpcode;
    
    uint8_t maskBitAndPayloadLength;
    
    // Default size: sizeof(opcode) + sizeof(maskBitAndPayloadLength) + sizeof(mask)
    NSUInteger sizeWithoutPayload = 6;
    
    uint64_t totalLength = MIN((payloadData.length + sizeWithoutPayload), maxSize);
    
    // Calculate and set the frame size and payload length
    if (totalLength - sizeWithoutPayload < 126) {
        maskBitAndPayloadLength = totalLength - sizeWithoutPayload;
    }
    else {
        totalLength = MIN(totalLength + 2, maxSize);
        sizeWithoutPayload += 2;
        
        if (totalLength - sizeWithoutPayload < 65536) {
            maskBitAndPayloadLength = 126;
        }
        else {
            totalLength = MIN(totalLength + 6, maxSize);
            maskBitAndPayloadLength = 127;
            sizeWithoutPayload += 6;
        }
    }
    
    payloadLength = totalLength - sizeWithoutPayload;
    
    // Set the opcode
    uint8_t finBitAndOpcode = anOpcode;
    
    // Set fin bit
    if (payloadLength == payloadData.length) {
        finBitAndOpcode |= 0b10000000;
    }
    
    // Create the frame data
    data = [[NSMutableData alloc] initWithLength:totalLength];
    uint8_t *frameBytes = (uint8_t *)(data.mutableBytes);
    
    // Store the opcode
    frameBytes[0] = finBitAndOpcode;
    
    // Set the mask bit
    maskBitAndPayloadLength |= 0b10000000;
    
    // Store mask bit and payload length
    frameBytes[1] = maskBitAndPayloadLength;
    
    if (payloadLength > 65535) {
        uint64_t *payloadLength64 = (uint64_t *)(frameBytes + 2);
        *payloadLength64 = CFSwapInt64HostToBig(payloadLength);
    }
    else if (payloadLength > 125) {
        uint16_t *payloadLength16 = (uint16_t *)(frameBytes + 2);
        *payloadLength16 = CFSwapInt16HostToBig(payloadLength);
    }
    
    // Generate a new mask
    uint8_t mask[LFWSMaskSize];
    SecRandomCopyBytes(kSecRandomDefault, LFWSMaskSize, mask);
    
    // Store mask key
    uint8_t *mask8 = (uint8_t *)(frameBytes + sizeWithoutPayload - sizeof(mask));
    (void)memcpy(mask8, mask, sizeof(mask));
    
    // Store the payload data
    frameBytes += sizeWithoutPayload;
    (void)memcpy(frameBytes, payloadData.bytes, payloadLength);
    
    // Mask the payload data
    for (int i = 0; i < payloadLength; i++) {
        frameBytes[i] ^= mask[i % 4];
    }
}

/**
 *  创建一个新的框架和数据接口
 *
 *  @param opcode  The opcode of the message
 *  @param data    The payload data to be processed
 *  @param maxSize The maximum size of the frame
 *
 *  @return frame
 */
- (id)initWithOpcode:(LFWSWebSocketOpcodeType)anOpcode data:(NSData *)aData maxSize:(NSUInteger)maxSize {
    self = [super init];
    if (self) {
        [self constructFrameWithOpcode:anOpcode data:aData maxSize:maxSize];
    }
    return self;
}


@end
