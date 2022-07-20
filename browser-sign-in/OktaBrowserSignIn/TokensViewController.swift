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
    var token: Token? {
        didSet {
            DispatchQueue.main.async {
                self.showTokenInfo()
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
            guard let user = notification.object as? Credential else { return }
            self.token = user.token
        }
        self.token = Credential.default?.token
    }
    
    @IBAction func introspectTapped() {
        guard let credential = Credential.default else { return  }
        credential.introspect(.accessToken, completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tokenInfo):
                    guard let isValid = tokenInfo.payload["active"] as? Bool else { return }
                    self.showAlert(title: "Access token is \(isValid ? "valid" : "invalid")!")
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.showError(error.localizedDescription)
                    }
                }
            }
        })
    }
    
    @IBAction func refreshTapped() {
        guard let credential = Credential.default
        else {
            self.showAlert(title: "Unable to Refresh Token",
                           message: "an unknown issue prevented refreshing the token. Please try again.")
            return
        }
        
        credential.refreshIfNeeded { result in
            if case let .failure(error) = result {
                DispatchQueue.main.async {
                    self.showError(error.localizedDescription)
                }
            }
            self.showTokenInfo()
            self.showAlert(title: "Token refreshed!")
        }
    }
    
    @IBAction func revokeTapped() {
        guard let credential = Credential.default else { return  }
        credential.revoke {[weak self] result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Sign out failed",
                                                  message: error.localizedDescription,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            case .success:
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}

// UI Utils
private extension TokensViewController {    
    func showTokenInfo() {
        guard let token = token else {
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
    
    func showAlert(title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showError(_ message: String) {
        self.showAlert(title: "Error", message: message)
    }
}
