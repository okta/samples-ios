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

    /// This function demonstrates how to securely store the token in the device keychain after a successful sign in.
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
    
    /// This function demonstrates how to determine if biometric storage is eligible to the user, (e.g. either a passcode is set, a fingerprint is 
    /// enrolled with Touch ID, or a face is set up with Face ID). Once you are are ready to authenticate, the
    /// ``storeSignInBehindBiometric`` function is called to perform the authentication.
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
    
    /// This function demonstrate how to securely store the token in the keychain after a successful sign in, using a biometric factor to control access.
    ///
    /// This is called by the ``signInWithBiometrics`` function after it determines the user is eligible for using biometrics on this device.
    func storeSignInBehindBiometric() {
        self.auth?.signIn(from: self.view.window) { result in
            switch result {
            case .success(let token):
                do {
                    try Credential.store(
                        token,
                        security: [
                            .accessibility(.afterFirstUnlockThisDeviceOnly),
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
    
    /// This demonstrates how to securely store the sign in credentials behind a biometric factor ``signInWithBiometrics``
    /// or using the default implementation provided ``signIn``.
    ///
    /// The biometrics storage switch is used to determine which one approach over the other.
    @IBAction private func signInTapped() {
        auth?.ephemeralSession = ephemeralSwitch.isOn
        let isBiometricsEnabled = biometricStorageSwitch.isOn
        
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
