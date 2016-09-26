//
//  LFWSWebSocket.h
//  LFWebSocketDemo
//
//  Created by 李丰 on 16/9/26.
//  Copyright © 2016年 李丰. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LFWSWebSocket : NSObject<NSStreamDelegate>

/**
 *  Specifies the maximum fragment size to use. Minimum fragment size is 131 bytes.(最小131b)
 */
@property (assign, nonatomic) NSUInteger fragmentSize;

/**
 *  The hostUrl.
 */
@property (strong, nonatomic, readonly) NSURL *hostURL;

/**
 *  The protocol selected by the server.
 */
@property (strong, nonatomic, readonly) NSString *selectedProtocol;

/**
 *  初始化
 *
 *  @param url       url
 *  @param protocols protocols
 *
 *  @return self
 */
- (id)initWithURL:(NSURL *)url protocols:(NSArray *)protocols;

/**
 *  Opens the connection.（开启服务）
 */
- (void)open;

/**
 *  Closes the connection.（关闭服务）
 */
- (void)close;

/**
 *  发送数据
 *
 *  @param data  数据
 */
- (void)sendData:(NSData *)data;

/**
 *  发送文本(UTF8编码)
 *
 *  @param text 文本
 */
- (void)sendText:(NSString *)text;

/**
 Sends a ping message with the specified data.
 @param data Additional data to be sent as part of the ping message. Maximum data size is 125 bytes.
 */
- (void)sendPingWithData:(NSData *)data;

/**
 *  回调数据
 *
 *  @param dataCallback
 */
- (void)setDataCallback:(void (^)(NSData *data))dataCallback;

/**
 *  回调文本
 *
 *  @param textCallback
 */
- (void)setTextCallback:(void (^)(NSString *text))textCallback;

/**
 Sets a pong callback block that will be called whenever a pong is received.
 @param pongCallback The callback block
 */
- (void)setPongCallback:(void (^)(void))pongCallback;

/**
 *  Sets a callback block that will be called after the connection is closed.
 *  @param closeCallback The callback block
 */
- (void)setCloseCallback:(void (^)(NSUInteger statusCode, NSString *message))closeCallback;

/**
 *  Sends the given request.
 *  Use this method to send a preconfigured request to handle authentication.
 *  Websocket related header fields are added automatically. Should be used after getting a response callback.
 *  @param request The request to be sent
 */
- (void)sendRequest:(NSURLRequest *)request;

/**
 *  Sets a callback block that will be called whenever a response is received.
 *  Use this callback to handle authentication and to set any cookies received.
 *  @param responseCallback The callback block
 */
- (void)setResponseCallback:(void (^)(NSHTTPURLResponse *response, NSData *data))responseCallback;


@end
