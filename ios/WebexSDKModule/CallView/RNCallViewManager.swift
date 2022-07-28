//
//  RNCallViewManager.swift
//  WebexSDKModule
//
//  Created by Daniel Zarinski on 27/07/22.
//  Copyright © 2022 Launchcode. All rights reserved.
//

import Foundation
import UIKit
import React
import WebexSDK
import AVFoundation

class CallViewController: RCTView, MultiStreamObserver {
    @objc var onCallJoined: RCTDirectEventBlock?
    @objc var onCallStatusUpdate: RCTDirectEventBlock?
    
    // TODO: Remove unnecessary methods
    var space: Space?
    var oldCallId: String?
    var player = AVAudioPlayer()
    var auxStreams: [AuxStream?] = []
    var auxIndexPath = IndexPath(item: 0, section: 0)
    var auxView: MediaRenderView?
    var auxDict: [MediaRenderView: AuxStream] = [:]
    
    // onAuxStreamChanged represent a call back when a existing auxiliary stream status changed.
    var onAuxStreamChanged: ((AuxStreamChangeEvent) -> Void)?
    
    // onAuxStreamAvailable represent the call back when current call have a new auxiliary stream.
    var onAuxStreamAvailable: (() -> MediaRenderView?)?
    
    // onAuxStreamUnavailable represent the call back when current call have an existing auxiliary stream being unavailable.
    var onAuxStreamUnavailable: (() -> MediaRenderView?)?
    
    override init(frame: CGRect) {
        print("dLog: call view controller initializing")
        super.init(frame: frame)
        self.addSubview(self.remoteVideoView)
        self.addSubview(self.selfVideoView)
        self.addSubview(self.callingLabel)
        self.requestPermissions()
        self.connectToCall()
        self.webexCallStatesProcess()
        
        selfVideoView.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: -120).isActive = true
        selfVideoView.topAnchor.constraint(equalTo: self.topAnchor, constant: 70).isActive = true
        
        callingLabel.alignCenter()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var selfVideoView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.setSize(width: 100, height: 180)
        view.flipX()
        
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleSelfViewGesture)))
        
        return view
    }()
    
    lazy var remoteVideoView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.alpha = 1
        
        return view
    }()
    
    lazy var callingLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.accessibilityIdentifier = "callLabel"
        label.textColor = .white
        label.textAlignment = .center
        label.text = "No video"
        
        return label
    }()
    
    lazy var screenShareView: MediaRenderView = {
        let view = MediaRenderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return view
    }()
    
    func connectToCall() {
        guard let call = CallManager.call else {return}
        guard let currentCallId = CallManager.currentCallId else {return}
        
        print("dLog: CallViewController.connectToCall with callId: \(currentCallId)")
        print("dLog: CallViewController.connectToCall call.spaceId: \(String(describing: call.spaceId))")
        
        print("dLog: connectToCall - isSendingVideo: \(call.sendingVideo)")
        
        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
        self.selfVideoView.alpha = 1
    }
    
    @objc func handleSelfViewGesture(gesture: UIPanGestureRecognizer){
        let location = gesture.location(in: self)
        let draggedView = gesture.view
        draggedView?.center = location
        
        let verticalBound = self.layer.frame.height / 4
        let selfViewHeight = self.selfVideoView.frame.height - 20
        
        if gesture.state == .ended {
            if self.selfVideoView.frame.midY >= verticalBound {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.selfVideoView.center.y = verticalBound
                }, completion: nil)
            }
            
            if self.selfVideoView.frame.midY <= selfViewHeight {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.selfVideoView.center.y = selfViewHeight
                }, completion: nil)
            }
            
            if self.selfVideoView.frame.midY >= verticalBound {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.selfVideoView.center.y = verticalBound
                }, completion: nil)
            }
            
            
            if self.selfVideoView.frame.midX >= self.layer.frame.width / 2 {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.selfVideoView.center.x = self.layer.frame.width - 60
                }, completion: nil)
            }else{
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                    self.selfVideoView.center.x = 60
                }, completion: nil)
            }
        }
    }
    
    func requestPermissions () {
        AVCaptureDevice.requestAccess(for: .audio) { audioRequestResponse in
            if audioRequestResponse == false {
                print("dLog: Unable to get access to audio device")
                return
            }
            
            AVCaptureDevice.requestAccess(for: .video) { videoRequestResponse in
                if videoRequestResponse == false {
                    print("dLog: Unable to get access to video device")
                    return
                }
            }
        }
    }
}

extension CallViewController {
    private func updateStates() {
        guard let call = CallManager.call else {
            print("dLog: CallViewController:updateStates - failed to get call.")
            return
        }
        
        CallManager.renderMode = call.remoteVideoRenderMode
        CallManager.compositedLayout = call.compositedVideoLayout ?? .single
        CallManager.isLocalAudioMuted = !call.sendingAudio
        CallManager.isLocalVideoMuted = !call.sendingVideo
        CallManager.isLocalScreenSharing = call.sendingScreenShare
        CallManager.isReceivingAudio = call.receivingAudio
        CallManager.isReceivingVideo = call.receivingVideo
        CallManager.isReceivingScreenshare = call.receivingScreenShare
        CallManager.isFrontCamera = call.facingMode == .user ? true : false
        
        callingLabel.isHidden = call.receivingVideo ? true : false
    }
    
    func webexCallStatesProcess() {
        guard let call = CallManager.call else {
            print("dLog: CallViewController.webexCallStatesProcess - failed to get call!!!")
            return
        }
        print("dLog: Call Status: \(call.status)")
        self.updateStates()
        
        call.onConnected = {
            print("dLog: CallViewController:call.onConnected called")
            
            self.updateStates()
            call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
        }
        
        
        call.onMediaChanged = { [weak self] mediaEvents in
            print("dLog: onMediaChanged Call, events: \(mediaEvents)")
            
            if let self = self {
                self.updateStates()
                
                switch mediaEvents {
                    /* Local/Remote video rendering view size has changed */
                case .localVideoViewSize, .remoteVideoViewSize, .remoteScreenShareViewSize, .localScreenShareViewSize:
                    break
                    
                    /* This might be triggered when the remote party muted or unmuted the audio. */
                case .remoteSendingAudio(let isSending):
                    print("dLog: Remote is sending Audio- \(isSending)")
                    
                    /* This might be triggered when the remote party muted or unmuted the video. */
                case .remoteSendingVideo(let isSending):
                    print("dLog: call onMediaChanged: remoteSendingVideo isSending: \(isSending)")
                    self.remoteVideoView.alpha = isSending ? 1 : 0
                    
                    if isSending {
                        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
                    }
                    
                    break
                    
                    /* This might be triggered when the local party muted or unmuted the audio. */
                case .sendingAudio(let isSending):
                    print("dLog: CallViewController:call.sendingAudio \(isSending)")
                    CallManager.isLocalAudioMuted = !isSending
                    
                    if CallManager.isLocalAudioMuted {
                        print("dLog: isLocalAudioMuted is true")
                    } else {
                        print("dLog: isLocalAudioMuted is false")
                    }
                    break
                    
                    /* This might be triggered when the local party muted or unmuted the video. */
                case .sendingVideo(let isSending):
                    print("dLog: call.sendingVideo \(isSending) @!@!@!@!@!@!@!@!@!@!@!@!")
                    
                    CallManager.isLocalVideoMuted = !isSending
                    if isSending {
                        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
                        self.selfVideoView.alpha = 1
                    } else {
                        self.selfVideoView.alpha = 0
                    }
                    break
                case .receivingAudio(let isReceiving):
                    print("Remote is receiving Audio- \(isReceiving)")
                    
                case .receivingVideo(let isReceiving):
                    print("dLog: CallViewController: .receivingVideo \(isReceiving)")
                    if isReceiving {
                        self.remoteVideoView.alpha = 1
                    } else {
                        self.remoteVideoView.alpha = 0
                    }
                    
                    if isReceiving {
                        call.videoRenderViews = (self.selfVideoView, self.remoteVideoView)
                    }
                    break
                    
                    /* Camera FacingMode on local device has switched. */
                case .cameraSwitched:
                    print("dLog: cameraSwitched")
                    
                    CallManager.isFrontCamera.toggle()
                    break
                    
                    
                    /* Whether Screen share is blocked by local*/
                case .receivingScreenShare(let isReceiving):
                    print("dLog: receiving screen share: \(isReceiving)")
                    
                    /* Whether Remote began to send Screen share */
                case .remoteSendingScreenShare(let remoteSending):
                    print("dLog: remoteSendingScreenShare: \(remoteSending)")
                    
                    
                    /* Whether local began to send Screen share */
                case .sendingScreenShare(let startedSending):
                    print("dLog sendingScreenShare \(startedSending)")
                    
                    /* This might be triggered when the remote video's speaker has changed.
                     */
                case .activeSpeakerChangedEvent(let from, let to):
                    print("Active speaker changed from \(String(describing: from)) to \(String(describing: to))")
                    
                default:
                    break
                }
            }
        }
        
        call.onFailed = { reason in
            print("dLog: Call Failed!")
            // self.player.stop()
        }
        
        call.onCallMembershipChanged = { membershipChangeType  in
            print("dLog: CallViewController:call.onCallMembershipChanged \(membershipChangeType)")
            
            CallEventEmitter.emitter.sendEvent(withName: CallEventType.onCallMembershipChanged.rawValue, body: ["membershipChangeType" : membershipChangeType])
        }
        
        call.onWaiting = { reason in
            print("dLog: CallViewController:call.onWaiting \(reason)")
        }
        
        call.onRinging = { [weak self] in
            print("dLog: CallViewController:call.onRinging called!")
            //      guard let self = self else { return }
            //      guard let path = Bundle.main.path(forResource: "call_1_1_ringback", ofType: "wav") else { return }
            //      let url = URL(fileURLWithPath: path)
            //      do {
            //        self.player = try AVAudioPlayer(contentsOf: url)
            //        self.player.numberOfLoops = -1
            //        self.player.play()
            //      } catch {
            //        print("There is an issue with ringtone")
            //      }
        }
        
        call.onInfoChanged = {
            print("dLog: CallViewController:call.onInfoChanged isOnHold: \(call.isOnHold)")
            CallManager.onHold = call.isOnHold
            
            call.videoRenderViews?.local.isHidden = CallManager.onHold
            call.videoRenderViews?.remote.isHidden = CallManager.onHold
            call.screenShareRenderView?.isHidden = CallManager.onHold
            self.selfVideoView.isHidden = CallManager.onHold
            self.remoteVideoView.isHidden = CallManager.onHold
        }
        
        /* set the observer of this call to get multi stream event */
        call.multiStreamObserver = self
        
        /* Callback when a new multi stream media being available. Return a MediaRenderView let the SDK open it automatically. Return nil if you want to open it by call the API:openAuxStream(view: MediaRenderView) later.*/
        self.onAuxStreamAvailable = { [weak self] in
            if let strongSelf = self {
                strongSelf.auxStreams.append(nil)
                print("dLog: onAuxStreamAvailable")
            }
            return nil
        }
        
        /* Callback when an existing multi stream media being unavailable. The SDK will close the last auxiliary stream if you don't return the specified view*/
        self.onAuxStreamUnavailable = {
            return nil
        }
        
        /* Callback when an existing multi stream media changed*/
        self.onAuxStreamChanged = { [weak self] event in
            print("dLog: self.onAuxStreamChanged")
            if let strongSelf = self {
                switch event {
                    /* Callback for open an auxiliary stream results*/
                case .auxStreamOpenedEvent(let view, let result):
                    switch result {
                    case .success(let auxStream):
                        print("dLog: aux stream: \(auxStream)")
                    case .failure(let error):
                        print("dLog: ========\(error)=====")
                    @unknown default:
                        break
                    }
                    /* This might be triggered when the auxiliary stream's speaker has changed.
                     */
                case .auxStreamPersonChangedEvent(let auxStream, let old, let new):
                    print("dLog: auxStreamPersonChangedEvent: \(auxStream)")
                    print("Auxiliary stream has changed: Person from \(String(describing: old?.displayName)) to \(String(describing: new?.displayName))")
                    /* This might be triggered when the speaker muted or unmuted the video. */
                case .auxStreamSendingVideoEvent(let auxStream):
                    print("Auxiliary stream has changed: Sending Video \(auxStream.isSendingVideo)")
                    /* This might be triggered when the speaker's video rendering view size has changed. */
                case .auxStreamSizeChangedEvent(let auxStream):
                    print("Auxiliary stream size changed: Size \(auxStream.auxStreamSize)")
                    /* Callback for close an auxiliary stream results*/
                case .auxStreamClosedEvent(let view, let error):
                    if error == nil {
                        print("closedAuxiliaryUI: renderView \(view)")
                    } else {
                        print("=====auxStreamClosedEvent error:\(String(describing: error))")
                    }
                @unknown default:
                    break
                }
            }
        }
        
        call.oniOSBroadcastingChanged = { event in
            switch event {
            case .extensionConnected:
                call.startSharing(completionHandler: { error in
                    if error != nil {
                        print("share screen error:\(String(describing: error))")
                    }
                })
                print("Extension Connected")
            case .extensionDisconnected:
                call.stopSharing(completionHandler: { error in
                    if error != nil {
                        print("share screen error:\(String(describing: error))")
                    }
                })
                print("Extension stopped Broadcasting")
            @unknown default:
                break
            }
        }
        
        print("UUID of Call: \(call.uuid)")
    }
}
