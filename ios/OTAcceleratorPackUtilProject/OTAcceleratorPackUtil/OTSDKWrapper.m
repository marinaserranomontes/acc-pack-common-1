//
//  OTSDKWrapper.m
//  OTAcceleratorPackUtilProject
//
//  Created by Xi Huang on 11/14/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Opentok/Opentok.h>
#import "OTSDKWrapper.h"


@interface OTSDKWrapper() <OTSessionDelegate, OTPublisherKitDelegate, OTPublisherDelegate, OTSubscriberKitDelegate, OTSubscriberKitDelegate>

@property (nonatomic) NSString *name;
@property (nonatomic) OTSession *session;
@property (nonatomic) OTPublisher *publisher; //for this first version, we will only have 1 pub.
@property (nonatomic) NSMutableDictionary *subscribers;
@property (nonatomic) NSMutableDictionary *streams;

@property (nonatomic) NSString *internalApiKey;
@property (nonatomic) NSString *internalSessionId;
@property (nonatomic) NSString *internalToken;

@property (strong, nonatomic) OTWrapperBlock handler;

@end

@implementation OTSDKWrapper

- (instancetype)initWithOpenTokApiKey:(NSString *)apiKey
                            sessionId:(NSString *)sessionId
                                token:(NSString *)token
                                 name:(NSString *)name {
    
    NSAssert(apiKey.length != 0, @"OpenTok: API key can not be empty, please add it to OneToOneCommunicator");
    NSAssert(sessionId.length != 0, @"OpenTok: Session Id can not be empty, please add it to OneToOneCommunicator");
    NSAssert(token.length != 0, @"OpenTok: Token can not be empty, please add it to OneToOneCommunicator");
    
    _session = [[OTSession alloc] initWithApiKey:apiKey
                                       sessionId:sessionId
                                        delegate:self];
    if (_session) {
        _internalApiKey = apiKey;
        _internalSessionId = sessionId;
        _internalToken = token;
        _streams = [[NSMutableDictionary alloc] init];
        _subscribers = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)connectWithHandler:(OTWrapperBlock)handler {
    
    if (!handler) return;
    
    self.handler = handler;
    NSError *error = [self connect];
    if (error) {
        self.handler(OTWrapperDidFail, error);
    }
}

- (OTError*) connect {
    
    OTError *error = nil;
    [_session connectWithToken:self.internalToken error:&error];
    
    return error;
}

- (void)disconnect {
    
     OTError *error = nil;
    
    //force unpublish
    if (_publisher) {
        [_publisher.view removeFromSuperview];
        [_session unpublish:_publisher error:&error];
        
        if (error) {
            self.handler(OTWrapperDidFail, error);
        }
        else {
            self.handler(OTWrapperDidStopPublishing, error);
        }
        _publisher = nil;
    }
    
    //force unsubscriber
    if ([_subscribers count] != 0) {
        for(OTSubscriber* sub in _subscribers) {
            [sub.view removeFromSuperview];
            [_session unsubscribe:sub error:&error];
            
            if (error) {
                self.handler(OTWrapperDidFail, error);
            }
            else {
                self.handler(OTWrapperDidLeaveRemote, error);
            }
        }
        [_subscribers removeAllObjects];
}

    //disconnect
    [_session disconnect:&error];
    
    if (error) {
        self.handler(OTWrapperDidFail, error);
    }
    else {
        self.handler(OTWrapperDidDisconnect, error);
    }
}

- (NSError *)startPublishingMedia {
    OTError *error = nil;
    if (_publisher){
        //create a new publisher
        _publisher = [[OTPublisher alloc] initWithDelegate:self name:self.name];
        
        //start publishing
        [self.session publish:_publisher error:&error];
        
        if (error) {
            self.handler(OTWrapperDidFail, error);
        }
    }
    return error;
}

- (NSError *)stopPublishingMedia {
     OTError *error = nil;
    if ( _publisher ) {
        //we suppose we have only a publisher, what happens when we have the screensharing pub too? boolean to indicate it?
        [_publisher.view removeFromSuperview];
        [_session unpublish:_publisher error:&error];
        
        if (error) {
            self.handler(OTWrapperDidFail, error);
        }
        _publisher = nil;
    }
    return error;
}

- (void)enableLocalMedia:(OTSDKWrapperMediaType)mediaType
                 enabled:(BOOL)enabled {
    
    if ( _publisher ){
        if ( mediaType == OTSDKWrapperMediaTypeAudio ){
            _publisher.publishAudio = enabled;
        }
        else {
            if ( mediaType == OTSDKWrapperMediaTypeVideo ){
                _publisher.publishVideo = enabled;
            }
        }
    }
}

- (BOOL) isLocalMediaEnabled:(OTSDKWrapperMediaType)mediaType {
    
    if ( _publisher ) {
        if ( mediaType == OTSDKWrapperMediaTypeAudio ){
            return _publisher.publishAudio;
        }
        else {
            if ( mediaType == OTSDKWrapperMediaTypeVideo ){
                return _publisher.publishVideo;
            }
        }
    }
    
    return false;
}

- (void)switchCamera {
    
    //TODO
}

- (void)switchLocalVideoViewScale {
    //TODO
}

- (UIView *)addRemoteWithStreamId:(NSString *)streamId
                            error:(NSError **)error {
    UIView *view = nil;
    
    //check if the remote exists
    if ( !_subscribers[streamId] ){
        NSError *subscriberError = nil;
        
        OTStream * stream = [_streams valueForKey:streamId];
    
        OTSubscriber *subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        [_session subscribe:subscriber error:&subscriberError];
        
        if (subscriberError){
            self.handler(OTWrapperDidFail, subscriberError);
        }
        
        [_subscribers setObject:subscriber forKey:streamId];
        
        view = subscriber.view; //to-review
        
    }
    
    return view;
}

- (NSError *)removeRemoteWithStreamId:(NSString *)streamId {
    
    NSError *unsubscribeError = nil;
    
    if ( _subscribers[streamId] ){
        
        OTSubscriber *subscriber = [_subscribers valueForKey:streamId];
    
        [subscriber.view removeFromSuperview];
        
        [self.session unsubscribe:subscriber error:&unsubscribeError];
        if (unsubscribeError) {
            NSLog(@"%@", unsubscribeError);
            self.handler(OTWrapperDidFail, unsubscribeError);
        }
        
        [_subscribers removeObjectForKey:streamId];
    }
    
    return unsubscribeError;
}

#pragma mark - OTSessionDelegate
-(void)sessionDidConnect:(OTSession*)session {
    if ( self.handler ){
        self.handler(OTWrapperDidConnect, nil);
    }
}

- (void)sessionDidDisconnect:(OTSession *)session {
    if ( self.handler ){
        self.handler(OTWrapperDidDisconnect, nil);
    }
}

- (void)session:(OTSession *)session streamCreated:(OTStream *)stream {
    if( !_streams[stream.streamId]){
        [_streams setObject:stream forKey:stream.streamId];
    }
    
    //TODO CALLBACK TO INDICATE the new streamID
    
    //TODO SUBSCRIBE AUTOMATICALLY
}

- (void)session:(OTSession *)session streamDestroyed:(OTStream *)stream {
    if( _streams[stream.streamId]){
        [_streams removeObjectForKey:stream.streamId];
    }
    
    if (_subscribers[stream.streamId]){
        [_subscribers removeObjectForKey:stream.streamId];
        //remote left the session
        if (self.handler){
            self.handler(OTWrapperDidLeaveRemote, nil);
        }
    }
    
}

- (void)session:(OTSession *)session didFailWithError:(OTError *)error {
    if ( self.handler ){
        self.handler(OTWrapperDidFail, nil);
    }
}

- (void)sessionDidBeginReconnecting:(OTSession *)session {
    if ( self.handler ){
        self.handler(OTWrapperDidBeginReconnecting, nil);
    }
}

- (void)sessionDidReconnect:(OTSession *)session {
    if ( self.handler ){
        self.handler(OTWrapperDidReconnect, nil);
    }
}

#pragma mark - OTPublisherDelegate
- (void)publisher:(OTPublisherKit *)publisher didFailWithError:(OTError *)error {
    if ( self.handler ){
        self.handler(OTWrapperDidFail, nil);
    }
}

- (void)publisher:(OTPublisherKit*)publisher streamCreated:(OTStream*)stream {
    if ( self.handler ){
        self.handler(OTWrapperDidStartPublishing, nil);
    }
}

- (void)publisher:(OTPublisherKit*)publisher streamDestroyed:(OTStream*)stream {
    if ( self.handler ){
        self.handler(OTWrapperDidStopPublishing, nil);
    }
}

#pragma mark - OTSubscriberKitDelegate
-(void) subscriberDidConnectToStream:(OTSubscriberKit*)subscriber {
    if (self.handler){
        self.handler(OTWrapperDidJoinRemote, nil);
    }
}

-(void)subscriberVideoDisabled:(OTSubscriber *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    

}

- (void)subscriberVideoEnabled:(OTSubscriberKit *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    
    
}

-(void)subscriberVideoDisableWarning:(OTSubscriber *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    
}

-(void)subscriberVideoDisableWarningLifted:(OTSubscriberKit *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    
}

- (void)subscriber:(OTSubscriberKit *)subscriber didFailWithError:(OTError *)error {

}

@end
