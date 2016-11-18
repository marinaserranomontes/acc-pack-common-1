//
//  OTAdvancedDelegate.h
//  OTWrapperProject
//
//  Created by mserrano on 18/11/2016.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#ifndef OTAdvancedDelegate_h
#define OTAdvancedDelegate_h

@interface OTAdvancedDelegate: NSObject

- (void) otwrapperReconnected;

- (void) otwrapperReconnecting;

- (void) otwrapperCameraChanged;

- (void) otwrapperVideoQualityWarningWithStreamId: (NSString *) streamId;

- (void) otwrapperVideoQualityWarningLiftedWithStreamId: (NSString *) streamId;

- (void) otwrraperError: (NSString*) error; //error code?

@end



#endif /* OTAdvancedDelegate_h */
