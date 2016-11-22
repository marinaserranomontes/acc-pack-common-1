//
//  OTSDKWrapper.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OTAcceleratorPackUtil/OTAcceleratorSession.h>
#import "OTStreamStatus.h"

typedef NS_ENUM(NSUInteger, OTWrapperSignal) {
    OTWrapperDidConnect = 0,
    OTWrapperDidDisconnect,
    OTWrapperDidFail,
    OTWrapperDidStartPublishing,
    OTWrapperDidStopPublishing,
    OTWrapperDidStartCaptureMedia,
    OTWrapperDidStopCaptureMedia,
    OTWrapperDidJoinRemote,
    OTWrapperDidLeaveRemote,
    OTReceivedVideoDisabledByLocal,
    OTReceivedVideoEnabledByLocal,
    OTRemoteVideoDisabledByRemote,
    OTRemoteVideoEnabledByRemote,
    OTRemoteVideoDisabledByBadQuality,
    OTRemoteVideoEnabledByGoodQuality,
    OTRemoteVideoDisableWarning,
    OTRemoteVideoDisableWarningLifted,
    OTCameraChanged,
    OTWrapperDidBeginReconnecting,
    OTWrapperDidReconnect,
};

typedef void (^OTWrapperBlock)(OTWrapperSignal signal, NSError *error);


typedef enum : NSUInteger {
    OTSDKWrapperMediaTypeAudio,
    OTSDKWrapperMediaTypeVideo
} OTSDKWrapperMediaType;

@class OTSDKWrapper;
@protocol OTSDKWrapperDataSource <NSObject>

- (OTSession *)sessionOfSDKWrapper:(OTSDKWrapper *)wrapper;

@end

@interface OTSDKWrapper : NSObject

#pragma mark - session
/**
 *  The object that acts as the data source of the SDK wrapper.
 *
 *  The delegate must adopt the OTSDKWrapperDataSource protocol. The delegate is not retained.
 */
@property (readonly, weak, nonatomic) id<OTSDKWrapperDataSource> dataSource;

@property (readonly, nonatomic) NSString *name;

- (instancetype)initWithDataSource:(id<OTSDKWrapperDataSource>)dataSource;

- (instancetype)initWithName:(NSString *)name
                  dataSource:(id<OTSDKWrapperDataSource>)dataSource;

- (NSError *)broadcastSignalWithType:(NSString *)type;

- (NSError *)broadcastSignalWithType:(NSString *)type
                                data:(id)string;

- (void) connect;

- (void)connectWithHandler:(OTWrapperBlock)handler; //to receive notifications changes

- (void)disconnect; // Force un-publish/un-subscribe, disconnect from session and clean everything

#pragma mark - connection
@property (readonly, nonatomic) NSString *selfConnectionId;

@property (readonly, nonatomic) NSUInteger connectionCount;

@property (readonly, nonatomic) BOOL isFirstConnection;

- (NSTimeInterval)intervalWithConnectionId:(NSString *)connectionId;

#pragma mark - publisher
@property (readonly, nonatomic) OTStreamStatus* localStreamStatus; //localStreamStatus

- (UIView *)captureMedia; //startPreview?

- (NSError *)startPublishingMedia;
- (NSError *)startPublishingMediaWithView:(UIView *)view; // if we merge screen sharing accelerator pack, this can be the API.

- (NSError *)stopPublishingMedia;

- (void)enableLocalMedia:(OTSDKWrapperMediaType)mediaType
                      enabled:(BOOL)enabled;

- (BOOL) isLocalMediaEnabled:(OTSDKWrapperMediaType)mediaType;

- (void)switchCamera;

- (void)switchLocalVideoViewScale; //fill or fit


#pragma mark - subscribers
- (UIView *)addRemoteWithStreamId:(NSString *)streamId
                            error:(NSError **)error;

- (NSError *)removeRemoteWithStreamId:(NSString *)streamId;

- (void)newRemoteObserver:(void (^)(NSString *streamId))completion;

- (void)remotesLeaveObserver:(void (^)(NSString *streamId))completion;

- (void)enableReceivedMedia:(OTSDKWrapperMediaType)mediaType
    participantWithStreamId: (NSString *) streamId
                    enabled:(BOOL)enabled;

- (BOOL) isReceivedMedia:(OTSDKWrapperMediaType)mediaType;

- (void)switchRemoteVideoViewScaleWithStreamId:(NSString *)streamId;

@end
