//
//  RNCallEventEmitter.m
//  WebexSDKModule
//
//  Created by Daniel Zarinski on 27/07/22.
//  Copyright © 2022 Launchcode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(CallEventEmitter, RCTEventEmitter)

RCT_EXTERN_METHOD(supportedEvents)

@end
