//
//  EventEmitter.swift
//  WebexSDKModule
//
//  Created by Daniel Zarinski on 27/07/22.
//  Copyright © 2022 Launchcode. All rights reserved.
//

import Foundation
import React

open class EventEmitter {
    // shared instance
    public static var sharedInstance = EventEmitter()

    // ReactNativeEventEmitter is instantiated by React Native with the bridge.
    private var eventEmitter: CallEventEmitter!

    private init() {}

    // When React Native instantiates the emitter it is registered here.
    func registerEventEmitter(eventEmitter: CallEventEmitter) {
        self.eventEmitter = eventEmitter
    }

    func dispatch(name: String, body: Any?) {
      self.eventEmitter.sendEvent(withName: name, body: body)
    }

    // All Events which must be support by React Native.
    lazy var allEvents: [String] = {
        var allEventNames: [String] = []

        // Append all events here
        return allEventNames
    }()
}
