//
//  OTBasicDelegate.h
//  OTWrapperProject
//
//  Created by mserrano on 18/11/2016.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#ifndef OTBasicDelegate_h
#define OTBasicDelegate_h

@interface OTBasicDelegate: NSObject

- (void) otwrapperConnectedWithConnectionId: (NSString *)connId
                          participantsCount: (NSInteger) count
                                       data: (NSStrint *) data;

- (void) otwrapperDisconnectedWithConnectionId: (NSString *)connId
                             participantsCount: (NSInteger) count;

- (void) otwrapperPublishingMediaStarted;

- (void) otwrapperPublishingMediaStopped;

- (void) otwrapperPreviewViewReady: (UIView *)view;

- (void) otwrapperPreviewViewDestroyed: (UIView *)view;

- (void) otwrapperParticipantViewReady: (UIView *)view
                              streamId: (NSString *)streamId;
- (void) otwrapperParticipantViewDestroyed: (UIView *)view
                                  streamId: (NSString *)streamId;
- (void) otwrapperParticipantJoinedWithStreamId: (NSString *) streamId;

- (void) otwrapperParticipantJoinedLeft: (NSString *) streamId;

- (void) otwrapperVideoParticipantChangedWithStreamId: (NSString *) streamId
                                               reason: (NSString *) reason
                                         videoActive: (BOOL) videoActive;

- (void) otwrraperError: (NSString*) error; //error code

@end



#endif /* OTBasicDelegate_h */
