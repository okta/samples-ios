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
            self.updateTokenInfo()
            credential?.automaticRefresh = true
            credential?.refreshIfNeeded { _ in
                DispatchQueue.main.async {
                    self.updateTokenInfo()
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
        self.credential = Credential.default
    }
    
    @IBAction func introspectTapped() {
        guard let credential = self.credential else {
            self.show(title: "An unexpected error occured with the token lifecycle.")
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
        guard let credential = self.credential else {
            self.show(title: "An unexpected error occured with the token lifecycle.")
            return
        }
        
        credential.refresh(completion: { result in
            switch result {
            case .failure(let error):
                self.show(title: "Error refreshing token", error: error.localizedDescription)
            case .success:
                self.show(title: "Token refreshed!")
                self.updateTokenInfo()
            }
        })
    }
    
    @IBAction func revokeTapped() {
        guard let credential = self.credential else {
            self.show(title: "Unable to Revoke Token",
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
}

// UI Utils
private extension TokensViewController {    
    func updateTokenInfo() {
        guard let token = self.credential?.token else {
            tokensView.text = "No token was found"
            return
        }
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byCharWrapping
        paragraph.paragraphSpacing = 15
        
        let bold = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)]
        let normal = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
                      NSAttributedString.Key.paragraphStyle: paragraph]
        
        func addString(to string: NSMutableAttributedString, title: String, value: String) {
            string.append(NSAttributedString(string: "\(title):\n", attributes: bold))
            string.append(NSAttributedString(string: "\(value)\n", attributes: normal))
        }
        
        let string = NSMutableAttributedString()
        addString(to: string, title: "Access token", value: token.accessToken)
        
        if let refreshToken = token.refreshToken {
            addString(to: string, title: "Refresh token", value: refreshToken)
        }
        
        addString(to: string, title: "Expires in", value: "\(token.expiresIn) seconds")
        addString(to: string, title: "Scope", value: token.scope ?? "N/A")
        addString(to: string, title: "Token type", value: token.tokenType)
        
        if let idToken = token.idToken {
            addString(to: string, title: "ID token", value: idToken.rawValue)
        }
        
        tokensView.attributedText = string
    }
}
