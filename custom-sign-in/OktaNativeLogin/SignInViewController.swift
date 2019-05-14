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

class SignInViewController: AuthBaseViewController {

    class func instantiate() -> SignInViewController {
        let signInStoryboard = UIStoryboard(name: "SignIn", bundle: nil)
        let signInViewController = signInStoryboard.instantiateViewController(withIdentifier: "SignInViewController") as! SignInViewController
        return signInViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This line needed for setting up AuthenticationClient when running UI tests
        //guard setupForUITests() else { return }
    }

    // MARK: - IB
    
    @IBOutlet private var usernameField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var signInButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    @IBAction private func signInTapped() {
        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty else { return }
        
        #warning ("Enter your Okta organization domain here")
        //let url = URL(string: "https://{yourOktaDomain}")!
        let url = URL(string: "https://sdk-test.trexcloud.com")!
        OktaAuthSdk.authenticate(with: url,
                                 username: username,
                                 password: password,
                                 onStatusChange:
            { status in
                self.hideProgress()
                self.flowCoordinatorDelegate?.onStatusChanged(status: status)
        })  { error in
                self.hideProgress()
                self.showError(message: error.description)
        }
        showProgress()
    }
}

// UI Utils
private extension SignInViewController {

    func showProgress() {
        activityIndicator.startAnimating()
        signInButton.isEnabled = false
    }
    
    func hideProgress() {
        activityIndicator.stopAnimating()
        signInButton.isEnabled = true
    }
    /*
    func showAccountLockedAlert(and callback: @escaping (_ username: String) -> Void) {
        let alert = UIAlertController(title: "Account Locked", message: "To unlock account enter email or username.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Email or Username"}
        alert.addAction(UIAlertAction(title: "Send Email", style: .default, handler: { _ in
            guard let username = alert.textFields?[0].text else { return }
            callback(username)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentAlert(alert)
    }
    
    func showUnlockEmailIsSentAlert() {
        let alert = UIAlertController(title: "Email sent!", message: "Email has been sent to your email address with instructions on unlocking your account.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentAlert(alert)
    }
 */
}
/*
private extension SignInViewController {
    func setupForUITests() -> Bool {
        guard let testURL = ProcessInfo.processInfo.environment["OKTA_URL"],
              let testConfig = configForUITests
              else { return true }
        //client = AuthenticationClient(oktaDomain: URL(string: testURL)!, delegate: self, mfaHandler: self)
        //oktaOidc = try! OktaOidc(configuration: OktaOidcConfig(with: testConfig))
        return false
    }
    
    var configForUITests: [String: String]? {
        let env = ProcessInfo.processInfo.environment
        guard let oktaURL = env["OKTA_URL"],
            let clientID = env["CLIENT_ID"],
            let redirectURI = env["REDIRECT_URI"],
            let logoutRedirectURI = env["LOGOUT_REDIRECT_URI"] else {
                return nil
        }
        return ["issuer": "\(oktaURL)/oauth2/default",
                "clientId": clientID,
                "redirectUri": redirectURI,
                "logoutRedirectUri": logoutRedirectURI,
                "scopes": "openid profile offline_access"
        ]
    }
}
*/
