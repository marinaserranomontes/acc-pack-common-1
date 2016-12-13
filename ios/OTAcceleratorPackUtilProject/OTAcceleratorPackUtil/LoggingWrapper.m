//
//  LoggingWrapper.m
//  OTAcceleratorPackUtilProject
//
//  Created by mserrano on 13/12/2016.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoggingWrapper.h"

@implementation LoggingWrapper : NSObject 

+ (instancetype)sharedInstanceWithComponentId:(NSString *)componentId withClientVersion:(NSString *)version {
    
    static LoggingWrapper *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LoggingWrapper alloc] init];
        sharedInstance.logger = [[OTKLogger alloc] initWithClientVersion:version
                                                                  source:[[NSBundle mainBundle] bundleIdentifier]
                                                             componentId:componentId
                                                                    guid:[[NSUUID UUID] UUIDString]];
    });
    return sharedInstance;
}

@end
