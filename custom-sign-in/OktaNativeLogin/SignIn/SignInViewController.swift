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
    var urlString = "https://idx-devex.trexcloud.com"

    class func instantiate() -> SignInViewController {
        let signInStoryboard = UIStoryboard(name: "SignIn", bundle: nil)
        let signInViewController = signInStoryboard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
        return signInViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupForUITests()
    }

    public func handleLockedOutStatus(status: OktaAuthStatusLockedOut) {
        let alert = UIAlertController(title: "Account Locked", message: "Your account is locked.\nWould you like to unlock account?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Unlock", style: .default, handler: { _ in
            self.showAlertWithRecoverOptions(isPasswordRecoverFlow: false)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    public func handleLockedOutSuccessStatus() {
        let alert = UIAlertController(title: "Success", message: "Your account has been successfully unlocked", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func startRecoverFlowWithFactor(_ factor: OktaRecoveryFactors, isPasswordRecoverFlow: Bool) {
        guard let username = usernameField.text, !username.isEmpty else {
            showError(message: "Please enter username")
            return
        }

        SVProgressHUD.show()
        if isPasswordRecoverFlow {
            OktaAuthSdk.recoverPassword(with: URL(string: urlString)!,
                                        username: username,
                                        factorType: factor,
                                        onStatusChange:
                { [weak self] status in
                    SVProgressHUD.dismiss()
                    self?.flowCoordinatorDelegate?.onStatusChanged(status: status)
            })  { [weak self] error in
                SVProgressHUD.dismiss()
                self?.showError(message: error.description)
            }
        } else {
            OktaAuthSdk.unlockAccount(with: URL(string: urlString)!,
                                      username: username,
                                      factorType: factor,
                                      onStatusChange:
                { [weak self] status in
                    SVProgressHUD.dismiss()
                    self?.flowCoordinatorDelegate?.onStatusChanged(status: status)
            })  { [weak self] error in
                SVProgressHUD.dismiss()
                self?.showError(message: error.description)
            }
        }
    }

    // MARK: - IB
    
    @IBOutlet private var usernameField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var signInButton: UIButton!
    
    @IBAction private func signInTapped() {
        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty else { return }
        
        let successBlock: (OktaAuthStatus) -> Void = { [weak self] status in
            SVProgressHUD.dismiss()
            self?.flowCoordinatorDelegate?.onStatusChanged(status: status)
        }

        let errorBlock: (OktaError) -> Void = { [weak self] error in
            SVProgressHUD.dismiss()
            self?.showError(message: error.description)
        }

        SVProgressHUD.show()

        if isMockExample() {
            let unauthenticatedStatus = UnauthenticatedStatusMock(oktaDomain: URL(string: "https://www.dummy.com")!,
                                                                  responseHandler: CustomAuthResponseHandler())
            unauthenticatedStatus.authenticate(username: username,
                                               password: password,
                                               onStatusChange: successBlock,
                                               onError: errorBlock)
        } else {
            OktaAuthSdk.authenticate(with: URL(string: urlString)!,
                                     username: username,
                                     password: password,
                                     onStatusChange: successBlock,
                                     onError: errorBlock)
        }
    }

    func showAlertWithRecoverOptions(isPasswordRecoverFlow: Bool) {
        let alert = UIAlertController(title: "Select recovery factor", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "EMAIL", style: .default, handler: { _ in
            self.startRecoverFlowWithFactor(.email, isPasswordRecoverFlow: isPasswordRecoverFlow)
        }))
        alert.addAction(UIAlertAction(title: "SMS", style: .default, handler: { _ in
            self.startRecoverFlowWithFactor(.sms, isPasswordRecoverFlow: isPasswordRecoverFlow)
        }))
        alert.addAction(UIAlertAction(title: "CALL", style: .default, handler: { _ in
            self.startRecoverFlowWithFactor(.call, isPasswordRecoverFlow: isPasswordRecoverFlow)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction private func forgotPasswordTapped() {
        self.showAlertWithRecoverOptions(isPasswordRecoverFlow: true)
    }
}

private extension SignInViewController {
    func setupForUITests() {
        guard let url = ProcessInfo.processInfo.environment["OKTA_URL"] else {
            return
        }
        
        urlString = url
    }

    func isMockExample() -> Bool {
        guard let _ = ProcessInfo.processInfo.environment["MOCK_EXAMPLE"] else {
            return false
        }

        return true
    }
}

