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
        leaveChannel()
        Log.info(text: "deinit", tag: logTag)
    }
    
    func initEngine() {
        Log.info(text: "initEngine appid \(AppConfig.share.serverEnv.appId)", tag: logTag)
        let config = AgoraRtcEngineConfig()
        config.appId = AppConfig.share.serverEnv.appId
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        resetRtcConfig()
        if AppConfig.share.useVoscStagging {
            self.agoraKit.setParameters("{\"rtc.vocs_list\":[\"114.236.137.40\"]}")
        }
    }
    
    private func resetRtcConfig() {
        self.agoraKit.setChannelProfile(.liveBroadcasting)
        self.agoraKit.setAudioProfile(.musicHighQualityStereo)
        self.agoraKit.setAudioScenario(.gameStreaming)
        self.agoraKit.enableAudio()
        self.agoraKit.enableVideo()
        self.agoraKit.enableLocalVideo(false)
        self.agoraKit.enableLocalAudio(false)
        self.agoraKit.adjustRecordingSignalVolume(100)
        self.agoraKit.adjustAudioMixingPublishVolume(0)
        self.agoraKit.setAudioOptionParams("{\"adm_mix_with_others\":false}")
        self.agoraKit.setParameters("{\"che.audio.nonmixable.option\":true}")
        self.agoraKit.setParameters("{\"rtc.debug.enable\": true}")
    }
    
    func joinChannel(channelId: String, uid: UInt, isHost: Bool, token: String?) {
        agoraKit.enableAudioVolumeIndication(50, smooth: 3, reportVad: true)
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = isHost ? .broadcaster : .audience
        agoraKit.enableAudio()
        agoraKit.setClientRole(isHost ? .broadcaster : .audience)
        let ret = agoraKit.joinChannel(byToken: token,
                                       channelId: channelId,
                                       uid: uid,
                                       mediaOptions: option)
        Log.info(text: "joinChannel ret \(ret), channelId:\(channelId)", tag: logTag)
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel({_ in
            Log.info(text: "leaveChannel success", tag: "RtcManager")
            AgoraRtcEngineKit.destroy()
        })
    }
    
}

extension RtcManager: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   didJoinChannel channel: String,
                   withUid uid: UInt,
                   elapsed: Int) {
        Log.info(text: "didJoinChannel withUid \(uid)", tag: logTag)
        delegate?.rtcManagerOnJoinedChannel(self)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        Log.errorText(text:"didOccurError \(errorCode.rawValue)", tag: logTag)
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

