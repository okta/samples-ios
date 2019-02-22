//
//  MFASecurityQuestion.swift
//  OktaNativeLogin
//
//  Created by Anastasia Yurok on 2/15/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuthNative

class MFASecurityQuestionViewController: UIViewController {
    @IBOutlet private var questionLabel: UILabel!
    @IBOutlet private var answerField: UITextField!
    
    private var factor: EmbeddedResponse.Factor? {
        didSet {
            configure()
        }
    }
    
    private var onVerify: ((String) -> Void)?
    private var sendQuestionHandler: (() -> Void)?
    
    static func create(with factor: EmbeddedResponse.Factor,
                       sendQuestionHandler: @escaping (() -> Void)) -> MFASecurityQuestionViewController {
        let controller = UIStoryboard(name: "MFASecurityQuestion", bundle: nil)
            .instantiateViewController(withIdentifier: "MFASecurityQuestionViewController")
            as! MFASecurityQuestionViewController
        
        controller.factor = factor
        controller.sendQuestionHandler = sendQuestionHandler

        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendQuestionHandler?()
    }
    
    func verifySecurityQuestion(callback: @escaping (String) -> Void) {
        onVerify = callback
    }
    
    @IBAction func verifyTapped() {
        guard let answer = answerField.text else { return }
        onVerify?(answer)
    }
    
    private func configure() {
        guard isViewLoaded else { return }
        
        questionLabel.text = factor?.profile?.questionText
    }
}
