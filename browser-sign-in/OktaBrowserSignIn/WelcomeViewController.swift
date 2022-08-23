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
import LocalAuthentication

final class WelcomeViewController: UIViewController {
    lazy var auth = WebAuthentication.shared
    lazy var context = LAContext()
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var ephemeralSwitch: UISwitch!
    @IBOutlet weak var clientIdLabel: UILabel!
    @IBOutlet weak var biometricStorageSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        if let clientId = auth?.signInFlow.client.configuration.clientId {
            clientIdLabel.text = "Client ID: \(clientId)"
        } else {
            clientIdLabel.text = "Client ID is not configured"
            signInButton.isEnabled = false
        }
    }

    // This functions demonstrates how to securely store the given token returned after successfully
    // authenticating a user in the device keychain using the default implementation provided.
    func signIn() {
        auth?.signIn(from: view.window) { result in
            switch result {
            case .success(let token):
                do {
                    try Credential.store(token)
                    self.performSegue(withIdentifier: "show-details", sender: self)
                } catch {
                    self.show(title: "Error", error: error.localizedDescription, after: 3.0)
                    return
                }
            case .failure(let error):
                self.show(title: "Error", error: error.localizedDescription)
                return
            }
        }
    }
    
    // This functions demonstrate how to determines if a particular policy either a passcode set, a fingerprint
    // enrolled with Touch ID or a face set up with Face ID policy can be evaluated. Once you are are ready to authenticate, the
    // storeSignInBehindBiometric method is called to perform the authentication.
    func signInWithBiometrics() {
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Log in to your account",
                reply: { success, error in
                    guard let error = error else {
                        DispatchQueue.main.async {
                            self.storeSignInBehindBiometric()
                        }
                        return
                    }
                    self.show(title: "Error", error: error.localizedDescription)
                })
        } else {
            show(title: "Error", error: error?.localizedDescription)
        }
    }
    
    // This functions demonstrates how to securely store the given token returned after successfully
    // authenticating a user behind a biometric factor for later use.
    func storeSignInBehindBiometric() {
        self.auth?.signIn(from: self.view.window) { result in
            switch result {
            case .success(let token):
                do {
                    try Credential.store(
                        token,
                        security: [
                            .accessibility(.afterFirstUnlock),
                            .accessControl(.biometryAny),
                            .context(self.context)
                        ])
                    self.performSegue(withIdentifier: "show-details", sender: self)
                } catch {
                    self.show(title: "Error", error: error.localizedDescription, after: 3.0)
                    return
                }
            case .failure(let error):
                self.show(title: "Error", error: error.localizedDescription)
                return
            }
        }
    }

    @IBAction private func signInTapped() {
        auth?.ephemeralSession = ephemeralSwitch.isOn
        let isBiometricsEnabled = biometricStorageSwitch.isOn
        
        // This demonstrates how to securely store the sign in credentials behind a biometric factor
        // or using the default implementation provided. Only choose one approach or the other and not both.
        if isBiometricsEnabled {
            signInWithBiometrics()
        } else {
            signIn()
        }
    }
}

extension UIViewController {
    func show(title: String? = nil, error: String? = nil, after delay: TimeInterval = 0.0) {
        // There's currently no way to know when the ASWebAuthenticationSession will be dismissed,
        // so to ensure the alert can be displayed, we must delay presenting an error until the
        // dismissal is complete.
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let alert = UIAlertController(
                title: title,
                message: error,
                preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            
            self.present(alert, animated: true)
        }
    }
}
