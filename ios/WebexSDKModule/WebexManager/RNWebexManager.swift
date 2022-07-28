//
//  File.swift
//  WebexSDKModule
//
//  Created by Daniel Zarinski on 27/07/22.
//  Copyright © 2022 Launchcode. All rights reserved.
//

import Foundation
import Foundation
import React
import WebexSDK
import os


@objc(WebexManager)
class WebexManager: NSObject {
    public private(set) static var webex: Webex!
    public private(set) static var isLoggedIn: Bool = false
    
    private var accessToken: String?
    private var authenticator: OAuthAuthenticator?
    
    @objc func initWebex(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        NSLog("dLog: initWebex)")
        
        DispatchQueue.main.sync {
            WebexManager.isLoggedIn = false
            self._initWebex({ success, hasError in
                if hasError == true {
                    reject("event_failure", "Unable to initialize webex.", nil)
                    return
                }
                WebexManager.isLoggedIn = success
                resolve(success)
            })
        }
    }
    
    @objc func authenticate(_ accessToken: String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        
        self.accessToken = accessToken
        print("dLog: Authenticate called with access token: \(accessToken)")
        
        if(WebexManager.isLoggedIn) {
            NSLog("dLog: authenticate called on a logged in user")
            resolve(true)
            return
        }
        
        guard let authenticator = WebexManager.webex?.authenticator as? TokenAuthenticator else {
            print("dLog: Unable to access Webex Authenticator.")
            reject("event_failure", "Unable to access Webex Authenticator.", nil)
            return
        }
        print("dLog: authenticate - 2")
        
        print("dLog: authorized: \(authenticator.authorized)")
        
        print("dLog: accessToken \(accessToken)")
        
        authenticator.authorizedWith(accessToken: accessToken, expiryInSeconds: nil, completionHandler: { result in
            print("dLog: authorize result = \(result)")
            
            if(result == .success) {
                print("dLog: authenticate - 3")
                self.accessToken = nil
                WebexManager.isLoggedIn = true
                
                resolve(true)
            } else {
                print("dLog: authenticate - 4")
                WebexManager.isLoggedIn = false
                reject("auth_failure", "Authentication failed. \(result)", nil)
            }
        })
    }
    
    @objc func getAccessToken(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        guard let webex = WebexManager.webex else {
            reject("event_error", "No webex instance.", nil)
            return
        }
        guard let authenticator = webex.authenticator as? TokenAuthenticator else {
            print("dLog: getAccessToken called without an authenticator.")
            reject("event_error", "No authenticator instance.", nil)
            return
        }
        
        authenticator.accessToken() { result in
            print("dLog: getAccessToken called through authenticator")
            if let error = result.error {
                print("Failed to get access token \(error.localizedDescription)")
                reject("event_error", error.localizedDescription, nil)
                return
            }
            
            print("dLog: accessToken: \(String(describing: result.data))")
            resolve(result.data)
            return
        }
    }
    
    @objc func isLoggedIn(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        print("dLog: isLogged In, \(WebexManager.isLoggedIn)")
        resolve(WebexManager.isLoggedIn)
    }
    
    @objc func logout(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        print("dLog: WebexManager: logout")
        guard let webex = WebexManager.webex else { return }
        
        if let authenticator = webex.authenticator {
            authenticator.deauthorize(completionHandler: {
                WebexManager.isLoggedIn = false
                resolve(true)
                return
            })
        } else {
            reject("event_error", "Authenticator was not initialized.", nil)
        }
    }
    
    private func _initWebex(_ completion: @escaping ((_ success: Bool, _ hasError: Bool?) -> Void)) -> Void {
        NSLog("dLog: initializing webex")
        
        let authenticator = TokenAuthenticator()
        
        WebexManager.webex = Webex(authenticator: authenticator)
        WebexManager.webex.enableConsoleLogger = true
        WebexManager.webex.logLevel = .error // .verbose or .error
        
        WebexManager.webex.initialize { isLoggedIn in
            print("dLog: webex initialized successfully. isLoggedIn: \(isLoggedIn)")
            WebexManager.isLoggedIn = isLoggedIn
            
            if isLoggedIn {
                CallManager.setIncomingCallListener()
            }
            
            completion(WebexManager.isLoggedIn, false)
            return
        }
    }
    
    @objc static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

