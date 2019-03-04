//
//  NativeSignInController.swift
//  OktaNativeLogin
//
//  Created by Alex on 9 Jan 19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuthSdk
import OktaAuth

class LoginFormViewController: UIViewController {

    @IBOutlet private var loginField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var loginButton: UIButton!
    
    typealias LoginCompletionHandler = (_ username: String, _ password: String) -> Void
    
    private var loginHandler: LoginCompletionHandler?
   
    @discardableResult
    static func loadAndPresent(from presentingController: UIViewController, completion: @escaping LoginCompletionHandler) -> LoginFormViewController {
        let navigation = UIStoryboard(name: "LoginForm", bundle: nil)
            .instantiateViewController(withIdentifier: "LoginNavigationController")
            as! UINavigationController
        
        let loginController = navigation.topViewController as! LoginFormViewController
        loginController.loginHandler = completion
        
        presentingController.present(navigation, animated: true)
        
        return loginController
    }
    
    @IBAction private func loginTapped() {
        guard let login = loginField.text, !login.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            return
        }
        
        self.dismiss(animated: true) {
            self.loginHandler?(login, password)
        }
    }
    
    @IBAction private func cancelTapped() {
        self.dismiss(animated: true)
    }
}

