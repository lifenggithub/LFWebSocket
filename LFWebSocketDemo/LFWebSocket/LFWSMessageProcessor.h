//
//  LFWSMessageProcessor.h
//  LFWebSocketDemo
//
//  Created by 李丰 on 16/9/26.
//  Copyright © 2016年 李丰. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LFWSFrame;
@class LFWSMessage;

/**
 *  This class is responsible for constructing/processing messages.
 *  该类负责构建／处理message
 */

@interface LFWSMessageProcessor : NSObject

/**
 *  Specifies the maximum fragment size to use.
 */
@property (assign, nonatomic) NSUInteger fragmentSize;

/**
 *  Number of bytes constructed.
 */
@property (assign, nonatomic) NSUInteger bytesConstructed;

/**
 *  Constructs a message from the received data.
 *
 *  @param data 接受的数据
 *
 *  @return LFWSFrame
 */
- (LFWSFrame *)constructMessageFromData:(NSData *)data;

/**
 *  Queues a message to send.
 *
 *  @param message The message to send
 */
- (void)queueMessage:(LFWSMessage *)message;

/**
 *  Schedules the next message.
 */
- (void)scheduleNextMessage;

/**
 *  Processes the current message;
 */
- (void)processMessage;

/**
 *  Queues a frame to send.
 *  @param frame The frame to send
 */
- (void)queueFrame:(LFWSFrame *)frame;

/**
 *  Returns the next frame to send.
 */
- (LFWSFrame *)nextFrame;

@end
