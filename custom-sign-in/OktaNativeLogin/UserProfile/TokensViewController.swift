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
    @IBOutlet private var refreshButton: UIButton!
    
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    var stateManager: OktaOidcStateManager? {
        didSet {
            configure()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configure()
    }
    
    @IBAction func refreshTapped() {
        stateManager?.renew(callback: { stateManager, error in
            if let error = error {
                self.showError(error.localizedDescription)
                return
            }

            self.configure()
            self.showAlert(title: "Token refreshed!")
        })
    }
}

// UI Utils
private extension TokensViewController {
    func configure() {
        guard isViewLoaded else { return }
        
        var tokens = ""
        if let accessToken = stateManager?.accessToken,
           let decodedToken = try? OktaOidcStateManager.decodeJWT(accessToken) {
            tokens += "Access token:\n\(decodedToken)\n\n"
            print("Access token:\n\(decodedToken)")
        }
        
        if let refreshToken = stateManager?.refreshToken {
            tokens += "Refresh token:\n\(refreshToken)\n\n"
        }
        
        if let idToken = stateManager?.idToken,
           let decodedToken = try? OktaOidcStateManager.decodeJWT(idToken) {
            tokens += "ID token:\n\(decodedToken)"
            print("ID token:\n\(decodedToken)")
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
        self.refreshButton.isEnabled = false
    }
    
    func stopProgress() {
        self.activityIndicator.stopAnimating()
        self.refreshButton.isEnabled = true
    }
}
