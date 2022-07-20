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

final class WelcomeViewController: UIViewController {
    var auth: WebAuthentication?
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var ephemeralSwitch: UISwitch!
    @IBOutlet weak var clientIdLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        if let configForUITests = configForUITests {
            self.auth = WebAuthentication(
                issuer: URL(string: configForUITests["issuer"]!)!,
                clientId: configForUITests["clientId"]!,
                scopes: configForUITests["scopes"]!,
                redirectUri: URL(string: configForUITests["redirectUri"]!)!,
                logoutRedirectUri: URL(string: configForUITests["logoutRedirectUri"] ?? ""),
                additionalParameters: nil)
        } else {
            self.auth = WebAuthentication.shared
        }
        
        if Credential.default != nil {
            self.performSegue(withIdentifier: "show-details", sender: self)
        }
        
        if let clientId = auth?.signInFlow.client.configuration.clientId {
            self.clientIdLabel.text = "clientId: \(clientId)"
        } else {
            self.clientIdLabel.text = "Not configured"
            self.signInButton.isEnabled = false
        }
    }
    
    func navigateToDetailsPage() {
        guard Credential.default != nil else { return }
        self.performSegue(withIdentifier: "show-details", sender: self)
    }
    
    @IBAction func ephemeralSwitchChanged(_ sender: Any) {
        guard let sender = sender as? UISwitch else { return }
        self.auth?.ephemeralSession = sender.isOn
    }
    
    @IBAction private func signInTapped() {
        let window = viewIfLoaded?.window
        auth?.signIn(from: window) { result in
            switch result {
            case .success(let token):
                do {
                    try Credential.store(token)
                    self.performSegue(withIdentifier: "show-details", sender: self)
                } catch {
                    self.show(error: error)
                    return
                }
                
            case .failure(let error):
                let alert = UIAlertController(title: "Error",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
        }
    }
    
    func show(error: Error) {
        // There's currently no way to know when the ASWebAuthenticationSession will be dismissed,
        // so to ensure the alert can be displayed, we must delay presenting an error until the
        // dismissal is complete.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
            let alert = UIAlertController(
                title: "Cannot sign in",
                message: error.localizedDescription,
                preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            
            self.present(alert, animated: true)
        }
    }
}

// UI Tests
private extension WelcomeViewController {
    var configForUITests: [String: String]? {
        let env = ProcessInfo.processInfo.environment
        guard let oktaURL = env["OKTA_URL"], oktaURL.count > 0,
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
