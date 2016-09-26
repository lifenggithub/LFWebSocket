//
//  LFWSMessage.h
//  LFWebSocketDemo
//
//  Created by 李丰 on 16/9/26.
//  Copyright © 2016年 李丰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LFWSFrame.h"

/**
 *  Message for communicating with a WebSocket server
 *  用来与WebSocket服务器信息交流
 */

@interface LFWSMessage : NSObject

/**
 *  The messageType.
 */
@property (assign, nonatomic) LFWSWebSocketOpcodeType opcode;

/**
 The messageData.
 */
@property (strong, nonatomic) NSData *data;

/**
 *  The messageText.
 */
@property (strong, nonatomic) NSString *text;

/**
 *  The statusCode.
 */
@property (assign, nonatomic) NSInteger statusCode;

@end
