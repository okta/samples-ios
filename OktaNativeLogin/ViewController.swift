//
//  ViewController.swift
//  OktaNativeLogin
//
//  Created by Alex on 9 Jan 19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
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
        
        client.logIn(username: username, password: password)
    }
}

extension ViewController: AuthenticationClientDelegate {
    func handleSuccess() {
        guard let sessionToken = client.sessionToken else { return }
        
        
        
        
        
    }
    
    func handleError(_ error: OktaError) {
        
    }
    
    func handleChangePassword(canSkip: Bool, callback: @escaping (_ old: String?, _ new: String?, _ skip: Bool) -> Void) {
        
    }
    
    func handleMultifactorAuthenication(callback: @escaping (_ code: String) -> Void) {
        
    }
    
    func transactionCancelled() {
        
    }
}
