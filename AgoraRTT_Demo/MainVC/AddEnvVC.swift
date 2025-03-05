//
//  AddEnvVC.swift
//  AgoraRTT_Demo
//
//  Created by ZYP on 2024/7/25.
//

import UIKit
import SVProgressHUD

protocol AddEnvVCDelegate: NSObjectProtocol {
    func addEnvVCDidAddEnv(env: ServerEnv)
}

class AddEnvVC: UIViewController {
    private let nameTextField = UITextField()
    private let serverUrlTextField = UITextField()
    private let testIpTextField = UITextField()
    private let testPortTextField = UITextField()
    private let appIdTextField = UITextField()
    private let authTextField = UITextField()
    private let apiVersionTextField = UITextField()
    private let comfirmButton = UIButton()
    private let useFinalTagAsParagraphDistinctionSwitch = UISwitch()
    private let useFinalTagAsParagraphDistinctionLabel = UILabel()
    weak var delegate: AddEnvVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        commonInit()
    }
    
    private func setupUI() {
        comfirmButton.setTitle("确定", for: .normal)
        comfirmButton.setTitleColor(.red, for: .normal)
        nameTextField.borderStyle = .roundedRect
        serverUrlTextField.borderStyle = .roundedRect
        testIpTextField.borderStyle = .roundedRect
        testPortTextField.borderStyle = .roundedRect
        appIdTextField.borderStyle = .roundedRect
        authTextField.borderStyle = .roundedRect
        apiVersionTextField.borderStyle = .roundedRect
        nameTextField.placeholder = "name"
        serverUrlTextField.placeholder = "http://114.236.137.80:16000/v1"
        testIpTextField.placeholder = "testIp"
        testPortTextField.placeholder = "testPort"
        appIdTextField.placeholder = "appId"
        authTextField.placeholder = "auth"
        apiVersionTextField.placeholder = "api version: 6/7"
        apiVersionTextField.keyboardType = .numberPad
        useFinalTagAsParagraphDistinctionLabel.text = "兼容 5.x(用isFinal 断句)"
        useFinalTagAsParagraphDistinctionLabel.textColor = .blue
        testPortTextField.keyboardType = .numberPad
        view.backgroundColor = .white
        let stackView = UIStackView(arrangedSubviews: [nameTextField, serverUrlTextField, testIpTextField, testPortTextField, appIdTextField, authTextField, apiVersionTextField, comfirmButton, useFinalTagAsParagraphDistinctionSwitch, useFinalTagAsParagraphDistinctionLabel])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        stackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        stackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
    }
    
    private func commonInit() {
        comfirmButton.addTarget(self, action: #selector(comfirmButtonClicked), for: .touchUpInside)
    }
    
    @objc func comfirmButtonClicked() {
        guard let name = nameTextField.text, !name.isEmpty else {
            SVProgressHUD.showError(withStatus: "name不能为空")
            return
        }
        guard let serverUrl = serverUrlTextField.text, !serverUrl.isEmpty else {
            SVProgressHUD.showError(withStatus: "serverUrl不能为空")
            return
        }
        guard let appId = appIdTextField.text, !appId.isEmpty else {
            SVProgressHUD.showError(withStatus: "appId不能为空")
            return
        }
        let apiVerionStr = apiVersionTextField.text ?? "0"
        let useFinalTagAsParagraphDistinction = useFinalTagAsParagraphDistinctionSwitch.isOn
        let serverEnv = ServerEnv(name: name,
                                  serverUrlString: serverUrl,
                                  apiVersion: APIVersion(rawValue: Float(apiVerionStr) ?? 0) ?? .api6_x,
                                  testIp: testIpTextField.text ?? "",
                                  testPort: UInt(testPortTextField.text ?? "") ?? 0,
                                  appId: appId,
                                  auth: authTextField.text,
                                  useFinalTagAsParagraphDistinction: useFinalTagAsParagraphDistinction)
        delegate?.addEnvVCDidAddEnv(env: serverEnv)
        dismiss(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
