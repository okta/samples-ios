//
//  ViewController.swift
//  OktaNativeLogin
//
//  Created by Alex on 9 Jan 19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuthNative
import OktaAuth

class ViewController: UIViewController {

    @IBOutlet private var loginField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var loginButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    private var client: AuthenticationClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "https://lohika-um.oktapreview.com")!
        client = AuthenticationClient(oktaDomain: url, delegate: self)
    }
    
    @IBAction private func loginTapped() {
        guard let username = loginField.text,
            let password = passwordField.text else { return }
        
        loginButton.isEnabled = false
        activityIndicator.startAnimating()
        
        client.logIn(username: username, password: password)
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension ViewController: AuthenticationClientDelegate {
    func handleSuccess() {
        guard let sessionToken = client.sessionToken else { return }
        
        print("Session token: \(sessionToken)")
        
        OktaAuth.authoize(withSessionToken: sessionToken).start().then { manager in
            
            let message = "Access token:\n\(manager.accessToken!)"
            let alert = UIAlertController(title: "Logged In!", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.activityIndicator.stopAnimating()
        
        }.catch { error in
            
            print("Error: \(error)")
            self.showError(message: error.localizedDescription)
            self.activityIndicator.stopAnimating()
            
        }
        
    }
    
    func handleError(_ error: OktaAuthNative.OktaError) {
        
        print("Error: \(error)")
        showError(message: error.localizedDescription)
        activityIndicator.stopAnimating()
        
    }
    
    func handleChangePassword(canSkip: Bool, callback: @escaping (_ old: String?, _ new: String?, _ skip: Bool) -> Void) {
        
    }
    
    func handleMultifactorAuthenication(callback: @escaping (_ code: String) -> Void) {
        
    }
    
    func transactionCancelled() {
        
    }
}
