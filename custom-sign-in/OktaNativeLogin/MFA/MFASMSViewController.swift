//
//  MFASMSViewController.swift
//  OktaNativeLogin
//
//  Created by Anastasia Yurok on 2/14/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuthNative

class MFASMSViewController: UIViewController {
    @IBOutlet private var phoneNumberLabel: UILabel!
    @IBOutlet private var codeTextField: UITextField!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var verifyButton: UIButton!
    
    private var onSendTapped: (() -> Void)?
    private var factor: EmbeddedResponse.Factor? {
        didSet {
            configure()
        }
    }
    
    private var onVerify: ((String) -> Void)?
    
    static func create(with factor: EmbeddedResponse.Factor,
                       sendSMSHandler: @escaping (() -> Void)) -> MFASMSViewController {
        let controller = UIStoryboard(name: "MFASMS", bundle: nil)
            .instantiateViewController(withIdentifier: "MFASMSViewController")
            as! MFASMSViewController
        
        controller.onSendTapped = sendSMSHandler
        controller.factor = factor
        
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.stopAnimating()
        verifyButton.isEnabled = false
    }
    
    func verifySMS(completion: @escaping (String) -> Void) {
        activityIndicator.stopAnimating()
        verifyButton.isEnabled = true
        onVerify = completion
    }
    
    @IBAction func sendSMSTapped() {
        onSendTapped?()
        activityIndicator.startAnimating()
    }
    
    @IBAction func verifyButtonTapped() {
        guard let code = codeTextField.text else { return }
        onVerify?(code)
        activityIndicator.startAnimating()
    }
    
    private func configure() {
        guard isViewLoaded else { return }
        
        if let phoneNumber = factor?.profile?.phoneNumber {
            phoneNumberLabel.isHidden = false
            phoneNumberLabel.text = phoneNumber
        } else {
            phoneNumberLabel.isHidden = true
        }
    }
}
