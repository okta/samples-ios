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

    let secureStorage = OktaSecureStorage(applicationPassword: "password")
    
    var tokenManager: OktaTokenManager?
    
    private var authState: OktaTokenManager? {
        return OktaAuth.tokens
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.readTokenManagerFromKeychain(completion: { success in
            self.updateUI()
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    @IBAction func signInTapped() {
        self.showProgress()

        OktaAuth.signInWithBrowser().start(self)
        .then { tokenManager in
            self.tokenManager = tokenManager
            self.hideProgress()
            self.showAlert(title: "Signed In!")
            self.updateUI()

            guard let authStateData = try? NSKeyedArchiver.archivedData(withRootObject: self.tokenManager!, requiringSecureCoding: false) else {
                return
            }
            do {
                try self.secureStorage.set(data: authStateData,
                                           forKey: "okta_user",
                                           behindBiometrics: self.secureStorage.isTouchIDSupported() || self.secureStorage.isFaceIDSupported())
            } catch let error as NSError {
                let alert = UIAlertController(title: "Storage Error", message: "Error with error code: \(error.code)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
        }.catch { error in
            self.hideProgress()
            self.showError(message: error.localizedDescription)
        }
    }
    
    @IBAction func signOutTapped() {
        self.showProgress()
        
        OktaAuth.signOutOfOkta().start(self)
        .then {
            self.authState?.clear()
            try? self.secureStorage.clear()
            self.tokenManager = nil
            self.hideProgress()
            self.showAlert(title: "Signed Out!")
            self.updateUI()
        }.catch { error in
            self.hideProgress()
            self.showError(message: error.localizedDescription)
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

    @IBAction func tokensTapped() {
        guard let _ = self.tokenManager?.accessToken else {
            return
        }

        self.readTokenManagerFromKeychain(completion: { success in
            if success {
                self.presentTokenDetails()
            }
        })
    }
}

// UI Utils
private extension SingInViewController {
    func updateUI() {
        guard isViewLoaded else { return }
    
        guard let _ = self.tokenManager?.accessToken else {
            loggedInUserInfoContainer.isHidden = true
            statusLabel.text = "Unathenticated ✗"
            
            signInButton.isHidden = false
            signOutButton.isHidden = true
            return
        }

        self.loggedInUserInfoContainer.isHidden = false
        self.statusLabel.text = "Athenticated ✓"
        
        self.signInButton.isHidden = true
        self.signOutButton.isHidden = false
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

    func presentTokenDetails() {
        let controller = TokensViewController.fromStoryboard()
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func readTokenManagerFromKeychain(completion: @escaping (_ success: Bool) -> Void) {
        DispatchQueue.global().async {
            do {
                let authStateData = try self.secureStorage.getData(key: "okta_user")
                guard let tokenManager = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(authStateData) as? OktaTokenManager else {
                    return
                }

                self.tokenManager = tokenManager

                DispatchQueue.main.async {
                    self.updateUI()
                    completion(true)
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    if error.code == errSecItemNotFound {
                        return
                    } else if error.code == errSecUserCanceled {
                        self .readTokenManagerFromKeychain(completion: completion)
                    } else {
                        let alert = UIAlertController(title: "Storage Error", message: "Error with error code: \(error.code)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        completion(false)
                    }
                }
            }
        }
    }
}

