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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy var oktaOidc: OktaOidc = {
        if let configForUITests = AppDelegate.shared.configForUITests {
            return try! OktaOidc(configuration: OktaOidcConfig(with: configForUITests))
        } else {
            return try! OktaOidc()
        }
    }()
    
    lazy var stateManager: OktaOidcStateManager? = {
        return OktaOidcStateManager.readFromSecureStorage(for: AppDelegate.shared.oktaOidc.configuration)
    }()
    
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return false
    }

    func applicationWillResignActive(_ application: UIApplication) { }

    func applicationDidEnterBackground(_ application: UIApplication) { }

    func applicationWillEnterForeground(_ application: UIApplication) { }

    func applicationDidBecomeActive(_ application: UIApplication) { }

    func applicationWillTerminate(_ application: UIApplication) { }
}

// UI Tests
private extension AppDelegate {
    var configForUITests: [String: String]? {
        let env = ProcessInfo.processInfo.environment
        guard let oktaURL = env["OKTA_URL"], oktaURL.count > 0,
            let clientID = env["CLIENT_ID"],
            let redirectURI = env["REDIRECT_URI"],
            let logoutRedirectURI = env["LOGOUT_REDIRECT_URI"] else {
                return nil
        }
        return ["issuer": "\(oktaURL)",
            "clientId": clientID,
            "redirectUri": redirectURI,
            "logoutRedirectUri": logoutRedirectURI,
            "scopes": "openid profile offline_access"
        ]
    }
}
