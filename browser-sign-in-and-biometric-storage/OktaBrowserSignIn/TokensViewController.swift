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
import OktaOidc

class TokensViewController: UIViewController {

    @IBOutlet private var tokensView: UITextView!
    
    @IBOutlet private var introspectButton: UIButton!
    @IBOutlet private var refreshButton: UIButton!
    @IBOutlet private var revokeButton: UIButton!
    
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    var stateManager: OktaOidcStateManager?
    
    static func fromStoryboard() -> TokensViewController {
        return UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "TokensViewController")
            as! TokensViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configure()
    }
    
    @IBAction func introspectTapped() {
        guard let accessToken = self.stateManager?.accessToken else { return }
        
        self.stateManager?.introspect(token: accessToken, callback: { payload, error in
            if let error = error {
                self.showError(error.localizedDescription)
                return
            }
            
            guard let isValid = payload?["active"] as? Bool else {
                self.showError("Unexpected payload!")
                return
            }

            self.showAlert(title: "Access token is \(isValid ? "valid" : "invalid")!")
        })
    }
    
    @IBAction func refreshTapped() {
        self.stateManager?.renew(callback: { stateManager, error in
            if let error = error {
                self.showError(error.localizedDescription)
                return
            }
            
            self.configure()
            self.showAlert(title: "Token refreshed!")
        })
    }
    
    @IBAction func revokeTapped() {
        guard let accessToken = self.stateManager?.accessToken else { return }
        
        self.stateManager?.revoke(accessToken, callback: { isRevoked, error in
            guard isRevoked else {
                self.showError( error?.localizedDescription ?? "Failed to revoked access token!")
                return
            }
            
            self.showAlert(title: "Access token revoked!")
            self.configure()
        })
    }
}

// UI Utils
private extension TokensViewController {
    func configure() {
        guard isViewLoaded else { return }
        
        var tokens = ""
        if let accessToken = self.stateManager?.accessToken {
            tokens += "Access token: \(accessToken)\n\n"
        }
        
        if let refreshToken = self.stateManager?.refreshToken {
            tokens += "Refresh token: \(refreshToken)\n\n"
        }
        
        if let idToken = self.stateManager?.idToken {
            tokens += "ID token: \(idToken)"
        }
        
        tokensView.text = tokens
    }
    
    func showAlert(title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showError(_ message: String) {
        self.showAlert(title: "Error", message: message)
    }
    
    func startProgress() {
        self.activityIndicator.startAnimating()
        self.introspectButton.isEnabled = false
        self.refreshButton.isEnabled = false
        self.revokeButton.isEnabled = false
    }
    
    func stopProgress() {
        self.activityIndicator.stopAnimating()
        self.introspectButton.isEnabled = true
        self.refreshButton.isEnabled = true
        self.revokeButton.isEnabled = true
    }
}
