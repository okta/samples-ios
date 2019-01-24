//
//  TokenViewController.swift
//  OktaBrowserSignIn
//
//  Created by Anastasia Yurok on 1/21/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuth

class TokensViewController: UIViewController {

    @IBOutlet private var tokensView: UITextView!
    
    @IBOutlet private var introspectButton: UIButton!
    @IBOutlet private var refreshButton: UIButton!
    @IBOutlet private var revokeButton: UIButton!
    
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configure()
    }
    
    @IBAction func introspectTapped() {
        guard let accessToken = OktaAuth.tokens?.accessToken else { return }
        
        OktaAuth.introspect().validate(accessToken)
        .then { isValid in
            self.showAlert(title: "Access token is \(isValid ? "valid" : "invalid")!")
        }
        .catch { error in
            self.showError(error.localizedDescription)
        }
    }
    
    @IBAction func refreshTapped() {
        OktaAuth.refresh()
        .then { _ in
            self.configure()
            self.showAlert(title: "Token refreshed!")
        }
        .catch { error in
            self.showError(error.localizedDescription)
        }
    }
    
    @IBAction func revokeTapped() {
        guard let accessToken = OktaAuth.tokens?.accessToken else { return }
        
        OktaAuth.revoke(accessToken) { response, error in
            guard let _ = response else {
                self.showError( error?.localizedDescription ?? "Failed to revoked access token!")
                return
            }
            
            self.showAlert(title: "Access token revoked!")
            self.configure()
        }
    }
}

// UI Utils
private extension TokensViewController {
    func configure() {
        guard isViewLoaded else { return }
        
        var tokens = ""
        if let accessToken = OktaAuth.tokens?.accessToken {
            tokens += "Access token: \(accessToken)\n\n"
        }
        
        if let refreshToken = OktaAuth.tokens?.refreshToken {
            tokens += "Refresh token: \(refreshToken)\n\n"
        }
        
        if let idToken = OktaAuth.tokens?.idToken {
            tokens += "ID token: \(idToken)"
        }
        
        tokensView.text = tokens
    }
    
    func showAlert(title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showError(_ message: String) {
        self.showAlert(title: "Error", message: message)
    }
    
    func startProgress() {
        self.activityIndicator.startAnimating()
        self.introspectButton.isEnabled = false
        self.refreshButton.isEnabled = false
        self.revokeButton.isEnabled = false
    }
    
    func stopProgress() {
        self.activityIndicator.stopAnimating()
        self.introspectButton.isEnabled = true
        self.refreshButton.isEnabled = true
        self.revokeButton.isEnabled = true
    }
}
