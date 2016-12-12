# iOS SDK Wrapper and Common Accelerator Session Pack Utils

## Quick start

This library provides:

-  The Common Accelerator Session Pack, which is required whenever you use any of the iOS OpenTok accelerators. The Common Accelerator Session Pack is a common layer that includes the audio-video communication logic, and permits all accelerators and samples to share the same OpenTok session. The accelerator packs and sample app access the OpenTok session through the Common Accelerator Session Pack layer, which allows them to share a single OpenTok session.

- And the iOS SDK Wrapper, which offers a wrapper around the iOS SDK.
This wrapper can be used to build different samples apps based on OpenTok.

## Add the library

1. Add the following line to your pod file: pod 'OTAccPackUtil'
2. In a terminal prompt, navigate into your project directory and type pod install.
3. Reopen your project using the new *.xcworkspace file.

For more information about CocoaPods, including installation instructions, visit [CocoaPods Getting Started](https://guides.cocoapods.org/using/getting-started.html#getting-started).

## Exploring the code

For detail about the APIs used to develop this wrapper, see the [OpenTok iOS SDK Reference](https://tokbox.com/developer/sdks/iOS/reference/).

_**NOTE:** The sdk wrapper contains logic used for logging. This is used to submit anonymous usage data for internal TokBox purposes only. We request that you do not modify or remove any logging code in your use of this library._

### Main Class design

| Class        | Description  |
| ------------- | ------------- |
| `OTWrapper`   |	Represents an object to wrapper the iOS SDK and the main features of it. |
| `OTStreamStatus`   |	Defines the current status of the Stream properties. It is used in the wrapper. |
| `OTAcceleratorSession` 	|	Represents an OpenTok Session.	|
| `OTOneToOneCommunicator`	|	Defines an element to enable an one-to-one audio and video communication. |	

### Using the OneToOneCommunicator

[OpenTok One-to-One Communication Sample Apps](https://github.com/opentok/one-to-one-sample-apps)

### Using the iOS SDK Wrapper

| 		Main methods        | Description  |
| ------------- | ------------- |
|	`initWithDataSource` , `initWithName`	| Initializers	|
|   `connectWithHandler` , `disconnect` | To connect/disconnect to/from an OpenTok Session	 |
|	`startCaptureLocalMedia` , `stopCaptureLocalMedia`	| To start and stop the capture without start/stop publishing	 |
|	`startPublishingLocalMedia` , `stopPublishingLocalMedia`	|	To start and stop publishing media |
|	`enableLocalMedia` |	To enable the local media (audio or video)	|
|	`isLocalMediaEnabled`	|	To check if the local media (audio or video) is enabled or disabled	|
|	`switchCamera`	|	To cycle between cameras, if there are multiple cameras on the device	|
|	`switchVideoViewScaleBehavior`	|	To swap the  local video scale to Fill or Fit	|
|	`getLocalStreamStatus`	|	To get the stream status of the local publisher	|
|	`addRemoteWithStreamId`	|	To  add a remote 	|
|	`removeRemoteWithStreamId` |	To remove a remote |
|	`enableReceivedMediaWithStreamId`  |	To enable the received media (audio or video)	|
|	`isReceivedMediaEnabledWithStreamId`	|	To check if the received media (audior or video) is enabled or disabled	|
|	`switchRemoteVideoViewScaleBehaviorWithStreamId`	|	To swap the remote video scale to Fit or Fill	|
|	`getRemoteStreamStatusWithStreamId`	|	To get the stream status of the remote 	|
|	`setRemoteVideoRendererWithRender` |	To set a custom video render	|	
|	`connectionCount`	| To get the total number of connections 	|
|	`selfConnectionId`	|	To check if the connection is our own connection 	|
|	`isFirstConnection`	|	To check if our own connection is the first connection in the session 	|
|	`intervalWithConnectionId`	|	To compare the connections creation times between the local connection and the argument passing	|



The callbacks from the OTWrapper are implemented using a block. Some of the signals are: OTWrapperDidConnect, OTWrapperDidDisconnect, OTWrapperDidStartPublishing, OTWrapperDidStopPublishing, OTWrapperDidJoinRemote, OTWrapperDidLeaveRemote, ...

The `OTWrapperSignalDelegate` is used to notify the received signals.

Example: 

```ios
 
self.wrapper = [[OTSDKWrapper alloc] initWithDataSource:self];
self.wrapper.delegate = self; //OTWrapperSignalDelegate

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

...

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

- (void)signalReceivedWithType:(NSString *) type
                          data: (NSString *) data
              fromConnectionId: (NSString *) connectionId{
    NSLog(@"New received signal with type %@ and data %@", type, data);
}

```

