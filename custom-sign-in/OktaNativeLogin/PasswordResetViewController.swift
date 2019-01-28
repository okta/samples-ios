//
//  PasswordResetViewController.swift
//  OktaNativeLogin
//
//  Created by Anastasiia Iurok on 1/22/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit

class PasswordResetViewController: UIViewController {
    
    @IBOutlet private var oldPasswordField: UITextField!
    @IBOutlet private var newPasswordField: UITextField!
    @IBOutlet private var confirmPasswordField: UITextField!
    
    @IBOutlet private var cancelButton: UIButton!
    
    typealias PasswordResetCompletionHandler = (_ oldPassword: String?, _ newPassword: String?, _ skip: Bool) -> Void
    
    private var completionHandler: PasswordResetCompletionHandler?
    private var canSkip = false {
        didSet {
            configure()
        }
    }
   
    @discardableResult
    static func loadAndPresent(from presentingController: UIViewController, canSkip: Bool, completion: @escaping PasswordResetCompletionHandler) -> PasswordResetViewController {
        let navigation = UIStoryboard(name: "PasswordReset", bundle: nil)
            .instantiateViewController(withIdentifier: "ResetNavigationController")
            as! UINavigationController
        
        let controller = navigation.topViewController as! PasswordResetViewController
        controller.completionHandler = completion
        controller.canSkip = canSkip
        
        presentingController.present(navigation, animated: true)
        
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    @IBAction private func resetTapped() {
        guard let oldPassword = oldPasswordField.text, !oldPassword.isEmpty,
              let newPassword = newPasswordField.text, !newPassword.isEmpty,
              newPassword == confirmPasswordField.text else {
              return
        }
        
        self.dismiss(animated: true) {
            self.completionHandler?(oldPassword, newPassword, false)
        }
    }
    
    @IBAction private func cancelTapped() {
        self.dismiss(animated: true) {
            if self.canSkip {
                self.completionHandler?(nil, nil, true)
            }
        }
    }
    
    private func configure() {
        guard isViewLoaded else { return }
        cancelButton.setTitle(canSkip ? "Skip" : "Cancel", for: .normal)
    }
}
