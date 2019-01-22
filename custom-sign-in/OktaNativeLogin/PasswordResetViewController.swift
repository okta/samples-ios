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
    
    typealias PasswordResetCompletionHandler = (_ oldPassword: String, _ newPassword: String) -> Void
    
    private var completionHandler: PasswordResetCompletionHandler?
   
    @discardableResult
    static func loadAndPresent(from presentingController: UIViewController, completion: @escaping PasswordResetCompletionHandler) -> PasswordResetViewController {
        let navigation = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "ResetNavigationController")
            as! UINavigationController
        
        let controller = navigation.topViewController as! PasswordResetViewController
        controller.completionHandler = completion
        
        presentingController.present(navigation, animated: true)
        
        return controller
    }
    
    @IBAction private func resetTapped() {
        guard let oldPassword = oldPasswordField.text, !oldPassword.isEmpty,
              let newPassword = newPasswordField.text, !newPassword.isEmpty,
              newPassword == confirmPasswordField.text else {
              return
        }
        
        self.dismiss(animated: true) {
            self.completionHandler?(oldPassword, newPassword)
        }
    }
    
    @IBAction private func cancelTapped() {
        self.dismiss(animated: true)
    }
}
