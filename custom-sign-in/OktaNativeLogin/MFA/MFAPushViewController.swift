//
//  MFAPushViewController.swift
//  OktaNativeLogin
//
//  Created by Anastasiia Iurok on 2/1/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuthSdk

class MFAPushViewController : UIViewController {

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var pushButton: UIButton!

    private var factor: EmbeddedResponse.Factor? {
        didSet {
            configure()
        }
    }
    
    private var onPushTapped: (() -> Void)?
    private var onResendTapped: (() -> Void)?
    
    private var isPushTapped: Bool = false {
        didSet {
            configurePushButton()
        }
    }

    static func create(with factor: EmbeddedResponse.Factor, pushHandler: (() -> Void)?, resendHander: (() -> Void)?) -> MFAPushViewController {
        let controller = UIStoryboard(name: "MFAPush", bundle: nil)
            .instantiateViewController(withIdentifier: "MFAPushViewController")
            as! MFAPushViewController
        controller.factor = factor
        controller.onPushTapped = pushHandler
        controller.onResendTapped = resendHander
        
        return controller
    }
    
    override func viewDidLoad() {
        configure()
    }
    
    @IBAction private func pushTapped() {
        if isPushTapped {
            onResendTapped?()
        } else {
            onPushTapped?()
            isPushTapped = true
        }
    }
    
    private func configure() {
        guard isViewLoaded else { return }

        titleLabel.text = factor?.vendorName ?? "Unknown Vendor"
        configurePushButton()
    }
    
    private func configurePushButton() {
        pushButton.setTitle(isPushTapped ? "Resend Push" : "Send Push", for: .normal)
    }
}
