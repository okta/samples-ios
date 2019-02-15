//
//  MFATOTPViewController.swift
//  OktaNativeLogin
//
//  Created by Anastasia Yurok on 2/15/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuthNative

class MFATOTPViewController: UIViewController {
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var codeField: UITextField!
    
    private var factor: EmbeddedResponse.Factor? {
        didSet {
            configure()
        }
    }
    
    private var activateHandler: (() -> Void)?
    private var onVerify: ((String) -> Void)?
    
    static func create(with factor: EmbeddedResponse.Factor,
                       activationHandler: @escaping (() -> Void)) -> MFATOTPViewController {
        let controller = UIStoryboard(name: "MFATOTP", bundle: nil)
            .instantiateViewController(withIdentifier: "MFATOTPViewController")
            as! MFATOTPViewController
        
        controller.factor = factor
        controller.activateHandler = activationHandler
        
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        activateHandler?()
    }
    
    func requestTOTP(callback: @escaping ((String) -> Void)) {
        onVerify = callback
    }
    
    @IBAction func verifyTapped() {
        guard let code = codeField.text else { return }
        onVerify?(code)
    }
    
    private func configure() {
        guard isViewLoaded else { return }
        titleLabel.text = factor?.vendorName ?? "Unknown Vendor"
    }
}
