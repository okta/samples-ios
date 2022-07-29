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
import WebAuthenticationUI

class TokensViewController: UIViewController {
    var credential: Credential? {
        didSet {
            showTokenInfo()
            credential?.automaticRefresh = true
            credential?.refreshIfNeeded { _ in
                DispatchQueue.main.async {
                    self.showTokenInfo()
                }
            }
        }
    }
    
    @IBOutlet private var tokensView: UITextView!
    @IBOutlet private var introspectButton: UIButton!
    @IBOutlet private var refreshButton: UIButton!
    @IBOutlet private var revokeButton: UIButton!
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(forName: .defaultCredentialChanged,
                                               object: nil,
                                               queue: .main) { (notification) in
            guard let credential = notification.object as? Credential else { return }
            self.credential = credential
        }
        credential = Credential.default
    }
    
    @IBAction func introspectTapped() {
        guard let credential = credential else {
            show(title: "An unexpected error occured with the token lifecycle.")
            return
        }
        credential.introspect(.accessToken, completion: { result in
            switch result {
            case .success(let tokenInfo):
                guard let isValid = tokenInfo.active else {
                    self.show(title: "An unexpected error occured with the TokenInfo")
                    return
                }
                let tokenValidity = isValid ? "valid" : "inValid"
                self.show(title: "Access token is \(tokenValidity)!")
            case .failure(let error):
                self.show(title: "Error", error: error.localizedDescription)
            }
        })
    }
    
    @IBAction func refreshTapped() {
        guard let credential = credential else {
            show(title: "Unable to Refresh Token", error: "An unknown issue prevented refreshing the token. Please try again.")
            return
        }
        
        credential.refreshIfNeeded(completion: { result in
            switch result {
            case .failure(let error):
                self.show(title: "Unable to Refresh Tokenn", error: error.localizedDescription)
            case .success:
                self.showTokenInfo()
            }
        })
    }
    
    @IBAction func revokeTapped() {
        guard let credential = credential else {
            show(title: "Unable to Revoke Token",
                      error: "an unknown issue prevented revoking the token. Please try again.")
            return
        }
        
        credential.revoke { result in
            switch result {
            case .failure(let error):
                self.show(title: "Sign out failed", error: error.localizedDescription)
            case .success:
                DispatchQueue.main.async {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    func showTokenInfo() {
        tokensView.text = ""
        var tokenString = "Unable to show token"
        if let token = Credential.default?.token {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .medium
            dateFormatter.dateStyle = .medium
            
            tokenString = ""
            if let issued = token.issuedAt {
                tokenString += "Issue Date: \(dateFormatter.string(from: issued))\n"
            }
            if let expiry = token.expiresAt {
                tokenString += "Expiry Date: \(dateFormatter.string(from: expiry))\n"
            }
            if token.isExpired {
                tokenString += "---EXPIRED---\n"
            }
            tokenString += "\nAccess Token\n\n\(token.accessToken)\n\n"
            if let refreshToken = token.refreshToken {
                tokenString += "\nRefresh Token\n\n\(refreshToken)"
            }
        }
        tokensView.text = tokenString
    }
}
