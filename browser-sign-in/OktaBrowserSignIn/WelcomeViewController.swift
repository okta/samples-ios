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

    var oktaOidc: OktaOidc?
    var stateManager: OktaOidcStateManager?
    
    @IBOutlet weak var ephemeralSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        if #available(iOS 13.0, *) {
            // We'll allow the switch to be shown
        } else {
            ephemeralSwitch.superview?.isHidden = true
        }
        
        do {
            if let configForUITests = self.configForUITests {
                oktaOidc = try OktaOidc(configuration: OktaOidcConfig(with: configForUITests))
            } else {
                oktaOidc = try OktaOidc()
            }
        } catch let error {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            return
        }
        
        if  let oktaOidc = oktaOidc,
            let _ = OktaOidcStateManager.readFromSecureStorage(for: oktaOidc.configuration)?.accessToken {
            self.stateManager = OktaOidcStateManager.readFromSecureStorage(for: oktaOidc.configuration)
            performSegue(withIdentifier: "show-details", sender: self)
        }
    }

    @IBAction private func signInTapped() {
        if #available(iOS 13.0, *) {
            oktaOidc?.configuration.noSSO = ephemeralSwitch.isOn
        }
        
        oktaOidc?.signInWithBrowser(from: self, callback: { [weak self] stateManager, error in
            if let error = error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
                return
            }
            self?.stateManager?.clear()
            self?.stateManager = stateManager
            self?.stateManager?.writeToSecureStorage()
            self?.performSegue(withIdentifier: "show-details", sender: self)
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? SignInViewController {
            destinationViewController.oktaOidc = self.oktaOidc
            destinationViewController.stateManager = self.stateManager
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
