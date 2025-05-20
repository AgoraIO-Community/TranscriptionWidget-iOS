//
//  EntryVC.swift
//  AgoraRTT_Demo
//
//  Created by ZYP on 2024/6/21.
//

import UIKit
import SwiftUI

class EntryVC: UIViewController {
    let entryView = EntryView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
        displaySettingInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func setupUI() {
        view.addSubview(entryView)
        
        entryView.translatesAutoresizingMaskIntoConstraints = false
        entryView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        entryView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        entryView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        entryView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        let settingItem = UIBarButtonItem(title: "Setting",
                                          style: .plain,
                                          target: self,
                                          action: #selector(rightBarButtonItemTap))
        navigationItem.rightBarButtonItem = settingItem
    }
    
    private func commonInit() {
        entryView.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        
    }
    
    @objc func rightBarButtonItemTap() {
        let vc = SettingVC()
        vc.delegate = self
        present(vc, animated: true)
    }
    
    private func displaySettingInfo() {
        let t1 = AppConfig.share.transcriptLangs.map({ $0.rawValue }).joined(separator: "/")
        let t2 = AppConfig.share.translateLangs.map({ $0.rawValue }).joined(separator: "/")
        let t3 = AppConfig.share.serverEnv.name
        let t4 = AppConfig.share.serverEnv.serverUrlString
        let t5 = AppConfig.share.serverEnv.testIp
        let t6 = AppConfig.share.serverEnv.testPort
        let t7 = AppConfig.share.serverEnv.useFinalTagAsParagraphDistinction
        let text = """
        转写目标语言：\(t1)
        翻译目标语言：\(t2)
        环境名称：\(t3)
        环境地址：\(t4)
        testIp：\(t5)
        testPort：\(t6)
        使用isFinal断句（兼容5.x协议）：\(t7)
        """
        entryView.settingLabel.text = text
        entryView.settingLabel.numberOfLines = 0
        entryView.vocsSwitchButton.isOn = AppConfig.share.useVoscStagging
    }
}

extension EntryVC: EntryViewDelegate, SettingVCDelegate {
    func onVocsBtnValueChange(value: Bool) {
        AppConfig.share.useVoscStagging = value
    }
    
    func onButtonAction(action: EntryView.Action, channelName: String, graphId: String) {
        let isHost = action == .joinHost
        let uid: UInt = action == .joinHost ? 1 : 999
        let config = MainVC.Config(isHost: isHost, uid: uid, channelId: channelName, graphId: graphId)
        let vc = MainVC()
        vc.config = config
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func settingVCDidCompleted(appConfig: AppConfig) {
        AppConfig.share.updateByConfig(appConfig: appConfig)
        displaySettingInfo()
    }
}
