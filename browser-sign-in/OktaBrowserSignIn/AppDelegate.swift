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
              let logoutRedirectURI = env["LOGOUT_REDIRECT_URI"]
        else {
            return nil
        }
        
        let configuration = [
            "issuer": "\(oktaURL)/oauth2/default",
            "clientId": clientID,
            "redirectUri": redirectURI,
            "logoutRedirectUri": logoutRedirectURI,
            "scopes": "openid profile offline_access"
        ]
        return configuration
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        self.window = window
        
        if ProcessInfo.processInfo.arguments.contains("--reset-keychain") {
            try? Keychain.Search().delete()
        }
        
        NotificationCenter.default.addObserver(forName: .defaultCredentialChanged,
                                               object: nil,
                                               queue: .main) { notification in
            self.setRootViewController()
        }
        
        setRootViewController()
        return true
    }
    
    func setRootViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard Credential.default == nil else {
            let profileViewController = storyboard.instantiateViewController(withIdentifier: "Profile")
            window?.rootViewController = profileViewController
            return
        }
        
        let welcomeViewController = storyboard.instantiateViewController(withIdentifier: "SignIn")
        
        // Setup for UI Tests
        if let configForUITests = configForUITests,
           let issuer = configForUITests["issuer"],
           let issuerURL = URL(string: issuer),
           let clientId = configForUITests["clientId"],
           let scopes = configForUITests["scopes"],
           let redirectUri = configForUITests["redirectUri"],
           let redirectURL = URL(string: redirectUri) {
            let _ =  WebAuthentication(
                issuer: issuerURL,
                clientId: clientId,
                scopes: scopes,
                redirectUri: redirectURL)
        }
        window?.rootViewController = welcomeViewController
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

