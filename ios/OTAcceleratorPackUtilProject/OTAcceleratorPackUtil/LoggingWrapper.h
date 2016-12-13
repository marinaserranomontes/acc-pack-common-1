//
//  LoggingWrapper.h
//  OTAcceleratorPackUtilProject
//
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <OTKAnalytics/OTKLogger.h>

@interface LoggingWrapper: NSObject

@property (nonatomic) OTKLogger *logger;

+ (instancetype)sharedInstanceWithComponentId:(NSString *)componentId withClientVersion:(NSString *)version;

@end

