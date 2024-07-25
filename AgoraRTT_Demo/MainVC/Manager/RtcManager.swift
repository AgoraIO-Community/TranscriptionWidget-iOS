//
//  MccManager.swift
//  Demo
//
//  Created by ZYP on 2024/6/5.
//

import Foundation
import AgoraRtcKit

protocol RtcManagerDelegate: NSObjectProtocol {
    func rtcManagerOnJoinedChannel(_ manager: RtcManager)
    func rtcManager(_ manager: RtcManager,
                   receiveStreamMessageFromUid uid: UInt,
                   streamId: Int,
                   data: Data)
}

class RtcManager: NSObject {
    fileprivate let logTag = "RtcManager"
    private var agoraKit: AgoraRtcEngineKit!
    weak var delegate: RtcManagerDelegate?
    
    deinit {
        Log.info(text: "deinit", tag: logTag)
        agoraKit.leaveChannel()
    }
    
    func initEngine() {
        let config = AgoraRtcEngineConfig()
        config.appId = AppConfig.share.serverEnv.appId
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    }
    
    func joinChannel(channelId: String, uid: UInt, isHost: Bool) {
        agoraKit.enableAudioVolumeIndication(50, smooth: 3, reportVad: true)
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = isHost ? .broadcaster : .audience
        agoraKit.enableAudio()
        agoraKit.setClientRole(isHost ? .broadcaster : .audience)
        let ret = agoraKit.joinChannel(byToken: nil,
                                       channelId: channelId,
                                       uid: uid,
                                       mediaOptions: option)
        print("joinChannel ret \(ret)")
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel()
    }
    
}

extension RtcManager: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinChannel channel: String,
                   withUid uid: UInt,
                   elapsed: Int) {
        delegate?.rtcManagerOnJoinedChannel(self)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        Log.errorText(text:"didOccurError \(errorCode)", tag: logTag)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        Log.info(text: "didJoinedOfUid \(uid)", tag: logTag)
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   receiveStreamMessageFromUid uid: UInt,
                   streamId: Int,
                   data: Data) {
        delegate?.rtcManager(self, receiveStreamMessageFromUid: uid,
                             streamId: streamId,
                             data: data)
    }
}

