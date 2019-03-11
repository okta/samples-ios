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
import OktaAuth

class SingInViewController: UIViewController {
    @IBOutlet private var signInButton: UIButton!
    @IBOutlet private var signOutButton: UIButton!
    
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet private var loggedInUserInfoContainer: UIStackView!
    
    @IBOutlet private var userProfileButton: UIButton!
    
    @IBOutlet private var statusLabel: UILabel!
    
    private var authState: OktaTokenManager? {
        return OktaAuth.tokens
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    @IBAction func signInTapped() {
        self.showProgress()

        // This line needed for setting up AuthenticationClient when running UI tests
        guard signInTappedForUITests() else { return }
        
        OktaAuth.signInWithBrowser().start(self).then { _ in
            self.handleOktaAuthSuccess()
        }.catch { error in
            self.handleOktaAuthFailure(error: error)
        }
    }
    
    @IBAction func signOutTapped() {
        self.showProgress()
        
        // This line needed for setting up AuthenticationClient when running UI tests
        guard signOutTappedForUITests() else { return }
        
        OktaAuth.signOutOfOkta().start(self).then {
            self.handleOktaAuthLogoutSuccess()
        }.catch { error in
            self.handleOktaAuthFailure(error: error)
        }
    }
    
    @IBAction func userProfileTapped() {
        guard OktaAuth.isAuthenticated() else { return }
        
        self.showProgress()
        
        OktaAuth.getUser { response, error in
            self.hideProgress()
            
            guard let response = response else {
                self.showError(message: error?.localizedDescription ?? "Unable to get user info. Try re-authorize.")
                return
            }
            
            self.presentUserInfo(response)
        }
    }
}

// UI Utils
private extension SingInViewController {
    func updateUI() {
        guard isViewLoaded else { return }
    
        guard OktaAuth.isAuthenticated() else {
            loggedInUserInfoContainer.isHidden = true
            statusLabel.text = "Unathenticated ✗"
            
            signInButton.isHidden = false
            signOutButton.isHidden = true
            return
        }
        
        loggedInUserInfoContainer.isHidden = false
        statusLabel.text = "Athenticated ✓"
        
        signInButton.isHidden = true
        signOutButton.isHidden = false
    }
    
    func showAlert(title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showError(message: String) {
        showAlert(title: "Error", message: message)
    }
    
    func showProgress() {
        self.activityIndicator.startAnimating()

        self.signInButton.isEnabled = false
        self.signOutButton.isEnabled = false
        self.userProfileButton.isEnabled = false
    }
    
    func hideProgress() {
        self.activityIndicator.stopAnimating()
        
        self.signInButton.isEnabled = true
        self.signOutButton.isEnabled = true
        self.userProfileButton.isEnabled = true
    }
    
    func presentUserInfo(_ userInfo: [String:Any]) {
        var userInfoText = ""
        userInfo.forEach { userInfoText += ("\($0): \($1) \n") }
        self.presentDetails(userInfoText, title: "User Profile")
    }
    
    func presentDetails(_ content: String, title: String) {
        let controller = DetailViewController.fromStoryboard()
        controller.content = content
        controller.title = title
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func handleOktaAuthSuccess() {
        self.hideProgress()
        self.showAlert(title: "Signed In!")
        self.updateUI()
    }
    
    func handleOktaAuthLogoutSuccess() {
        self.authState?.clear()
        self.hideProgress()
        self.showAlert(title: "Signed Out!")
        self.updateUI()
    }
    
    func handleOktaAuthFailure(error: Error) {
        self.hideProgress()
        self.showError(message: error.localizedDescription)
    }
}

// UI Tests
private extension SingInViewController {
    
    func signInTappedForUITests() -> Bool {
        guard let config = configForUITests else { return true }
        OktaAuth.signInWithBrowser().start(withDictConfig: config, view: self).then { _ in
            self.handleOktaAuthSuccess()
        }.catch { error in
            self.handleOktaAuthFailure(error: error)
        }
        return false
    }
    
    func signOutTappedForUITests() -> Bool {
        guard let config = configForUITests else { return true }
        OktaAuth.signOutOfOkta().start(withDictConfig: config, view: self).then {
            self.handleOktaAuthLogoutSuccess()
        }.catch { error in
            self.handleOktaAuthFailure(error: error)
        }
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

