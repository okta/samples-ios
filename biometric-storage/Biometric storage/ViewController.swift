//
//  ViewController.swift
//  Biometric storage
//
//  Created by Ildar Abdullin on 3/15/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var storeStackView: UIStackView!
    @IBOutlet weak var biometricImageView: UIImageView!
    @IBOutlet weak var readStackView: UIStackView!
    @IBOutlet weak var storeButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        readStackView.isHidden = true
    }


}

