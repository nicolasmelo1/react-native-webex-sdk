//
//  RNCallEventEmitter.swift
//  WebexSDKModule
//
//  Created by Daniel Zarinski on 27/07/22.
//  Copyright © 2022 Launchcode. All rights reserved.
//

import Foundation

@objc(CallEventEmitter)
open class CallEventEmitter: RCTEventEmitter {
    public static var emitter: RCTEventEmitter!

    override init() {
        super.init()
        CallEventEmitter.emitter = self
    }

    open override func supportedEvents() -> [String] {
        return CallEventType.allCases.map { $0.rawValue }
    }

    @objc public override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

enum CallEventType: String, CaseIterable {
    case onRinging, onConnected, onDisconnected, onCallMembershipChanged, onIncomingCall, onCallParticipants
}
