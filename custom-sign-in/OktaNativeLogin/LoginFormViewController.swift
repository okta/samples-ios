/*
 * Copyright 2019 Okta, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

