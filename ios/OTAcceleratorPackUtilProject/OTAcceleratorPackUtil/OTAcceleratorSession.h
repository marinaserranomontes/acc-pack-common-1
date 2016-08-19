//
//  OTAcceleratorSession.h
//
//  Copyright © 2016 Lucas Huang. All rights reserved.
//

#import <OpenTok/OpenTok.h>

@interface OTAcceleratorSession : OTSession

@property (readonly, nonatomic) NSString *apiKey;

+ (void)setOpenTokApiKey:(NSString *)apiKey
               sessionId:(NSString *)sessionId
                   token:(NSString *)token;

+ (instancetype)getAcceleratorPackSession;

+ (NSError *)registerWithAccePack:(id)delegate;

+ (NSError *)deregisterWithAccePack:(id)delegate;

+ (BOOL)containsAccePack:(id)delegate;

+ (NSSet<id<OTSessionDelegate>> *)getRegisters;

@end
