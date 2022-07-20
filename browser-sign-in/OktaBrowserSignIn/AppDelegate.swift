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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        
        if ProcessInfo.processInfo.arguments.contains("--reset-keychain") {
            try? Keychain.Search().delete()
        }
        window?.rootViewController = self.getRootViewController()
        window?.makeKeyAndVisible()
        return true
    }
    
    func getRootViewController() -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let _ = Credential.default else {
            let welcomeViewController = storyboard.instantiateViewController(withIdentifier: "SignIn") as? WelcomeViewController
            if let configForUITests = configForUITests {
                welcomeViewController?.auth = WebAuthentication(
                    issuer: URL(string: configForUITests["issuer"]!)!,
                    clientId: configForUITests["clientId"]!,
                    scopes: configForUITests["scopes"]!,
                    redirectUri: URL(string: configForUITests["redirectUri"]!)!,
                    logoutRedirectUri: URL(string: configForUITests["logoutRedirectUri"] ?? ""),
                    additionalParameters: nil)
            } else {
                welcomeViewController?.auth = WebAuthentication.shared
            }
            return welcomeViewController
        }
        let profileViewController = storyboard.instantiateViewController(withIdentifier: "Profile")
        return profileViewController
    }
    
    func applicationWillResignActive(_ application: UIApplication) { }
    
    func applicationDidEnterBackground(_ application: UIApplication) { }
    
    func applicationWillEnterForeground(_ application: UIApplication) { }
    
    func applicationDidBecomeActive(_ application: UIApplication) { }
    
    func applicationWillTerminate(_ application: UIApplication) { }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        do {
            try WebAuthentication.shared?.resume(with: url)
        } catch {
            print(error)
        }
        return true
    }
}

