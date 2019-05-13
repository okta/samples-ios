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

class SignInViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This line needed for setting up AuthenticationClient when running UI tests
        guard setupForUITests() else { return }
        
        // Setup Okta Auth Client
//        #warning ("Enter your Okta organization domain here")
        let url = URL(string: "https://{yourOktaDomain}")!
        client = AuthenticationClient(oktaDomain: url, delegate: self, mfaHandler: self)
        oktaOidc = try! OktaOidc()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? UserProfileViewController {
            controller.profile = client.embedded?.user?.profile
            controller.logoutTappedCallback = performLogout
        }
    }
    
    // MARK: - Private
    
    private var client: AuthenticationClient!
    private var oktaOidc: OktaOidc!
    private var authState: OktaOidcStateManager?
    private weak var mfaController: MFAViewController?
    
    private var userProfile: EmbeddedResponse.User.Profile? {
        guard client.status == .success else { return nil }
        return client.embedded?.user?.profile
    }
    
    private func performLogout() {
        self.client.resetStatus()
        self.authState = nil
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - IB
    
    @IBOutlet private var usernameField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var signInButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    @IBAction private func signInTapped() {
        guard let username = usernameField.text, !username.isEmpty,
            let password = passwordField.text, !password.isEmpty else { return }
        
        client.authenticate(username: username, password: password)
        showProgress()
    }
}

extension SignInViewController: AuthenticationClientDelegate {
    
    func handleSuccess(sessionToken: String) {
        print("Session token: \(sessionToken)")
        
        oktaOidc.authenticate(withSessionToken: sessionToken, callback: { manager, error in
            DispatchQueue.main.async {
                guard let manager = manager else {
                    self.handleOktaAuthFailure(error: error!)
                    return
                }
                self.handleOktaAuthSuccess(manager: manager)
            }
        })
    }
    
    func handleError(_ error: OktaAuthSdk.OktaError) {
        print("Error: \(error)")
        
        client.resetStatus()
        hideProgress()
        showError(message: error.description)
    }
    
    func handleChangePassword(canSkip: Bool, callback: @escaping (_ old: String?, _ new: String?, _ skip: Bool) -> Void) {
        PasswordResetViewController.loadAndPresent(from: self, canSkip: canSkip) { (old, new, isSkipped) in
            callback(old, new, isSkipped)
        }
    }
    
    func handleAccountLockedOut(callback: @escaping (String, FactorType) -> Void) {
        hideProgress()
        showAccountLockedAlert { username in
            callback(username, .email)
            self.showProgress()
        }
    }
    
    func handleRecoveryChallenge(factorType: FactorType?, factorResult: OktaAPISuccessResponse.FactorResult?) {
        hideProgress()
        guard factorType == .email, factorResult == .waiting else {
            showError(message: "Unexpected recovery challange response!")
            return
        }

        // Allow to sign in after unlocking user's account
        client.resetStatus()

        showUnlockEmailIsSentAlert()
    }
    
    func transactionCancelled() {
        hideProgress()
        showMessage("Authorization cancelled!")
    }
}

extension SignInViewController: AuthenticationClientMFAHandler {
    
    func selectFactor(factors: [EmbeddedResponse.Factor], callback: @escaping (EmbeddedResponse.Factor) -> Void) {
        mfaController = MFAViewController.loadAndPresent(
            from: self,
            factors: factors,
            selectionHandler: { factor in
                callback(factor)
            },
            cancel: { [weak self] in
                self?.hideProgress()
                self?.client.cancelTransaction()
            },
            resend: { [weak self] factor in
                guard let link = self?.client?.links?.resend?.first else {
                    return
                }
                
                self?.client?.perform(link: link)
            }
        )
    }
    
    func pushStateUpdated(_ state: OktaAPISuccessResponse.FactorResult) {
        switch state {
        case .waiting:
            return
        case .cancelled:
            showError(message: "Factor authorization cancelled!")
        case .rejected:
            showError(message: "Factor authorization rejected!")
        case .timeout, .timeWindowExceeded:
            showError(message: "Factor authorization timed out!")
        default:
            showError(message: "Factor authorization failed!")
        }
        hideProgress()
    }
    
    func requestTOTP(callback: @escaping (String) -> Void) {
        mfaController?.requestTOTP(callback: callback)
    }
    
    func requestSMSCode(phoneNumber: String?, callback: @escaping (String) -> Void) {
        mfaController?.requestSMSCode(callback: callback)
    }
    
    func securityQuestion(question: String, callback: @escaping (String) -> Void) {
        mfaController?.requestSecurityQuestion(callback: callback)
    }
}

// UI Utils
private extension SignInViewController {
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        presentAlert(alert)
    }
    
    func showMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        presentAlert(alert)
    }
    
    func showProgress() {
        activityIndicator.startAnimating()
        signInButton.isEnabled = false
    }
    
    func hideProgress() {
        activityIndicator.stopAnimating()
        signInButton.isEnabled = true
    }
    
    func showAccountLockedAlert(and callback: @escaping (_ username: String) -> Void) {
        let alert = UIAlertController(title: "Account Locked", message: "To unlock account enter email or username.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Email or Username"}
        alert.addAction(UIAlertAction(title: "Send Email", style: .default, handler: { _ in
            guard let username = alert.textFields?[0].text else { return }
            callback(username)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presentAlert(alert)
    }
    
    func showUnlockEmailIsSentAlert() {
        let alert = UIAlertController(title: "Email sent!", message: "Email has been sent to your email address with instructions on unlocking your account.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presentAlert(alert)
    }
    
    func presentAlert(_ alert: UIAlertController, animated: Bool = true, completion: (() -> Void)? = nil) {
        if let controller = presentedViewController {
            controller.dismiss(animated: true) {
                self.present(alert, animated: animated, completion: completion)
            }
        } else {
            present(alert, animated: animated, completion: completion)
        }
    }
    
    func handleOktaAuthSuccess(manager: OktaOidcStateManager) {
        authState = manager
        hideProgress()
        performSegue(withIdentifier: "user-profile", sender: self)
    }
    
    func handleOktaAuthFailure(error: Error) {
        print("Error: \(error)")
        showError(message: error.localizedDescription)
        hideProgress()
    }
}

private extension SignInViewController {
    func setupForUITests() -> Bool {
        guard let testURL = ProcessInfo.processInfo.environment["OKTA_URL"],
              let testConfig = configForUITests
              else { return true }
        client = AuthenticationClient(oktaDomain: URL(string: testURL)!, delegate: self, mfaHandler: self)
        oktaOidc = try! OktaOidc(configuration: OktaOidcConfig(with: testConfig))
        return false
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
