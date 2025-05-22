//
//  MainVC.swift
//  AgoraRTT_Demo
//
//  Created by ZYP on 2024/6/21.
//

import UIKit
import SVProgressHUD
import AgoraTranscriptSubtitle

class MainVC: UIViewController {
    let mainView = MainView()
    private let rtcManager = RtcManager()
    private let rttManager = RttManager()
    let logTag = "MainVC"
    var config: Config!
    var rttTaskId: String?
    var rttToken: String?
    let useReplayTest = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if config == nil {
            fatalError()
        }
        setupUI()
        commonInit()
        
        mainView.rttView.showTranscriptContent = true
        
        let useFinalTagAsParagraphDistinction = AppConfig.share.serverEnv.name.contains("小天才")
        
        mainView.rttView.debugParam = DebugParam(dump_input: true,
                                                 dump_deserialize: true,
                                                 useFinalTagAsParagraphDistinction: useFinalTagAsParagraphDistinction,
                                                 showTranslateContent: true)
        if useReplayTest {
            debug_replay()
        }
    }
    
    deinit {
        if let token = rttToken, let taskId = rttTaskId {
            rttManager.requestStopRttRecognize(token: token, taskId: taskId)
        }
    }
    
    private func setupUI() {
        view.addSubview(mainView)
        mainView.frame = view.bounds
        let roleName = config.isHost ? "Host" : "Audience"
        title = roleName + "-" + config.channelId + "-" + "\(config.uid)"
    }
    
    private func commonInit() {
        mainView.delegate = self
        rttManager.delegate = self
        rtcManager.delegate = self
        rtcManager.initEngine()
        if !useReplayTest {
            rtcManager.joinChannel(channelId: config.channelId,
                                   uid: config.uid,
                                   isHost: config.isHost,
                                   token: config.token)
            SVProgressHUD.show(withStatus: "joining channel...")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let vc = ObjectiveCCodeVC()
        present(vc, animated: true)
    }
}

extension MainVC: MainViewDelegate {
    func mainViewDidTapAction(action: MainView.Action) {
        switch action {
        case .showAllTranscipt:
            let vc = TextShowVC()
            vc.textView.text = mainView.rttView.getAllTranscriptText()
            present(vc, animated: true)
            break
        case .showAllTranslate:
            let vc = TextShowVC()
            vc.textView.text = mainView.rttView.getAllTranslateText()
            present(vc, animated: true)
            break
        }
    }
}

extension MainVC: RtcManagerDelegate {
    func rtcManagerOnJoinedChannel(_ manager: RtcManager) {
        SVProgressHUD.show(withStatus: "startting rtt...")
        rttManager.requestStartRttRecognize(channelId: config.channelId, graphId: config.graphId, pubBotToken: config.pubBotToken)
    }
    
    func rtcManager(_ manager: RtcManager,
                    receiveStreamMessageFromUid uid: UInt,
                    streamId: Int,
                    data: Data) {
        mainView.rttView.pushMessageData(data: data, uid: uid)
    }
}

extension MainVC: RttManagerDelegate {
    func rttManager(_ rttManager: RttManager, didOccurErrorWith msg: String) {
        SVProgressHUD.showError(withStatus: msg)
    }
    
    func rttManager(_ rttManager: RttManager, didStartWith taskId: String, token: String) {
        self.rttToken = token
        self.rttTaskId = taskId
        SVProgressHUD.showInfo(withStatus: "rtt start success")
    }
    
    func rttManagerDidStop(_ rttManager: RttManager) {
        SVProgressHUD.showInfo(withStatus: "rtt stop success")
    }
}
