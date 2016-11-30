//
//  TestSDKWrapperViewController.m
//  OTAcceleratorPackUtilProject
//
//  Created by mserrano on 25/11/2016.
//  Copyright © 2016 Tokbox, Inc. All rights reserved.
//

#import "TestSDKWrapperViewController.h"
#import "AppDelegate.h"

@interface TestSDKWrapperViewController () <OTSDKWrapperDataSource, OTWrapperSignalDelegate>

@property (weak, nonatomic) IBOutlet UIView *subscriberView;
@property (weak, nonatomic) IBOutlet UIView *publisherView;
@property (nonatomic) OTSDKWrapper *wrapper;

@end

@implementation TestSDKWrapperViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.wrapper = [[OTSDKWrapper alloc] initWithDataSource:self];
    self.wrapper.delegate = self;

    __weak TestSDKWrapperViewController *weakSelf = self;
    
    [self.wrapper connectWithHandler:^(OTWrapperSignal signal, NSString *streamId, NSError *error) {
        __strong TestSDKWrapperViewController *strongSelf = weakSelf;
        if(strongSelf) {
            if (!error) {
                [self handleCommunicationWithSignal:signal streamId: streamId];
            }
            else {
                NSLog(@"Error: %@", error.description);
            }
        }
    }];
    
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"EndCall" style:UIBarButtonItemStylePlain target:self action:@selector(endCallButtonPressed)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.wrapper disconnect];
}

- (void)handleCommunicationWithSignal:(OTWrapperSignal)signal
                         streamId: (NSString *) streamId{
    switch (signal) {
        case OTWrapperDidConnect: {
            NSLog(@"SDKWrapper connected");
            
            //start publishing
            UIView * pubView = [self.wrapper startPublishingLocalMedia];
       
            if (pubView != nil) {
                pubView.frame = self.publisherView.bounds;
                [self.publisherView addSubview:pubView];
            }
            break;
        }
        case OTWrapperDidDisconnect:{
            NSLog(@"SDKWrapper disconnected");
            break;
        }
        case OTWrapperDidStartPublishing:{
            NSLog(@"SDKWrapper started publishing");
            break;
        }
        case OTWrapperDidStopPublishing:{
            NSLog(@"SDKWrapper stopped publishing");
            break;
        }
        case OTWrapperDidJoinRemote:{
            NSLog(@"SDKWrapper: a new remote joined");
            NSError *error;
            UIView * subView = [self.wrapper addRemoteWithStreamId:streamId error:&error];
            if (subView) {
                subView.frame = self.subscriberView.bounds;
                [self.subscriberView addSubview:subView];
            }
            break;
        }
        case OTWrapperDidLeaveRemote:{
            NSLog(@"SDKWrapper: a remote left");
            break;
        }
        case OTRemoteVideoDisabledByRemote:{
            NSLog(@"SDKWrapper: The remote disabled the video");
            break;
        }
        case OTRemoteVideoEnabledByRemote:{
            NSLog(@"SDKWrapper: The remote enabled the video");
            break;
        }
       
        default: break;
    }
}

- (void)endCallButtonPressed {
    [self.wrapper disconnect];
}

- (void)signalReceivedWithType:(NSString *) type
                          data: (NSString *) data
              fromConnectionId: (NSString *) connectionId{
    NSLog(@"New received signal with type %@ and data %@", type, data);
}

#pragma mark - OTOneToOneCommunicatorDataSource
- (OTAcceleratorSession *)sessionOfSDKWrapper:(OTSDKWrapper *)wrapper {
    return [(AppDelegate*)[[UIApplication sharedApplication] delegate] getSharedAcceleratorSession];
}

@end
