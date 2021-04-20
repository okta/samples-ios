/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import UIKit
import OktaIdx
import OktaIdxAuth

extension Notification.Name {
    static let authenticationSuccessful = Notification.Name("AuthenticationSuccessful")
    static let authenticationFailed = Notification.Name("AuthenticationFailed")
}

class OnboardingManager {
    static let shared = OnboardingManager()
    
    struct UserDefaultsKeys {
        static let storedTokenKey = "com.okta.directAuth.storedToken"
    }
    
    weak var windowScene: UIWindowScene?
    private(set) var onboardingWindow: UIWindow?
    let configuration: Configuration
    
    private var _currentUser: User? {
        didSet {
            if _currentUser == nil {
                show()
            }
        }
    }
    
    var currentUser: User? {
        get {
            if _currentUser == nil,
               let data = UserDefaults.standard.object(forKey: UserDefaultsKeys.storedTokenKey) as? Data
            {
                _currentUser = try? JSONDecoder().decode(User.self, from: data)
            }
            return _currentUser
        }
        set {
            let defaults = UserDefaults.standard
            _currentUser = newValue
            if let currentUser = _currentUser {
                let data = try? JSONEncoder().encode(currentUser)
                defaults.set(data, forKey: UserDefaultsKeys.storedTokenKey)
            } else {
                defaults.removeObject(forKey: UserDefaultsKeys.storedTokenKey)
            }
            defaults.synchronize()
        }
    }
        
    struct Configuration {
        let issuer: String
        let clientId: String
        let scopes: [String]
        let redirectUri: String
    }
    
    init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    convenience init?() {
        guard let path = Bundle.main.url(forResource: "Okta", withExtension: "plist"),
              let data = try? Data(contentsOf: path),
              let content = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String:String],
              let issuer = content["issuer"],
              let clientId = content["clientId"],
              let scopes = content["scopes"],
              let redirectUri = content["redirectUri"]
        else {
            return nil
        }

        self.init(configuration: .init(issuer: issuer,
                                       clientId: clientId,
                                       scopes: scopes.components(separatedBy: " "),
                                       redirectUri: redirectUri))
    }

    func show(in scene: UIWindowScene? = nil) {
        guard let windowScene = scene ?? self.windowScene else { return }
        guard onboardingWindow == nil else { return }
        
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        guard let rootViewController = storyboard.instantiateInitialViewController() as? UINavigationController,
              var topViewController = rootViewController.topViewController as? UIViewController & SigninController
        else {
            return
        }
        
        topViewController.auth = OktaIdxAuth(issuer: configuration.issuer,
                                             clientId: configuration.clientId,
                                             clientSecret: nil,
                                             scopes: configuration.scopes,
                                             redirectUri: configuration.redirectUri,
                                             completion: { (token, error) in
                                                self.completed(with: token, error: error)
                                             })
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        onboardingWindow = window
        
        NotificationCenter.default.addObserver(forName: .authenticationSuccessful,
                                               object: nil,
                                               queue: .main) { (notification) in
            self.dismiss(animated: true)
        }
    }
    
    func dismiss(animated: Bool = true) {
        guard let onboardingWindow = onboardingWindow else { return }
        if animated {
            UIView.animate(withDuration: 0.33) {
                onboardingWindow.alpha = 0
            } completion: { _ in
                self.onboardingWindow = nil
            }
        } else {
            self.onboardingWindow = nil
        }
    }
    
    func revokeTokens(completion: @escaping(Bool, Error?) -> Void) {
        guard let user = currentUser else {
            completion(false, nil)
            return
        }
        
        let auth = OktaIdxAuth(issuer: configuration.issuer,
                               clientId: configuration.clientId,
                               clientSecret: nil,
                               scopes: configuration.scopes,
                               redirectUri: configuration.redirectUri,
                               completion: { (_, _) in
                               })
        auth.revokeTokens(token: user.token.accessToken,
                          type: .accessAndRefreshToken) { (response, error) in
            completion(response?.status == .tokenRevoked, error)
        }
    }
    
    func completed(with token: IDXClient.Token?, error: Error?) {
        guard let token = token else {
            let alert = UIAlertController(title: nil,
                                          message: error?.localizedDescription ?? "Could not sign in",
                                          preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: nil))
            
            let rootViewController = onboardingWindow?.rootViewController
            rootViewController?.presentedViewController?.dismiss(animated: true)
            rootViewController?.present(alert, animated: true)

            return
        }
        
        print("Got the token \(token.accessToken)")
        
        currentUser = User(with: token)
        NotificationCenter.default.post(name: .authenticationSuccessful,
                                        object: currentUser)
    }
}
