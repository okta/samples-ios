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

final class WelcomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        do {
            if let configForUITests = configForUITests {
                AppDelegate.shared.oktaOidc = try OktaOidc(configuration: OktaOidcConfig(with: configForUITests))
            } else {
                AppDelegate.shared.oktaOidc = try OktaOidc()
            }
            
            AppDelegate.shared.stateManager = OktaOidcStateManager.readFromSecureStorage(for: AppDelegate.shared.oktaOidc!.configuration)
            
        } catch {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                exit(1)
            }))
            self.present(alert, animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = AppDelegate.shared.stateManager?.accessToken {
            performSegue(withIdentifier: "show-details", sender: self)
        }
    }
    
    @IBAction private func signInTapped() {   
        AppDelegate.shared.oktaOidc?.signInWithBrowser(from: self, callback: { [weak self] stateManager, error in
            if let error = error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
                return
            }
            AppDelegate.shared.stateManager?.clear()
            AppDelegate.shared.stateManager = stateManager
            stateManager?.writeToSecureStorage()
            self?.performSegue(withIdentifier: "show-details", sender: self)
        })
    }
}

// UI Tests
private extension WelcomeViewController {
    var configForUITests: [String: String]? {
        let env = ProcessInfo.processInfo.environment
        guard let oktaURL = env["OKTA_URL"],
              oktaURL.count > 0,
              let clientID = env["CLIENT_ID"],
              let redirectURI = env["REDIRECT_URI"],
              let logoutRedirectURI = env["LOGOUT_REDIRECT_URI"] else {
                return nil
        }
        return ["issuer": oktaURL,
            "clientId": clientID,
            "redirectUri": redirectURI,
            "logoutRedirectUri": logoutRedirectURI,
            "scopes": "openid profile offline_access"
        ]
    }
}
