//
//  RNCallViewManager.m
//  WebexSDKModule
//
//  Created by Daniel Zarinski on 27/07/22.
//  Copyright © 2022 Launchcode. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(CallViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(count, NSNumber)

RCT_EXPORT_VIEW_PROPERTY(onCallStatusUpdate, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onCallJoined, RCTDirectEventBlock)

@end
