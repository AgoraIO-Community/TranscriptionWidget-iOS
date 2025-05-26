//
//  HttpClient.swift
//  AgoraRTT_Demo
//
//  Created by ZYP on 2024/6/21.
//

import Foundation
import AgoraTranscriptSubtitle

struct TestServerInfo {
    let ip: String
    let port: UInt
}

struct RtcConfig {
    let channelName: String
    let subBotUid: String
    let pubBotUid: String
    let pubBotToken: String?
}

fileprivate func removeNilValues(from value: Any?) -> Any? {
    guard let value = value else { return nil }
    if let dict = value as? [String: Any?] {
        var result: [String: Any] = [:]
        for (key, val) in dict {
            if let processedVal = removeNilValues(from: val) {
                result[key] = processedVal
            }
        }
        return result.isEmpty ? nil : result
    }
    if let array = value as? [[String: Any?]] {
        let processedArray = array.compactMap { removeNilValues(from: $0) as? [String: Any] }
        return processedArray.isEmpty ? nil : processedArray
    }
    if let array = value as? [Any?] {
        let processedArray = array.compactMap { removeNilValues(from: $0) }
        return processedArray.isEmpty ? nil : processedArray
    }
    return value
}

// MARK: - HttpClient6x
class HttpClient6_x: NSObject {
    static let logTag = "HttpClient6.x"
    
    typealias AcquireCompletedBlock = (_ token: String?, _ errorMsg: String?) -> Void
    
    static func acquire(appId: String,
                        auth: String?,
                        baseUrl: String,
                        instanceId: String,
                        testServerInfo: TestServerInfo?,
                        timeoutInterval: TimeInterval = 60,
                        completed: @escaping AcquireCompletedBlock) {
        let url = URL(string: baseUrl + "/projects/" + appId + "/rtsc/speech-to-text/builderTokens")!
        
        var bodyDict : [String : Any] = ["instanceId" : instanceId,
                                         "devicePlatform" : "iOS"]
        if let testInfo = testServerInfo {
            bodyDict["testIp"] = testInfo.ip
            bodyDict["testPort"] = testInfo.port
        }
        let jsonBody = try! JSONSerialization.data(withJSONObject: bodyDict, options: [])
        
        var request = URLRequest(url: url)
        request.httpBody = jsonBody
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let auth = auth {
            request.setValue("\(auth)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = timeoutInterval
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                Log.error(error: "Failed to acquire token: \(error.localizedDescription)", tag: logTag)
                completed(nil, error.localizedDescription)
            } else if let data = data {
                /// 把data转成dict
                let respDict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                
                guard let token = respDict["tokenName"] as? String else {
                    Log.errorText(text: "acquire resp: \(respDict)", tag: logTag)
                    completed(nil, "Failed to acquire token, can not find token in response")
                    return
                }
                
                completed(token, nil)
            }
        }
        
        task.resume()
    }
    
    typealias StartCompletedBlock = (_ taskId: String?, _ errorMsg: String?) -> Void
    static func start(appId: String,
                      auth: String?,
                      baseUrl: String,
                      token: String,
                      targetTranscribeLanguages: [String],
                      sourceTranslateLanguage: String,
                      targetTranslateLanguages: [String],
                      rtcConfig: RtcConfig,
                      testServerInfo: TestServerInfo?,
                      timeoutInterval: TimeInterval = 60,
                      completed: @escaping StartCompletedBlock) {
        let urlString = baseUrl + "/projects/" + appId + "/rtsc/speech-to-text/tasks" + "?builderToken=" + token
        let url = URL(string: urlString)!
        
        var bodyDict: [String: Any] = [
            /// 需要识别的转录语种，最多支持两种语言
            "languages": targetTranscribeLanguages,
            "translateConfig": [
                "languages": [
                    [
                        "target": targetTranslateLanguages,
                        "source": sourceTranslateLanguage
                    ] as [String : Any]
                ]
            ],
            "maxIdleTime": 60,
            "devicePlatform": "iOS",
            "rtcConfig": [
                "channelName": rtcConfig.channelName,
                "subBotUid": rtcConfig.subBotUid,
                "pubBotUid": rtcConfig.pubBotUid,
                "pubBotToken": rtcConfig.pubBotToken
            ]
        ]
        bodyDict = removeNilValues(from: bodyDict) as? [String: Any] ?? [:]
        let jsonBody = try! JSONSerialization.data(withJSONObject: bodyDict, options: [])
        
        var request = URLRequest(url: url)
        request.httpBody = jsonBody
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let auth = auth {
            request.setValue("\(auth)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = timeoutInterval
        Log.debug(text: "\(request.cURL)", tag: "curl")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                Log.error(error: "Failed to start: \(error.localizedDescription)", tag: logTag)
                completed(nil, error.localizedDescription)
            } else if let data = data {
                let respDict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                
                if let status = respDict["status"] as? String,
                   status == "STARTED",
                   let taskId = respDict["taskId"] as? String {
                    completed(taskId, nil)
                }
                else {
                    let jsonString = String(data: data, encoding: .utf8)!
                    Log.errorText(text: "start fail: \(jsonString)")
                    completed(nil, jsonString)
                }
            }
        }
        task.resume()
    }
    
    typealias StopCompletedBlock = (_ errorMsg: String?) -> Void
    static func stop(appId: String,
                     auth: String?,
                     baseUrl: String,
                     token: String,
                     taskId: String,
                     timeoutInterval: TimeInterval = 60,
                     completed: @escaping StopCompletedBlock) {
        let urlString = baseUrl + "/projects/" + appId + "/rtsc/speech-to-text/tasks/\(taskId)" + "?builderToken=" + token
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let auth = auth {
            request.setValue("\(auth)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = timeoutInterval
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                Log.error(error: "Failed to stop: \(error.localizedDescription)", tag: logTag)
                completed(error.localizedDescription)
            } else if let data = data {
                let respDict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                if respDict.keys.isEmpty {
                    completed(nil)
                }
                else {
                    let jsonString = String(data: data, encoding: .utf8)!
                    Log.errorText(text: "stop fail: \(jsonString)")
                    completed(jsonString)
                }
            }
        }
        task.resume()
    }
}
// MARK: - HttpClient7_x
class HttpClient7_x: NSObject {
    static let logTag = "HttpClient7.x"
    
    typealias JoinCompletedBlock = (_ agentId: String?, _ errorMsg: String?) -> Void
    static func join(appId: String,
                     auth: String?,
                     baseUrl: String,
                     graphId: String,
                     targetTranscribeLanguages: [String],
                     sourceTranslateLanguage: String,
                     targetTranslateLanguages: [String],
                     rtcConfig: RtcConfig,
                     testServerInfo: TestServerInfo?,
                     timeoutInterval: TimeInterval = 60,
                     completed: @escaping JoinCompletedBlock) {
        let urlString = baseUrl + "/api/speech-to-text/v1/projects/" + appId + "/join"
        let url = URL(string: urlString)!
        
        var bodyDict: [String: Any?] = [
            "graph_id": graphId.isEmpty ? nil : graphId,
            /// 需要识别的转录语种，最多支持两种语言
            "languages": targetTranscribeLanguages,
            "name": rtcConfig.channelName,
            "translateConfig": [
                "languages": [
                    [
                        "target": targetTranslateLanguages,
                        "source": sourceTranslateLanguage
                    ] as [String : Any]
                ]
            ],
            "maxIdleTime": 60,
            "devicePlatform": "iOS",
            "rtcConfig": [
                "channelName": rtcConfig.channelName,
                "subBotUid": rtcConfig.subBotUid,
                "pubBotUid": rtcConfig.pubBotUid,
                "pubBotToken": rtcConfig.pubBotToken
            ]
        ]
        bodyDict = removeNilValues(from: bodyDict) as? [String: Any] ?? [:]
        let jsonBody = try! JSONSerialization.data(withJSONObject: bodyDict, options: [])
        
        var request = URLRequest(url: url)
        request.httpBody = jsonBody
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let auth = auth {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = timeoutInterval
        Log.debug(text: "\(request.cURL)", tag: "curl")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                Log.error(error: "Failed to join: \(error.localizedDescription)", tag: logTag)
                completed(nil, error.localizedDescription)
            } else if let data = data {
                Log.info(text: "Response to join: \(String(data: data, encoding: .utf8) ?? "")", tag: "curl")
                let respDict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                
                if let status = respDict["status"] as? String,
                   status == "RUNNING",
                   let agentId = respDict["agent_id"] as? String {
                    completed(agentId, nil)
                }
                else {
                    let jsonString = String(data: data, encoding: .utf8)!
                    Log.errorText(text: "join fail: \(jsonString)")
                    completed(nil, jsonString)
                }
            }
        }
        task.resume()
    }
    
    typealias StopCompletedBlock = (_ errorMsg: String?) -> Void
    static func leave(appId: String,
                      auth: String?,
                      baseUrl: String,
                      agentId: String,
                      timeoutInterval: TimeInterval = 60,
                      completed: @escaping StopCompletedBlock) {
        let urlString = baseUrl + "/api/speech-to-text/v1/projects/" + appId + "/agents/\(agentId)/leave"
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval
        if let auth = auth {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                Log.error(error: "Failed to stop: \(error.localizedDescription)", tag: logTag)
                completed(error.localizedDescription)
            } else if let data = data {
                Log.info(text: "Response to leave: \(String(data: data, encoding: .utf8) ?? "")", tag: "curl")
                completed(nil)
            }
        }
        task.resume()
    }
}

// MARK: - Token
class TokenClient: NSObject {
    typealias TokenCompletedBlock = (_ token: String?, _ errorMsg: String?) -> Void
    static let baseUrl: String = "https://service.shengwang.cn/toolbox/"
    
    static func fetchToken(appId: String,
                           appCertificate: String,
                           channelName: String,
                           uid: String,
                           expire: Int = 24 * 60 * 60,
                           completed: @escaping TokenCompletedBlock) {
        let url = baseUrl + "v2/token/generate"
        let params: [String: Any] = [
            "appCertificate": appCertificate,
            "appId": appId,
            "channelName": channelName,
            "expire": expire,
            "src": "iOS",
            "ts": 0,
            "types": [1], // 1: rtc token
            "uid": uid
        ]
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.timeoutInterval = 30
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completed(nil, error.localizedDescription)
            } else if let data = data {
                let respDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let dataDict = respDict?["data"] as? [String: Any]
                let token = dataDict?["token"] as? String
                if let token = token {
                    DispatchQueue.main.async {
                        completed(token, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completed(nil, "No token in response")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completed(nil, "Unknown error")
                }
            }
        }
        task.resume()
    }
}
