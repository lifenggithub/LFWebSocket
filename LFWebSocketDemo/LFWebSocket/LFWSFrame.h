//
//  LFWSFrame.h
//  LFWebSocketDemo
//
//  Created by 李丰 on 16/9/26.
//  Copyright © 2016年 李丰. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Type
 */
typedef enum {
    LFWSWebSocketOpcodeContinuation = 0,
    LFWSWebSocketOpcodeText = 1,
    LFWSWebSocketOpcodeBinary = 2,
    LFWSWebSocketOpcodeClose = 8,
    LFWSWebSocketOpcodePing = 9,
    LFWSWebSocketOpcodePong = 10
}LFWSWebSocketOpcodeType;

/**
 *  LFWSFrame to be send to a server.
 *  发送服务
 */

@interface LFWSFrame : NSObject

/**
 The type of the LFWSFrame.
 */
@property (assign, nonatomic, readonly) LFWSWebSocketOpcodeType opcode;

/**
 The LFWSFrame data.
 */
@property (strong, nonatomic, readonly) NSMutableData *data;

/**
 The length of the payload.
 */
@property (assign, nonatomic, readonly) uint64_t payloadLength;

/**
  If the frame is a control frame,return YES.
 */
@property (assign, nonatomic, readonly) BOOL isControlFrame;


/**
 *  创建一个新的框架和数据接口
 *
 *  @param opcode  The opcode of the message
 *  @param data    The payload data to be processed
 *  @param maxSize The maximum size of the frame
 *
 *  @return frame
 */
- (id)initWithOpcode:(LFWSWebSocketOpcodeType)opcode data:(NSData *)data maxSize:(NSUInteger)maxSize;


@end
