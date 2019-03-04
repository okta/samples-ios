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

    private var factor: EmbeddedResponse.Factor? {
        didSet {
            configure()
        }
    }
    
    private var onPushTapped: (() -> Void)?

    static func create(with factor: EmbeddedResponse.Factor, pushHandler: (() -> Void)?) -> MFAPushViewController {
        let controller = UIStoryboard(name: "MFAPush", bundle: nil)
            .instantiateViewController(withIdentifier: "MFAPushViewController")
            as! MFAPushViewController
        controller.factor = factor
        controller.onPushTapped = pushHandler
        
        return controller
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
