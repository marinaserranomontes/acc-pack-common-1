//
//  OTStreamStatus.m
//  OTAcceleratorPackUtilProject
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTStreamStatus.h"

@interface OTStreamStatus()

@property(nonatomic) BOOL hasAudio;

@property(nonatomic) BOOL hasVideo;

@property(nonatomic) CGSize videoDimensions;

@property(nonatomic) OTStreamVideoType videoType;

@property(nonatomic) UIView* view;

@property(nonatomic) BOOL hasAudioContainerStatus;

@property(nonatomic) BOOL hasVideoContainerStatus;

@end

@implementation OTStreamStatus

- (instancetype)initWithStreamView: (UIView *)view
                     containerAudo: (BOOL) containerAudio
                    containerVideo: (BOOL) containerVideo
                          hasAudio: (BOOL) hasAudio
                          hasVideo: (BOOL) hasVideo
                              type: (OTStreamVideoType) type
                              size: (CGSize) dimensions {
    if (self = [super init]) {
        _view = view;
        _hasAudio = hasAudio;
        _hasVideo = hasVideo;
        _hasAudioContainerStatus = containerAudio;
        _hasVideoContainerStatus = containerVideo;
        _videoType = type;
        _videoDimensions = dimensions;
    }
    
    return self;
}

@end
