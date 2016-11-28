//
//  OTSDKWrapper.m
//  OTAcceleratorPackUtilProject
//
//  Created by Xi Huang on 11/14/16.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "OTSDKWrapper.h"

@interface OTSDKWrapper() <OTSessionDelegate, OTPublisherDelegate, OTSubscriberKitDelegate, OTSubscriberKitDelegate>

@property (nonatomic) NSString *name;
@property (weak, nonatomic) OTAcceleratorSession *session;
@property (nonatomic) OTPublisher *publisher; //for this first version, we will only have 1 pub.
@property (nonatomic) NSMutableDictionary *subscribers;
@property (nonatomic) NSMutableDictionary *streams;
@property (nonatomic) NSMutableDictionary *connections;

@property (nonatomic) NSUInteger internalConnectionCount;
@property (nonatomic) OTConnection * selfConnection;
@property (readonly, nonatomic) NSUInteger connectionsOlderThanMe;

@property (strong, nonatomic) OTWrapperBlock handler;

@end

@implementation OTSDKWrapper

#pragma mark - session
- (instancetype)initWithDataSource:(id<OTSDKWrapperDataSource>)dataSource {
    
    return [self initWithName:[NSString stringWithFormat:@"%@-%@", [UIDevice currentDevice].systemName, [UIDevice currentDevice].name]
                   dataSource:dataSource];
}

- (instancetype)initWithName:(NSString *)name
                  dataSource:(id<OTSDKWrapperDataSource>)dataSource {
    if (!dataSource) {
        return nil;
    }
    
    if (self = [super init]) {
        _name = name;
        _dataSource = dataSource;
        _session = [_dataSource sessionOfSDKWrapper:self];
        _internalConnectionCount = 0;
        _connectionsOlderThanMe = 0;
        _subscribers = [[NSMutableDictionary alloc] init];
        _streams = [[NSMutableDictionary alloc] init];
        _connections = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSError *)broadcastSignalWithType:(NSString *)type {
    NSError *error;
    
    //TODO
    
    return error;
}

- (NSError *)broadcastSignalWithType:(NSString *)type
                                data:(id)string {
    NSError *error;
    
    //TODO
    
    return error;
}

- (void)connectWithHandler:(OTWrapperBlock)handler {
    if (!handler) return;
    self.handler = handler;
    NSError *error = [self connect];
    
    if (error) {
        self.handler(OTWrapperDidFail, nil, error);
    }
}

- (NSError*) connect {
    NSError *error = [self.session registerWithAccePack:self];
   
    return error;
}

- (void)disconnect {
    OTError *error = nil;
    
    //force unpublish
    if (_publisher) {
        [_publisher.view removeFromSuperview];
        [_session unpublish:_publisher error:&error];
        
        if (error) {
            self.handler(OTWrapperDidFail, _publisher.stream.streamId, error);
        }
        else {
            self.handler(OTWrapperDidStopPublishing, _publisher.stream.streamId, error);
        }
        _publisher = nil;
    }
    
    //force unsubscriber
    if ([_subscribers count] != 0) {
        for(NSString* key in _subscribers) {
            OTSubscriber *sub = [_subscribers valueForKey:key];
            [sub.view removeFromSuperview];
            [_session unsubscribe:sub error:&error];
            if (error) {
                self.handler(OTWrapperDidFail, sub.stream.streamId, error);
            }
            else {
                self.handler(OTWrapperDidLeaveRemote, sub.stream.streamId, error);
            }
        }
        [_subscribers removeAllObjects];
    }
    
    //disconnect
    [_session disconnect:&error];
    
    if (error) {
        self.handler(OTWrapperDidFail, nil, error);
    }
    else {
        self.handler(OTWrapperDidDisconnect, nil, error);
    }
    
    _internalConnectionCount = 0;
    _selfConnection = nil;
    [_connections removeAllObjects];
}

#pragma mark - connection
- (NSString *)selfConnectionId {
    return _selfConnection.connectionId;
}

- (NSUInteger)connectionCount {
    return _internalConnectionCount;
}

- (BOOL)isFirstConnection {
    if ( _connectionsOlderThanMe > 0 ) return false;
    else {
        return true;
    }
}

- (NSTimeInterval)intervalWithConnectionId:(NSString *)connectionId {
    OTConnection * connection = [_connections valueForKey:connectionId];
    //TODO
    
    NSTimeInterval time;
    
    return time;
}

- (UIView *)captureLocalMedia {
    
    UIView *view;
    
    //TODO
    
    return view;
}

- (UIView *)startPublishingLocalMedia {
    
    OTError *error = nil;
    UIView *view = nil;
    
    if (!self.publisher){
        //create a new publisher
        self.publisher = [[OTPublisher alloc] initWithDelegate:self name:self.name];
        
        //start publishing
        [self.session publish:self.publisher error:&error];
        view = self.publisher.view;
     
        if (error) {
            self.handler(OTWrapperDidFail, nil, error);
        }
    }
    return view;
}

- (NSError *)stopPublishingLocalMedia {
    OTError *error = nil;
    if ( self.publisher ) {
        //we suppose we have only a publisher, what happens when we have the screensharing pub too? boolean to indicate it?
        [self.publisher.view removeFromSuperview];
        [self.session unpublish:self.publisher error:&error];
     
        if (error) {
            self.handler(OTWrapperDidFail, nil, error);
        }
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

- (BOOL)isLocalMediaEnabled:(OTSDKWrapperMediaType)mediaType {
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
    if ( _publisher ) {
        AVCaptureDevicePosition newCameraPosition;
        AVCaptureDevicePosition currentCameraPosition;
        
        //get current position
        currentCameraPosition = _publisher.cameraPosition;
        //set the new position
        if( currentCameraPosition == AVCaptureDevicePositionFront ){
            newCameraPosition = AVCaptureDevicePositionBack;
        } else {
            newCameraPosition = AVCaptureDevicePositionFront;
        }
        
        [_publisher setCameraPosition:newCameraPosition];
        
        if ( self.handler ){
            self.handler(OTCameraChanged, _publisher.stream.streamId, nil);
        }
    }
}

- (void)switchVideoViewScaleBehavior {
    if ( _publisher ) {
        if ( _publisher.viewScaleBehavior == OTVideoViewScaleBehaviorFit ){
            _publisher.viewScaleBehavior = OTVideoViewScaleBehaviorFill;
        }
        else if ( _publisher.viewScaleBehavior == OTVideoViewScaleBehaviorFill ){
            _publisher.viewScaleBehavior = OTVideoViewScaleBehaviorFit;
        }
    }
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
            self.handler(OTWrapperDidFail, nil, subscriberError);
        }
        [_subscribers setObject:subscriber forKey:streamId];
        view = subscriber.view;
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
            self.handler(OTWrapperDidFail, nil, unsubscribeError);
        }
        
        [_subscribers removeObjectForKey:streamId];
    }
    
    return unsubscribeError;
}

- (void)enableReceivedMediaWithStreamId:(NSString *)streamId
                                  media:(OTSDKWrapperMediaType)mediaType
                                enabled:(BOOL)enabled {
    OTSubscriber *subscriber = [_subscribers valueForKey:streamId];
    if ( subscriber ){
        if ( mediaType == OTSDKWrapperMediaTypeAudio ){
            subscriber.subscribeToAudio = enabled;
        }
        else {
            if ( mediaType == OTSDKWrapperMediaTypeVideo ){
                subscriber.subscribeToVideo = enabled;
            }
        }
        [_subscribers setObject:subscriber forKey:streamId];
    }
}

- (BOOL)isReceivedMediaEnabledWithStreamId:(NSString *)streamId
                                     media:(OTSDKWrapperMediaType)mediaType {
    OTSubscriber *subscriber = [_subscribers valueForKey:streamId];
    if ( subscriber ){
        if ( mediaType == OTSDKWrapperMediaTypeAudio ){
            return subscriber.subscribeToAudio;
        }
        else {
            if ( mediaType == OTSDKWrapperMediaTypeVideo ){
                return subscriber.subscribeToVideo;
            }
        }
        [_subscribers setObject:subscriber forKey:streamId];
    }
    return false;
}

- (void)switchRemoteVideoViewScaleBehaviorWithStreamId:(NSString *)streamId {
    OTSubscriber *sub = [_subscribers valueForKey:streamId];
    if ( !sub ) {
        if ( sub.viewScaleBehavior == OTVideoViewScaleBehaviorFit ){
            sub.viewScaleBehavior = OTVideoViewScaleBehaviorFill;
        }
        else if ( sub.viewScaleBehavior == OTVideoViewScaleBehaviorFill ){
            sub.viewScaleBehavior = OTVideoViewScaleBehaviorFit;
        }
        [_subscribers setObject:sub forKey:streamId];
    }
}

#pragma mark - Private Methods
-(void) compareConnectionTimeWithConnection: (OTConnection *)connection {
    NSComparisonResult result = [connection.creationTime compare:_selfConnection.creationTime];
    
    if(result==NSOrderedAscending){
        _connectionsOlderThanMe --;
    }
    else {
        if(result==NSOrderedDescending){
            _connectionsOlderThanMe ++;
        }
        else
            NSLog(@"Both dates are same");
    }
}

#pragma mark - OTSessionDelegate
-(void)sessionDidConnect:(OTSession*)session {
    if ( self.handler ){
        self.handler(OTWrapperDidConnect, nil, nil);
    }
    _selfConnection = session.connection;
}

- (void)sessionDidDisconnect:(OTSession *)session {
    if ( self.handler ){
        self.handler(OTWrapperDidDisconnect, nil, nil);
    }
}

- (void)  session:(OTSession*) session
connectionCreated:(OTConnection*) connection {
    _internalConnectionCount++;
    
    [_connections setObject:connection forKey:connection.connectionId];
    
    //check creationtime of the connections
    [self compareConnectionTimeWithConnection: connection];
    
}

- (void)session:(OTSession*) session
connectionDestroyed:(OTConnection*) connection {
    _internalConnectionCount--;
    
    [_connections removeObjectForKey:connection.connectionId];
    
    //check creationtime of the connections
    [self compareConnectionTimeWithConnection: connection];
}

- (void)session:(OTSession *)session streamCreated:(OTStream *)stream {
    if( !_streams[stream.streamId]){
        [_streams setObject:stream forKey:stream.streamId];
    }
    
    if (self.handler){
        self.handler(OTWrapperDidJoinRemote, stream.streamId, nil);
    }
    
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
            self.handler(OTWrapperDidLeaveRemote, stream.streamId, nil);
        }
    }
}

- (void)session:(OTSession *)session didFailWithError:(OTError *)error {
    if ( self.handler ){
        self.handler(OTWrapperDidFail, nil, error);
    }
}

- (void)sessionDidBeginReconnecting:(OTSession *)session {
    if ( self.handler ){
        self.handler(OTWrapperDidBeginReconnecting, nil,  nil);
    }
}

- (void)sessionDidReconnect:(OTSession *)session {
    if ( self.handler ){
        self.handler(OTWrapperDidReconnect, nil, nil);
    }
}

#pragma mark - OTPublisherDelegate
- (void)publisher:(OTPublisherKit *)publisher didFailWithError:(OTError *)error {
    if ( self.handler ){
        self.handler(OTWrapperDidFail, publisher.stream.streamId, error);
    }
}

- (void)publisher:(OTPublisherKit*)publisher streamCreated:(OTStream*)stream {
    if ( self.handler ){
        self.handler(OTWrapperDidStartPublishing, publisher.stream.streamId, nil);
    }
}

- (void)publisher:(OTPublisherKit*)publisher streamDestroyed:(OTStream*)stream {
    if ( self.handler ){
        self.handler(OTWrapperDidStopPublishing, publisher.stream.streamId, nil);
    }
    self.publisher = nil; //cleanup publisher
}

#pragma mark - OTSubscriberKitDelegate
-(void) subscriberDidConnectToStream:(OTSubscriberKit*)subscriber {
    if ( self.handler ){
        self.handler(OTWrapperDidJoinRemote, subscriber.stream.streamId, nil);
    }
}

-(void)subscriberVideoDisabled:(OTSubscriber *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    
    if (![_subscribers valueForKey:subscriber.stream.streamId]){
        return;
    }
    
    if (reason == OTSubscriberVideoEventPublisherPropertyChanged) {
        if ( self.handler ){
            self.handler(OTRemoteVideoDisabledByRemote, subscriber.stream.streamId, nil);
        }
    }
    else if (reason == OTSubscriberVideoEventQualityChanged) {
        if ( self.handler ){
            self.handler(OTRemoteVideoDisabledByBadQuality, subscriber.stream.streamId, nil);
        }
    } else if (reason == OTSubscriberVideoEventSubscriberPropertyChanged) {
        if ( self.handler ){
            self.handler(OTReceivedVideoDisabledByLocal, subscriber.stream.streamId, nil);
        }
    }
}

- (void)subscriberVideoEnabled:(OTSubscriberKit *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    
    if (![_subscribers valueForKey:subscriber.stream.streamId]){
        return;
    }
    
    if (reason == OTSubscriberVideoEventPublisherPropertyChanged) {
        if ( self.handler ){
            self.handler(OTRemoteVideoEnabledByRemote, subscriber.stream.streamId, nil);
        }
    }
    else if (reason == OTSubscriberVideoEventQualityChanged) {
        if ( self.handler ){
            self.handler(OTRemoteVideoEnabledByGoodQuality, subscriber.stream.streamId, nil);
        }
    } else if (reason == OTSubscriberVideoEventSubscriberPropertyChanged) {
        if ( self.handler ){
            self.handler(OTReceivedVideoEnabledByLocal, subscriber.stream.streamId, nil);
        }
    }
}

-(void)subscriberVideoDisableWarning:(OTSubscriber *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    if (![_subscribers valueForKey:subscriber.stream.streamId]){
        return;
    }
    if ( self.handler ){
        self.handler(OTRemoteVideoDisableWarning, subscriber.stream.streamId, nil);
    }
}

-(void)subscriberVideoDisableWarningLifted:(OTSubscriberKit *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    if (![_subscribers valueForKey:subscriber.stream.streamId]){
        return;
    }
    if ( self.handler ){
        self.handler(OTRemoteVideoDisableWarningLifted, subscriber.stream.streamId, nil);
    }
}

- (void)subscriber:(OTSubscriberKit *)subscriber didFailWithError:(OTError *)error {
    if ( self.handler ){
        self.handler(OTWrapperDidFail, subscriber.stream.streamId, error);
    }
}

-(NSString *) stringWithOTWrapperSignal: (NSUInteger) input {
    NSArray *arr = @[
                     @"OTWrapperDidConnect",
                     @"OTWrapperDidDisconnect",
                     @"OTWrapperDidFail",
                     @"OTWrapperDidStartPublishing",
                     @"OTWrapperDidStopPublishing",
                     @"OTWrapperDidStartCaptureMedia",
                     @"OTWrapperDidStopCaptureMedia",
                     @"OTWrapperDidJoinRemote",
                     @"OTWrapperDidLeaveRemote",
                     @"OTReceivedVideoDisabledByLocal",
                     @"OTReceivedVideoEnabledByLocal",
                     @"OTRemoteVideoDisabledByRemote",
                     @"OTRemoteVideoEnabledByRemote",
                     @"OTRemoteVideoDisabledByBadQuality",
                     @"OTRemoteVideoEnabledByGoodQuality",
                     @"OTRemoteVideoDisableWarning",
                     @"OTRemoteVideoDisableWarningLifted",
                     @"OTCameraChanged",
                     @"OTWrapperDidBeginReconnecting",
                     @"OTWrapperDidReconnect"
                     ];
    return (NSString *)[arr objectAtIndex:input];
}

@end
