/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import UIKit
import OktaIdxAuth

@IBDesignable
class AuthenticateViewController: UIViewController, SigninController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var nextButton: UIButton!

    var auth: OktaIdxAuth?

    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func nextAction(_ sender: Any) {
        guard let username = usernameField.text, username.count > 0,
              let password = passwordField.text, password.count > 0,
              let auth = auth
        else {
            return
        }
        
        auth.authenticate(username: username, password: password) { (response, error) in
            guard let response = response else {
                self.show(error: error ?? OnboardingError.missingResponse)
                return
            }
            
            self.handle(response: response)
        }
    }
        
    func handle(response: OktaIdxAuth.Response) {
        switch response.status {
        case .success: break
        case .passwordInvalid: break
        case .passwordExpired:
            showChangePassword()
        }
    }
    
    func showChangePassword() {
        guard var viewController = storyboard?.instantiateViewController(identifier: "NewPassword") as? UIViewController & SigninController
        else {
            show(error: OnboardingError.missingViewController)
            return
        }
        
        viewController.auth = auth
        
        navigationController?.setViewControllers([viewController], animated: true)
    }
}
