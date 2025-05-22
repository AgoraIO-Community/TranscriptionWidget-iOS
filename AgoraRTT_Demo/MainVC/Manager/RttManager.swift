//
//  RttManager.swift
//  AgoraRTT_Demo
//
//  Created by ZYP on 2024/6/21.
//

import UIKit

protocol RttManagerDelegate: NSObjectProtocol {
    func rttManager(_ rttManager: RttManager, didOccurErrorWith msg: String)
    func rttManager(_ rttManager: RttManager, didStartWith taskId: String, token: String)
    func rttManagerDidStop(_ rttManager: RttManager)
}

class RttManager: NSObject {
    private let logTag = "RttManager"
    weak var delegate: RttManagerDelegate?
    
    func requestStartRttRecognize(channelId: String, graphId: String, pubBotToken: String?) {
        Log.debug(text: "current env: \(AppConfig.share.serverEnv.name)", tag: logTag)
        if AppConfig.share.serverEnv.apiVersion == .api7_x {
            let testInfo: TestServerInfo? = AppConfig.share.serverEnv.testIp.isEmpty ? nil : TestServerInfo(ip: AppConfig.share.serverEnv.testIp, port: UInt(AppConfig.share.serverEnv.testPort))
            let targetTranscribeLanguages = AppConfig.share.transcriptLangs.map({ $0.rawValue })
            let sourceTranslateLanguage = targetTranscribeLanguages.first!
            let targetTranslateLanguages = AppConfig.share.translateLangs.map({ $0.rawValue })
            let rtcConfig = RtcConfig(channelName: channelId,
                                      subBotUid: AppConfig.share.subBotUid,
                                      pubBotUid: AppConfig.share.pubBotUid,
                                      pubBotToken: pubBotToken)
            HttpClient7_x.join(appId: AppConfig.share.serverEnv.appId,
                                auth: AppConfig.share.serverEnv.auth,
                                baseUrl: AppConfig.share.serverEnv.serverUrlString,
                                graphId: graphId,
                                targetTranscribeLanguages: targetTranscribeLanguages,
                                sourceTranslateLanguage: sourceTranslateLanguage,
                                targetTranslateLanguages: targetTranslateLanguages,
                                rtcConfig: rtcConfig,
                                testServerInfo: testInfo,
                                timeoutInterval: 15) { taskId, errorMsg in
                if let errorMsg = errorMsg {
                    let logText = "start rtt server fail: \(errorMsg)"
                    Log.errorText(text: logText, tag: self.logTag)
                    self.delegate?.rttManager(self, didOccurErrorWith: logText)
                    return
                }
                
                let logText = "start rtt server success, taskId: \(taskId!)"
                Log.info(text: logText, tag: self.logTag)
                self.delegate?.rttManager(self, didStartWith: taskId!, token: "")
            }
        } else {
            let testInfo: TestServerInfo? = AppConfig.share.serverEnv.testIp.isEmpty ? nil : TestServerInfo(ip: AppConfig.share.serverEnv.testIp, port: UInt(AppConfig.share.serverEnv.testPort))
            let targetTranscribeLanguages = AppConfig.share.transcriptLangs.map({ $0.rawValue })
            let sourceTranslateLanguage = targetTranscribeLanguages.first!
            let targetTranslateLanguages = AppConfig.share.translateLangs.map({ $0.rawValue })
            HttpClient6_x.acquire(appId: AppConfig.share.serverEnv.appId,
                                  auth: AppConfig.share.serverEnv.auth,
                                  baseUrl: AppConfig.share.serverEnv.serverUrlString,
                                  instanceId: channelId,
                                  testServerInfo: testInfo) { [weak self](token, errorMsg) in
                guard let self = self else {
                    return
                }
                if let errorMsg = errorMsg {
                    let logText = "acquire rtt server fail: \(errorMsg)"
                    Log.errorText(text: logText, tag: self.logTag)
                    self.delegate?.rttManager(self, didOccurErrorWith: logText)
                    return
                }
                
                let rtcConfig = RtcConfig(channelName: channelId,
                                          subBotUid: AppConfig.share.subBotUid,
                                          pubBotUid: AppConfig.share.pubBotUid,
                                          pubBotToken: pubBotToken)
                HttpClient6_x.start(appId: AppConfig.share.serverEnv.appId,
                                    auth: AppConfig.share.serverEnv.auth,
                                    baseUrl: AppConfig.share.serverEnv.serverUrlString,
                                    token: token!,
                                    targetTranscribeLanguages: targetTranscribeLanguages,
                                    sourceTranslateLanguage: sourceTranslateLanguage,
                                    targetTranslateLanguages: targetTranslateLanguages,
                                    rtcConfig: rtcConfig,
                                    testServerInfo: testInfo,
                                    timeoutInterval: 15) { taskId, errorMsg in
                    if let errorMsg = errorMsg {
                        let logText = "start rtt server fail: \(errorMsg)"
                        Log.errorText(text: logText, tag: self.logTag)
                        self.delegate?.rttManager(self, didOccurErrorWith: logText)
                        return
                    }
                    
                    let logText = "start rtt server success, taskId: \(taskId!)"
                    Log.info(text: logText, tag: self.logTag)
                    
                    self.delegate?.rttManager(self, didStartWith: taskId!, token: token!)
                }
            }
        }
    }
    
    func requestStopRttRecognize(token: String, taskId: String) {
        if AppConfig.share.serverEnv.apiVersion == .api7_x {
            HttpClient7_x.leave(appId: AppConfig.share.serverEnv.appId,
                                auth: AppConfig.share.serverEnv.auth,
                                baseUrl: AppConfig.share.serverEnv.serverUrlString,
                                agentId: taskId,
                                timeoutInterval: 10) { [weak self](errorMsg) in
                guard let self = self else { return }
                if let errorMsg = errorMsg {
                    let logText = "stop rtt server fail: \(errorMsg)"
                    Log.errorText(text: logText, tag: self.logTag)
                    self.delegate?.rttManager(self, didOccurErrorWith: logText)
                    return
                }
                let logText = "stop rtt server success"
                Log.info(text: logText, tag: self.logTag)
                
                self.delegate?.rttManagerDidStop(self)
            }
        } else {
            HttpClient6_x.stop(appId: AppConfig.share.serverEnv.appId,
                               auth: AppConfig.share.serverEnv.auth,
                               baseUrl: AppConfig.share.serverEnv.serverUrlString,
                               token: token,
                               taskId: taskId,
                               timeoutInterval: 10) { [weak self](errorMsg) in
                guard let self = self else { return }
                if let errorMsg = errorMsg {
                    let logText = "stop rtt server fail: \(errorMsg)"
                    Log.errorText(text: logText, tag: self.logTag)
                    self.delegate?.rttManager(self, didOccurErrorWith: logText)
                    return
                }
                
                let logText = "stop rtt server success"
                Log.info(text: logText, tag: self.logTag)
                
                self.delegate?.rttManagerDidStop(self)
            }
        }
    }
}

extension URLRequest {
    var cURL: String {
        var components = ["curl -v"]

        if let httpMethod = self.httpMethod {
            components.append("-X \(httpMethod)")
        }

        if let headers = self.allHTTPHeaderFields {
            for (field, value) in headers {
                components.append("-H \"\(field): \(value)\"")
            }
        }

        if let httpBody = self.httpBody,
           let bodyString = String(data: httpBody, encoding: .utf8) {
            components.append("-d \"\(bodyString)\"")
        }

        if let url = self.url {
            components.append("\"\(url.absoluteString)\"")
        }

        return components.joined(separator: " \\\n")
    }
}

