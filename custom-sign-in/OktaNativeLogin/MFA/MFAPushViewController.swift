//
//  MFAPushViewController.swift
//  OktaNativeLogin
//
//  Created by Anastasiia Iurok on 2/1/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuthNative

class MFAPushViewController : UIViewController {

    @IBOutlet private var titleLabel: UILabel!

    var factor: EmbeddedResponse.Factor? {
        didSet {
            configure()
        }
    }
    
    var onPushTapped: (() -> Void)?

    static func fromStoryboard() -> MFAPushViewController {
        return UIStoryboard(name: "MFAPush", bundle: nil)
            .instantiateViewController(withIdentifier: "MFAPushViewController")
            as! MFAPushViewController
    }
    
    override func viewDidLoad() {
        configure()
    }
    
    @IBAction private func pushTapped() {
        onPushTapped?()
    }
    
    private func configure() {
        guard isViewLoaded else { return }

        titleLabel.text = factor?.vendorName ?? "Unknown Vendor"
    }
}
