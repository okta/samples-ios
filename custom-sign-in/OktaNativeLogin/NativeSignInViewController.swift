//
//  UserProfileViewController.swift
//  OktaNativeLogin
//
//  Created by Anastasiia Iurok on 1/16/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuthNative
import OktaAuth

class NativeSignInViewController: UIViewController {
    
    @IBOutlet private var loginButton: UIButton!
    @IBOutlet private var logoutButton: UIButton!
    
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet private var loggedInUserInfoContainer: UIStackView!
    @IBOutlet private var usernameButton: UIButton!
    
    @IBOutlet private var unathenticatedNotice: UILabel!
    
    private var client: AuthenticationClient!
    private var authState: OktaTokenManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup Okta Auth Client
        let url = URL(string: "{your Okta domain}")!
        client = AuthenticationClient(oktaDomain: url, delegate: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateUI()
    }
    
    @IBAction func loginTapped() {
        LoginFormViewController.loadAndPresent(from: self) { (username, password) in
            self.showProgress()
        
            // Perfrom login
            self.client.authenticate(username: username, password: password)
        }
    }
    
    @IBAction func logoutTapped() {
        // Perfrom logout
        self.client.resetStatus()
        self.authState = nil
        
        self.updateUI()
    }
    
    @IBAction func usernameTapped() {
        guard let profile = client.embedded?.user?.profile else {
            return
        }

        let controller = UserProfileViewController.fromStoryboard()
        controller.profile = profile
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

extension NativeSignInViewController: AuthenticationClientDelegate {
    
    func handleSuccess(sessionToken: String) {
        print("Session token: \(sessionToken)")
        
        OktaAuth.authenticate(withSessionToken: sessionToken).start().then { manager in
            // Cash auth state
            self.authState = manager
            
            self.showAuthSucceeded()
            self.hideProgress()
            self.updateUI()
        }.catch { error in
            print("Error: \(error)")
            self.showError(message: error.localizedDescription)
            self.hideProgress()
        }
    }
    
    func handleError(_ error: OktaAuthNative.OktaError) {
        print("Error: \(error)")
        showError(message: error.localizedDescription)
        hideProgress()
    }
    
    func handleChangePassword(canSkip: Bool, callback: @escaping (_ old: String?, _ new: String?, _ skip: Bool) -> Void) {
    }
    
    func handleAccountLockedOut(callback: @escaping (String, FactorType) -> Void) {
        self.hideProgress()
        self.showAccountLockedAlert { username in
            callback(username, .email)
            self.showProgress()
        }
    }
    
    func handleRecoveryChallenge(factorType: FactorType?, factorResult: FactorResult?) {
        self.hideProgress()
        guard factorType == .email, factorResult == .waiting else {
            self.showError(message: "Unexpected recovery challange response!")
            return
        }

        // Allow to sign in after unlocking user's account
        self.client.resetStatus()

        self.showUnlockEmailIsSentAlert()
    }
    
    func handleMultifactorAuthenication(callback: @escaping (_ code: String) -> Void) {
    }
    
    func transactionCancelled() {
    }
}

// UI Utils
private extension NativeSignInViewController {
    
    var userProfile: EmbeddedResponse.User.Profile? {
        return client.embedded?.user?.profile
    }
    
    func updateUI() {
        guard isViewLoaded else { return }
        
        if let userProfile = userProfile {
            presentAuthenticatedUser(userProfile)
        } else {
            presentUnauthenticated()
        }
    }
    
    func presentAuthenticatedUser(_ profile: EmbeddedResponse.User.Profile) {
        logoutButton.isHidden = false
        loginButton.isHidden = true
        
        loggedInUserInfoContainer.isHidden = false
        usernameButton.setTitle(profile.login, for: .normal)
        
        unathenticatedNotice.isHidden = true
    }
    
    func presentUnauthenticated() {
        logoutButton.isHidden = true
        loginButton.isHidden = false
        
        loggedInUserInfoContainer.isHidden = true
        usernameButton.setTitle(nil, for: .normal)
        
        unathenticatedNotice.isHidden = false
    }
    
    func showAuthSucceeded() {
        let alert = UIAlertController(title: "Logged In!", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "User Profile", style: .default, handler: { _ in
            self.usernameTapped()
        }))
        self.present(alert, animated: true, completion: nil)
    }

    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showProgress() {
        activityIndicator.startAnimating()
        self.loginButton.isEnabled = false
    }
    
    func hideProgress() {
        activityIndicator.stopAnimating()
        self.loginButton.isEnabled = true
    }
    
    func showAccountLockedAlert(and callback: @escaping (_ username: String) -> Void) {
        let alert = UIAlertController(title: "Account Locked", message: "To unlock account enter email or username.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Email or Username"}
        alert.addAction(UIAlertAction(title: "Send Email", style: .default, handler: { _ in
            guard let username = alert.textFields?[0].text else { return }
            callback(username)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true, completion: nil)
    }
    
    func showUnlockEmailIsSendAlert() {
         let alert = UIAlertController(title: "Email sent!", message: "Email has been sent to your email with instructions on unlocking your account.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
}
