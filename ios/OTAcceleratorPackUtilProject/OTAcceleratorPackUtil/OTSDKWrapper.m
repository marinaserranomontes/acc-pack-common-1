//
//  OTSDKWrapper.m
//  OTAcceleratorPackUtilProject
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "OTSDKWrapper.h"
#import "LoggingWrapper.h"

static NSString* const KLogClientVersion = @"ios-vsol-1.0.0";
static NSString* const kLogComponentIdentifier = @"sdkWrapper";
static NSString* const KLogActionConnect = @"Connect";
static NSString* const KLogActionDisconnect = @"Disconnect";
static NSString* const KLogActionGetOwnConnection = @"GetOwnConnection";
static NSString* const KLogActionCheckOldestConnection = @"CheckOldestConnection";
static NSString* const KLogActionConnectionsCount = @"GetConnectionsCount";
static NSString* const KLogActionCompareConnections = @"CompareConnections";
static NSString* const KLogActionStartPreview = @"StartPreview";
static NSString* const KLogActionStopPreview = @"StopPreview";
static NSString* const KLogActionStartPublishingMedia = @"StartPublishingMedia";
static NSString* const KLogActionStopPublishingMedia = @"StopPublishingMedia";
static NSString* const KLogActionIsLocalMediaEnabled = @"IsLocalMediaEnabled";
static NSString* const KLogActionEnableLocalMedia = @"EnableLocalMedia";
static NSString* const KLogActionEnableReceivedMedia = @"EnableReceivedMedia";
static NSString* const KLogActionIsReceivedMediaEnabled = @"IsReceivedMediaEnabled";
static NSString* const KLogActionAddRemote = @"AddRemote";
static NSString* const KLogActionRemoveRemote = @"RemoveRemote";
static NSString* const KLogActionCycleCamera = @"CycleCamera";
static NSString* const KLogActionSendSignal = @"SendSignal";
static NSString* const KLogActionGetLocalStreamStatus = @"GetLocalStreamStatus";
static NSString* const KLogActionGetRemoteStreamStatus = @"GetRemoteStreamStatus";
static NSString* const KLogActionSetRemoteStyle = @"SetRemoteStyle";
static NSString* const KLogActionSetLocalStyle = @"SetLocalStyle";
static NSString* const KLogActionSetRemoteVideoRenderer = @"SetRemoteVideoRenderer";
static NSString* const KLogVariationAttempt = @"Attempt";
static NSString* const KLogVariationSuccess = @"Success";
static NSString* const KLogVariationFailure = @"Failure";

@interface OTSDKWrapper() <OTSessionDelegate, OTPublisherKitDelegate, OTPublisherDelegate, OTSubscriberKitDelegate, OTSubscriberKitDelegate>

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

@property (nonatomic) id<OTVideoRender> customRender;

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
    error = [self broadcastSignalWithType:type data:nil dst:nil];
    
    return error;
}

- (NSError *)broadcastSignalWithType:(NSString *)type
                                data:(id)string {
    NSError *error;
    error = [self broadcastSignalWithType:type data:string dst:nil];
    
    return error;
}

- (NSError *)broadcastSignalWithType:(NSString *)type
                                data:(id)string
                                 dst: (NSString *)connectionId{
    NSError *error;
    if (_session) {
        [_session signalWithType:type
                          string:string
                      connection: [_connections valueForKey:connectionId] //to send to a specific participant
                           error:&error];
    }
    
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
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionConnect
                                variation:KLogVariationAttempt
                               completion:nil];
    
    NSError *error = [self.session registerWithAccePack:self];
    
    return error;
}

- (void)disconnect {
    OTError *error = nil;
    
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionDisconnect
                                variation:KLogVariationAttempt
                               completion:nil];
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
        for (NSString* key in _subscribers) {
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
    
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionGetOwnConnection
                                variation:KLogVariationAttempt
                               completion:nil];
    [loggingWrapper.logger logEventAction:KLogActionGetOwnConnection
                                variation:KLogVariationSuccess                              completion:nil];
    return _selfConnection.connectionId;
}

- (NSUInteger)connectionCount {
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionConnectionsCount
                                variation:KLogVariationAttempt
                               completion:nil];
    [loggingWrapper.logger logEventAction:KLogActionConnectionsCount
                                variation:KLogVariationSuccess
                               completion:nil];
    return _internalConnectionCount;
}

- (BOOL)isFirstConnection {
    if (_connectionsOlderThanMe > 0) return false;
    else {
        return true;
    }
}

- (NSTimeInterval)intervalWithConnectionId:(NSString *)connectionId {
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];    [loggingWrapper.logger logEventAction:KLogActionCompareConnections
                                                                                                                                                                                 variation:KLogVariationAttempt
                                                                                                                                                                                completion:nil];
    OTConnection * connection = [_connections valueForKey:connectionId];
    NSTimeInterval time = [self.selfConnection.creationTime timeIntervalSinceDate: connection.creationTime];
    
    [loggingWrapper.logger logEventAction:KLogActionCompareConnections
                                variation:KLogVariationSuccess
                               completion:nil];
    return time;
}

- (UIView *)startCaptureLocalMedia {
    UIView *view;
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionStartPreview
                                variation:KLogVariationAttempt
                               completion:nil];
    if (!self.publisher) {
        //create a new publisher
        self.publisher = [[OTPublisher alloc] initWithDelegate:self name:self.name];
        view = self.publisher.view;
    }
    
    [loggingWrapper.logger logEventAction:KLogActionStartPreview
                                variation:KLogVariationSuccess
                               completion:nil];
    return view;
}

- (NSError *)stopCaptureLocalMedia {
    NSError *error = nil;
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionStartPreview
                                variation:KLogVariationAttempt
                               completion:nil];
    if (self.publisher) {
        //destroy the current publisher
        //[self.publisher release]; //how to destroy the publisher?
        [self.publisher.view removeFromSuperview];
        self.publisher = nil;
    }
    [loggingWrapper.logger logEventAction:KLogActionStopPreview
                                variation:KLogVariationSuccess
                               completion:nil];
    return error;
}

- (UIView *)startPublishingLocalMedia {
    OTError *error = nil;
    UIView *view = nil;
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionStartPublishingMedia
                                variation:KLogVariationAttempt
                               completion:nil];
    
    view = [self startCaptureLocalMedia];
    //start publishing
    [self.session publish:self.publisher error:&error];
    if (error) {
        self.handler(OTWrapperDidFail, nil, error);
    }
    return view;
}

- (NSError *)stopPublishingLocalMedia {
    OTError *error = nil;
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionStopPublishingMedia
                                variation:KLogVariationAttempt
                               completion:nil];
    if (self.publisher) {
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
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionEnableLocalMedia
                                variation:KLogVariationAttempt
                               completion:nil];
    if (_publisher) {
        if (mediaType == OTSDKWrapperMediaTypeAudio) {
            _publisher.publishAudio = enabled;
        }
        else {
            if (mediaType == OTSDKWrapperMediaTypeVideo){
                _publisher.publishVideo = enabled;
            }
        }
    }
    [loggingWrapper.logger logEventAction:KLogActionEnableLocalMedia
                                variation:KLogVariationSuccess
                               completion:nil];
}

- (BOOL)isLocalMediaEnabled:(OTSDKWrapperMediaType)mediaType {
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionIsLocalMediaEnabled
                                variation:KLogVariationAttempt
                               completion:nil];
    BOOL mediaEnabled = false;
    if (_publisher) {
        if (mediaType == OTSDKWrapperMediaTypeAudio) {
            mediaEnabled = _publisher.publishAudio;
        }
        else {
            if (mediaType == OTSDKWrapperMediaTypeVideo) {
                mediaEnabled = _publisher.publishVideo;
            }
        }
    }
    [loggingWrapper.logger logEventAction:KLogActionIsLocalMediaEnabled
                                variation:KLogVariationSuccess
                               completion:nil];
    return mediaEnabled;
}

- (void)switchCamera {
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionCycleCamera
                                variation:KLogVariationAttempt
                               completion:nil];
    
    if (_publisher) {
        AVCaptureDevicePosition newCameraPosition;
        AVCaptureDevicePosition currentCameraPosition;
        
        //get current position
        currentCameraPosition = _publisher.cameraPosition;
        //set the new position
        if (currentCameraPosition == AVCaptureDevicePositionFront) {
            newCameraPosition = AVCaptureDevicePositionBack;
        } else {
            newCameraPosition = AVCaptureDevicePositionFront;
        }
        
        [_publisher setCameraPosition:newCameraPosition];
    }
}

- (void)switchVideoViewScaleBehavior {
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionSetLocalStyle
                                variation:KLogVariationAttempt
                               completion:nil];
    if (_publisher) {
        if (_publisher.viewScaleBehavior == OTVideoViewScaleBehaviorFit) {
            _publisher.viewScaleBehavior = OTVideoViewScaleBehaviorFill;
        }
        else if (_publisher.viewScaleBehavior == OTVideoViewScaleBehaviorFill) {
            _publisher.viewScaleBehavior = OTVideoViewScaleBehaviorFit;
        }
    }
    
    [loggingWrapper.logger logEventAction:KLogActionSetLocalStyle
                                variation:KLogVariationSuccess
                               completion:nil];
}

- (UIView *)addRemoteWithStreamId:(NSString *)streamId
                            error:(NSError **)error {
    UIView *view = nil;
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionAddRemote
                                variation:KLogVariationAttempt
                               completion:nil];
    
    //check if the remote exists
    if (!_subscribers[streamId]) {
        NSError *subscriberError = nil;
        OTStream * stream = [_streams valueForKey:streamId];
        
        OTSubscriber *subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        
        if (_customRender != nil) {
            [subscriber setVideoRender: _customRender];
        }
        
        [_session subscribe:subscriber error:&subscriberError];
        
        if (subscriberError) {
            self.handler(OTWrapperDidFail, nil, subscriberError);
        }
        [_subscribers setObject:subscriber forKey:streamId];
        view = subscriber.view;
    }
    
    return view;
}

- (NSError *)removeRemoteWithStreamId:(NSString *)streamId {
    NSError *unsubscribeError = nil;
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionRemoveRemote
                                variation:KLogVariationAttempt
                               completion:nil];
    if (_subscribers[streamId]) {
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
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionEnableReceivedMedia
                                variation:KLogVariationAttempt
                               completion:nil];
    OTSubscriber *subscriber = [_subscribers valueForKey:streamId];
    if (subscriber) {
        if (mediaType == OTSDKWrapperMediaTypeAudio) {
            subscriber.subscribeToAudio = enabled;
        }
        else {
            if (mediaType == OTSDKWrapperMediaTypeVideo) {
                subscriber.subscribeToVideo = enabled;
            }
        }
        [_subscribers setObject:subscriber forKey:streamId];
    }
    [loggingWrapper.logger logEventAction:KLogActionEnableReceivedMedia
                                variation:KLogVariationSuccess
                               completion:nil];
    
}

- (BOOL)isReceivedMediaEnabledWithStreamId:(NSString *)streamId
                                     media:(OTSDKWrapperMediaType)mediaType {
    OTSubscriber *subscriber = [_subscribers valueForKey:streamId];
    BOOL mediaEnabled = false;
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionIsReceivedMediaEnabled
                                variation:KLogVariationAttempt
                               completion:nil];
    if (subscriber) {
        if (mediaType == OTSDKWrapperMediaTypeAudio) {
            return subscriber.subscribeToAudio;
        }
        else {
            if (mediaType == OTSDKWrapperMediaTypeVideo) {
                return subscriber.subscribeToVideo;
            }
        }
        [_subscribers setObject:subscriber forKey:streamId];
    }
    [loggingWrapper.logger logEventAction:KLogActionIsReceivedMediaEnabled                                variation:KLogVariationSuccess
                               completion:nil];
    return mediaEnabled;
}

- (void)switchRemoteVideoViewScaleBehaviorWithStreamId:(NSString *)streamId {
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionSetRemoteStyle
                                variation:KLogVariationAttempt
                               completion:nil];
    OTSubscriber *sub = [_subscribers valueForKey:streamId];
    if (!sub) {
        if (sub.viewScaleBehavior == OTVideoViewScaleBehaviorFit){
            sub.viewScaleBehavior = OTVideoViewScaleBehaviorFill;
        }
        else if (sub.viewScaleBehavior == OTVideoViewScaleBehaviorFill) {
            sub.viewScaleBehavior = OTVideoViewScaleBehaviorFit;
        }
        [_subscribers setObject:sub forKey:streamId];
    }
    [loggingWrapper.logger logEventAction:KLogActionSetRemoteStyle
                                variation:KLogVariationSuccess
                               completion:nil];
}

- (OTStreamStatus *) getRemoteStreamStatusWithStreamId:(NSString *) streamId {
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionGetRemoteStreamStatus
                                variation:KLogVariationAttempt
                               completion:nil];
    
    OTSubscriber *sub = [_subscribers valueForKey:streamId];
    if (sub) {
        [loggingWrapper.logger logEventAction:KLogActionGetRemoteStreamStatus
                                    variation:KLogVariationSuccess
                                   completion:nil];
        
        return [[OTStreamStatus alloc] initWithStreamView: sub.view containerAudo:sub.subscribeToAudio containerVideo:sub.subscribeToVideo hasAudio:sub.stream.hasAudio hasVideo:sub.stream.hasVideo type:sub.stream.videoType size:sub.stream.videoDimensions];
    
    }
    [loggingWrapper.logger logEventAction:KLogActionGetRemoteStreamStatus
                                variation:KLogVariationFailure
                               completion:nil];
    return nil;
}

- (OTStreamStatus *) getLocalStreamStatus {
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionGetLocalStreamStatus
                                variation:KLogVariationAttempt
                               completion:nil];
    if (_publisher) {
        [loggingWrapper.logger logEventAction:KLogActionGetLocalStreamStatus
                                    variation:KLogVariationSuccess
                                   completion:nil];
        
        return [[OTStreamStatus alloc] initWithStreamView:_publisher.view containerAudo:_publisher.publishAudio containerVideo:_publisher.publishVideo hasAudio:_publisher.stream.hasAudio hasVideo:_publisher.stream.hasVideo type:_publisher.stream.videoType size:_publisher.stream.videoDimensions];
    }
    [loggingWrapper.logger logEventAction:KLogActionGetLocalStreamStatus
                                variation:KLogVariationFailure
                               completion:nil];
    return nil;
}

- (void) setRemoteVideoRendererWithRender: (id<OTVideoRender>)render {
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionSetRemoteVideoRenderer
                                variation:KLogVariationAttempt
                               completion:nil];
    //limitation: this renderer will be applied to all the subscribers
    _customRender = render;
    
    [loggingWrapper.logger logEventAction:KLogActionSetRemoteVideoRenderer
                                variation:KLogVariationSuccess
                               completion:nil];
    
}

#pragma mark - Private Methods
-(void) compareConnectionTimeWithConnection: (OTConnection *)connection {
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionCompareConnections
                                variation:KLogVariationAttempt
                               completion:nil];
    
    NSComparisonResult result = [connection.creationTime compare:_selfConnection.creationTime];
    
    if (result==NSOrderedAscending) {
        _connectionsOlderThanMe --;
    }
    else {
        if (result==NSOrderedDescending) {
            _connectionsOlderThanMe ++;
        }
        else
            NSLog(@"Both dates are same");
    }
    
    [loggingWrapper.logger logEventAction:KLogActionCompareConnections
                                variation:KLogVariationSuccess
                               completion:nil];
}

#pragma mark - OTSessionDelegate
-(void)sessionDidConnect:(OTSession*)session {
    if (self.handler) {
        self.handler(OTWrapperDidConnect, nil, nil);
    }
    _selfConnection = session.connection;
    
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionConnect
                                variation:KLogVariationSuccess
                               completion:nil];
}

- (void)sessionDidDisconnect:(OTSession *)session {
    if (self.handler) {
        self.handler(OTWrapperDidDisconnect, nil, nil);
    }
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionDisconnect
                                variation:KLogVariationSuccess
                               completion:nil];
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
    if (stream.streamId && !_streams[stream.streamId]) {
        [_streams setObject:stream forKey:stream.streamId];
    }
    
    if (self.handler) {
        self.handler(OTWrapperDidJoinRemote, stream.streamId, nil);
    }
}

- (void)session:(OTSession *)session streamDestroyed:(OTStream *)stream {
    if (stream.streamId && !_streams[stream.streamId]) {
        [_streams removeObjectForKey:stream.streamId];
    }
    
    if (_subscribers[stream.streamId]) {
        [_subscribers removeObjectForKey:stream.streamId];
        //remote left the session
        if (self.handler){
            self.handler(OTWrapperDidLeaveRemote, stream.streamId, nil);
        }
    }
}

- (void)session:(OTSession *)session didFailWithError:(OTError *)error {
    if (self.handler) {
        self.handler(OTWrapperDidFail, nil, error);
    }
}

- (void)sessionDidBeginReconnecting:(OTSession *)session {
    if (self.handler) {
        self.handler(OTWrapperDidBeginReconnecting, nil,  nil);
    }
}

- (void)sessionDidReconnect:(OTSession *)session {
    if (self.handler) {
        self.handler(OTWrapperDidReconnect, nil, nil);
    }
}

- (void)session:(OTSession*)session
receivedSignalType:(NSString*)type
 fromConnection:(OTConnection*)connection
     withString:(NSString*)string {
    
    if (self.delegate) {
        [self.delegate signalReceivedWithType:type data:string fromConnectionId:connection.connectionId];
    }
}

#pragma mark - OTPublisherDelegate
- (void)publisher:(OTPublisherKit *)publisher didFailWithError:(OTError *)error {
    if (self.handler) {
        self.handler(OTWrapperDidFail, publisher.stream.streamId, error);
    }
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    _publisher = nil;
}

- (void)publisher:(OTPublisherKit*)publisher streamCreated:(OTStream*)stream {
    if (self.handler) {
        self.handler(OTWrapperDidStartPublishing, publisher.stream.streamId, nil);
    }
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionStartPublishingMedia
                                variation:KLogVariationSuccess
                               completion:nil];
}

- (void)publisher:(OTPublisherKit*)publisher streamDestroyed:(OTStream*)stream {
    if (self.handler) {
        self.handler(OTWrapperDidStopPublishing, publisher.stream.streamId, nil);
    }
    self.publisher = nil; //cleanup publisher
    
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionStopPublishingMedia
                                variation:KLogVariationSuccess
                               completion:nil];
}

- (void)publisher:(OTPublisher *)publisher didChangeCameraPosition:(AVCaptureDevicePosition)position {
    
    if (self.handler) {
        self.handler(OTCameraChanged, _publisher.stream.streamId, nil);
    }
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionCycleCamera
                                variation:KLogVariationSuccess
                               completion:nil];
}

#pragma mark - OTSubscriberKitDelegate
-(void) subscriberDidConnectToStream:(OTSubscriberKit*)subscriber {
    if (self.handler) {
        self.handler(OTWrapperDidJoinRemote, subscriber.stream.streamId, nil);
    }
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionAddRemote
                                variation:KLogVariationSuccess
                               completion:nil];
}

- (void)subscriberDidDisconnectFromStream:(OTSubscriberKit *)subscriber {
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    [loggingWrapper.logger logEventAction:KLogActionRemoveRemote
                                variation:KLogVariationSuccess
                               completion:nil];
}

-(void)subscriberVideoDisabled:(OTSubscriber *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    if (![_subscribers valueForKey:subscriber.stream.streamId]) {
        return;
    }
    
    if (reason == OTSubscriberVideoEventPublisherPropertyChanged) {
        if (self.handler) {
            self.handler(OTRemoteVideoDisabledByRemote, subscriber.stream.streamId, nil);
        }
    }
    else if (reason == OTSubscriberVideoEventQualityChanged) {
        if (self.handler) {
            self.handler(OTRemoteVideoDisabledByBadQuality, subscriber.stream.streamId, nil);
        }
    } else if (reason == OTSubscriberVideoEventSubscriberPropertyChanged) {
        if (self.handler) {
            self.handler(OTReceivedVideoDisabledByLocal, subscriber.stream.streamId, nil);
        }
    }
}

- (void)subscriberVideoEnabled:(OTSubscriberKit *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    
    if (![_subscribers valueForKey:subscriber.stream.streamId]) {
        return;
    }
    
    if (reason == OTSubscriberVideoEventPublisherPropertyChanged) {
        if (self.handler){
            self.handler(OTRemoteVideoEnabledByRemote, subscriber.stream.streamId, nil);
        }
    }
    else if (reason == OTSubscriberVideoEventQualityChanged) {
        if (self.handler) {
            self.handler(OTRemoteVideoEnabledByGoodQuality, subscriber.stream.streamId, nil);
        }
    } else if (reason == OTSubscriberVideoEventSubscriberPropertyChanged) {
        if (self.handler) {
            self.handler(OTReceivedVideoEnabledByLocal, subscriber.stream.streamId, nil);
        }
    }
}

-(void)subscriberVideoDisableWarning:(OTSubscriber *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    if (![_subscribers valueForKey:subscriber.stream.streamId]){
        return;
    }
    if (self.handler) {
        self.handler(OTRemoteVideoDisableWarning, subscriber.stream.streamId, nil);
    }
}

-(void)subscriberVideoDisableWarningLifted:(OTSubscriberKit *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    if (![_subscribers valueForKey:subscriber.stream.streamId]){
        return;
    }
    if (self.handler) {
        self.handler(OTRemoteVideoDisableWarningLifted, subscriber.stream.streamId, nil);
    }
}

- (void)subscriber:(OTSubscriberKit *)subscriber didFailWithError:(OTError *)error {
    if (self.handler) {
        self.handler(OTWrapperDidFail, subscriber.stream.streamId, error);
    }
    
    NSInteger errorCode = error.code;
    LoggingWrapper *loggingWrapper = [LoggingWrapper sharedInstanceWithComponentId:kLogComponentIdentifier withClientVersion: KLogClientVersion];
    
    switch (errorCode) {
        case OTSubscriberInternalError:
            [_subscribers removeObjectForKey:subscriber.stream.streamId];
            break;
        case OTConnectionTimedOut:
            [loggingWrapper.logger logEventAction:KLogActionAddRemote
                                        variation:KLogVariationFailure
                                       completion:nil];
            if (_session) {
                OTError *error;
                [ _session subscribe:subscriber error:&error];
            }
            break;
        case OTSubscriberWebRTCError:
            [_subscribers removeObjectForKey:subscriber.stream.streamId];
            break;
        case OTSubscriberServerCannotFindStream:
            [_subscribers removeObjectForKey:subscriber.stream.streamId];
            break;
        case OTSubscriberSessionDisconnected:
            [_subscribers removeObjectForKey:subscriber.stream.streamId];
        default:
            [_subscribers removeObjectForKey:subscriber.stream.streamId];
        break;

    }
}


@end
