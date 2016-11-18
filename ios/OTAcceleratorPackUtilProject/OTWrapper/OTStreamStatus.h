//
//  OTStreamStatus.h
//  OTWrapperProject
//
//  Created by mserrano on 18/11/2016.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#ifndef OTStreamStatus_h
#define OTStreamStatus_h

@interface OTStreamStatus : NSObject

@property(readonly) BOOL hasAudio;

@property(readonly) BOOL hasVideo;

@property (readonly) CGSize videoDimensions;

@property (readonly) OTStreamVideoType videoType;

@property (readonly) UIView* view;

@property (readonly) BOOL hasAudioContainerStatus; //Status of the container of the stream (publisher/subscriber).

@property (readonly) BOOL hasVideoContainerStatus; //Status of the container of the stream (publisher/subscriber).
@end


#endif /* OTStreamStatus_h */
