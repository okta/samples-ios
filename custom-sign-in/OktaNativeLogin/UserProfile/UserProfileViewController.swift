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
            SVProgressHUD.show(withStatus: "Asking OIDC client for access token...")
            if let oidcClient = self.createOidcClient() {
                oidcClient.authenticate(withSessionToken: self.successStatus!.sessionToken, callback: { stateManager, error in
                    SVProgressHUD.dismiss()
                    if let _ = stateManager?.accessToken {
                        self.accessTokenLabel.text = "YES"
                        self.accessTokenLabel.textColor = UIColor(red: 0, green: 255, blue: 0, alpha: 1)
                    }
                    if let _ = stateManager?.refreshToken {
                        self.refreshTokenLabel.text = "YES"
                        self.refreshTokenLabel.textColor = UIColor(red: 0, green: 255, blue: 0, alpha: 1)
                    }
                    self.oidcStateManager = stateManager
                })
            } else {
                SVProgressHUD.dismiss()
            }
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
            oidcClient?.signOutOfOkta(oidcStateManager, from: self, callback: { error in
                if let error = error {
                    self.showError(message: error.localizedDescription)
                } else {
                    self.processCancel()
                }
            })
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var timezoneLabel: UILabel!
    @IBOutlet weak var localeLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
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
