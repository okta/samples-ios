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
import OktaAuthSdk
import OktaOidc
import SVProgressHUD
import SafariServices

class UserProfileViewController: AuthBaseViewController {
    
    var successStatus: OktaAuthStatusSuccess?
    var oidcStateManager: OktaOidcStateManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        successStatus = status as? OktaAuthStatusSuccess
        titleLabel.text = "Welcome, \(successStatus?.model.embedded?.user?.profile?.firstName ?? "-")"
        subtitleLabel.text = successStatus?.model.embedded?.user?.profile?.login
        timezoneLabel.text = successStatus?.model.embedded?.user?.profile?.timeZone
        localeLabel.text = successStatus?.model.embedded?.user?.profile?.locale
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard let oidcClient = self.createOidcClient() else {
                return
            }
            SVProgressHUD.show(withStatus: "Asking OIDC client for access token...")
            oidcClient.authenticate(withSessionToken: self.successStatus!.sessionToken!, callback: { [weak self] stateManager, error in
                SVProgressHUD.dismiss()
                if let _ = stateManager?.accessToken {
                    self?.accessTokenLabel.text = "YES"
                    self?.accessTokenLabel.textColor = UIColor(red: 0, green: 255, blue: 0, alpha: 1)
                }
                if let _ = stateManager?.refreshToken {
                    self?.refreshTokenLabel.text = "YES"
                    self?.refreshTokenLabel.textColor = UIColor(red: 0, green: 255, blue: 0, alpha: 1)
                }
                if let stateManager = stateManager {
                    self?.oidcStateManager = stateManager
                    self?.viewTokensButton.isEnabled = true
                    self?.logoutButton.isEnabled = true
                }
                
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTokens" {
            guard let controller = segue.destination as? TokensViewController else {
                return
            }
            
            controller.stateManager = self.oidcStateManager
        }
    }
    
    func createOidcClient() -> OktaOidc? {
        var oidcClient: OktaOidc?
        if let config = self.readTestConfig() {
            oidcClient = try? OktaOidc(configuration: config)
        } else {
            oidcClient = try? OktaOidc()
        }

        return oidcClient
    }

    // MARK: - IB

    @IBAction private func logoutTapped() {
        if let oidcStateManager = self.oidcStateManager {
            let oidcClient = self.createOidcClient()
            oidcClient?.signOutOfOkta(oidcStateManager, from: self, callback: { [weak self] error in
                if let error = error {
                    self?.showError(message: error.localizedDescription)
                } else {
                    self?.flowCoordinatorDelegate?.onLoggedOut()
                }
            })
        }
    }
    
    @IBAction func launchWebAppTapped(_ sender: Any) {
        let bootstrapUrl: String = getConfig()!["bootstrap_url"] as! String
        let refreshToken : String = (oidcStateManager?.refreshToken)!
        getBootstrapToken(refreshToken: refreshToken) { (bootstrapToken) in
            let finalUrl: String = bootstrapUrl + "?access_token=" + bootstrapToken
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true

            let url = URL(string: finalUrl)
            DispatchQueue.main.sync {
                let vc = SFSafariViewController(url: url!, configuration: config)
                self.present(vc, animated: true)
            }
        }
    }
    
    func getBootstrapToken(refreshToken: String, completion: @escaping (String) -> ()) {
        let issuer: String = getConfig()!["issuer"] as! String
        let tokenUrl = issuer + "/v1/token"
        let client_id: String = getConfig()!["clientId"] as! String
        let serviceUrl: URL = URL(string: tokenUrl)!

        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let httpBody: String = "grant_type=refresh_token&scope=web_session&refresh_token=" + refreshToken + "&client_id=" + client_id
        
        request.httpBody = httpBody.data(using: .utf8)
        request.timeoutInterval = 20
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    print(json)
                    print(json!["access_token"] as? String)
                    completion(json!["access_token"] as! String)
                } catch {
                    print(error)
                }
            }
        }.resume()
    }

    func getConfig() -> [String: Any]? {
        if  let path = Bundle.main.path(forResource: "Okta", ofType: "plist"),
            let xml = FileManager.default.contents(atPath: path)
        {
            return (try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil)) as? [String: Any]
        }

        return nil
    }
    
    @IBOutlet weak var launchWebAppButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var timezoneLabel: UILabel!
    @IBOutlet weak var localeLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var viewTokensButton: UIButton!
    @IBOutlet weak var accessTokenLabel: UILabel!
    @IBOutlet weak var refreshTokenLabel: UILabel!
}

private extension UserProfileViewController {
    func readTestConfig() -> OktaOidcConfig? {
        guard let _ = ProcessInfo.processInfo.environment["OKTA_URL"],
              let testConfig = configForUITests else {
                return nil
                
        }

        return try? OktaOidcConfig(with: testConfig)
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
