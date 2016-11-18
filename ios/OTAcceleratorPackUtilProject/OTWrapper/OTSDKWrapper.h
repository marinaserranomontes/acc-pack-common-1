//
//  OTSDKWrapper.h
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTStreamStatus.h"
#import <OpenTok/OpenTok.h>

typedef enum : NSUInteger {
    OTSDKWrapperMediaTypeAudio,
    OTSDKWrapperMediaTypeVideo
} OTSDKWrapperMediaType;

@class OTSDKWrapper;
@protocol OTSDKWrapperDataSource <NSObject>

- (OTSession *)sessionOfSDKWrapper:(OTSDKWrapper *)wrapper;

@end

@protocol OTBasicDegate;
@protocol OTAdvancedDegate;

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
/**
 *  Force un-publish/un-subscribe, disconnect from session and clean everything
 */
- (void)disconnect;

#pragma mark - connection
@property (readonly, nonatomic) NSString *selfConnectionId;

@property (readonly, nonatomic) NSUInteger connectionCount;

@property (readonly, nonatomic) BOOL isFirstConnection;

- (NSTimeInterval)intervalWithConnectionId:(NSString *)connectionId;

#pragma mark - publisher

@property (readonly, nonatomic) OTStreamStatus* publishingStreamStatus; //localStreamStatus

- (UIView *)captureAudioVideo;

- (NSError *)startPublishing;

// if we merge screen sharing accelerator pack, this can be the API.
- (NSError *)startPublishingWithView:(UIView *)view;

- (NSError *)stopPublishing;

- (void)enablePublishingMedia:(OTSDKWrapperMediaType)mediaType
                      enabled:(BOOL)enabled;

- (BOOL) isPublishingMedia:(OTSDKWrapperMediaType)mediaType;

- (void)switchCamera;

- (void)switchVideoViewScaleBehavior;

#pragma mark - subscribers
/*- (void)newParticipantObserver:(void (^)(NSString *streamId))completion;

- (UIView *)addParticipantWithStreamId:(NSString *)streamId
                                 error:(NSError **)error;

- (NSError *)removeParticipantWithStreamId:(NSString *)streamId;

- (void)participantsLeaveObserver:(void (^)(NSString *streamId))completion;*/

- (void)enableReceivedMedia:(OTSDKWrapperMediaType)mediaType
    participantWithStreamId: (NSString *) streamId
                    enabled:(BOOL)enabled;

- (BOOL) isReceivedMedia:(OTSDKWrapperMediaType)mediaType;

- (void)switchParticipantVideoViewScaleBehaviorWithStreamId:(NSString *)streamId;

- (OTStreamStatus *) streamStatusWithStreamId: (NSString *)streamId;

@end
