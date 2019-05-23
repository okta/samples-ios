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
import SVProgressHUD

class SignInViewController: AuthBaseViewController {

    #warning ("Enter your Okta organization domain here")
    var urlString = "https://sdk-test-admin.trexcloud.com"

    class func instantiate() -> SignInViewController {
        let signInStoryboard = UIStoryboard(name: "SignIn", bundle: nil)
        let signInViewController = signInStoryboard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
        return signInViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupForUITests()
    }

    private func startForgotPasswordFlowWithFactor(_ factor: OktaRecoveryFactors) {
        guard let username = usernameField.text, !username.isEmpty else {
            showError(message: "Pleas enter username")
            return
        }
        SVProgressHUD.show()
        OktaAuthSdk.recoverPassword(with: URL(string: urlString)!,
                                    username: username,
                                    factorType: factor,
                                    onStatusChange:
            { status in
                SVProgressHUD.dismiss()
                self.flowCoordinatorDelegate?.onStatusChanged(status: status)
        })  { error in
            SVProgressHUD.dismiss()
            self.showError(message: error.description)
        }
    }

    // MARK: - IB
    
    @IBOutlet private var usernameField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var signInButton: UIButton!
    
    @IBAction private func signInTapped() {
        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty else { return }

        SVProgressHUD.show()
        OktaAuthSdk.authenticate(with: URL(string: urlString)!,
                                 username: username,
                                 password: password,
                                 onStatusChange:
            { status in
                SVProgressHUD.dismiss()
                self.flowCoordinatorDelegate?.onStatusChanged(status: status)
        })  { error in
                SVProgressHUD.dismiss()
                self.showError(message: error.description)
        }
    }

    @IBAction private func forgotPasswordTapped() {
        let alert = UIAlertController(title: "Select recovery factor", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "EMAIL", style: .default, handler: { _ in
            self.startForgotPasswordFlowWithFactor(.email)
        }))
        alert.addAction(UIAlertAction(title: "SMS", style: .default, handler: { _ in
            self.startForgotPasswordFlowWithFactor(.sms)
        }))
        alert.addAction(UIAlertAction(title: "CALL", style: .default, handler: { _ in
            self.startForgotPasswordFlowWithFactor(.call)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

private extension SignInViewController {
    func setupForUITests() {
        guard let url = ProcessInfo.processInfo.environment["OKTA_URL"] else {
                return
        }
        
        urlString = url
    }
}

