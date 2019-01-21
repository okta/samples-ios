//
//  SingInViewController.swift
//  OktaBrowserSignIn
//
//  Created by Anastasiia Iurok on 1/18/19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit
import OktaAuth

class SingInViewController: UIViewController {
    @IBOutlet private var signInButton: UIButton!
    @IBOutlet private var signOutButton: UIButton!
    
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet private var loggedInUserInfoContainer: UIStackView!
    
    @IBOutlet private var userProfileButton: UIButton!
    
    @IBOutlet private var statusLabel: UILabel!
    
    private var authState: OktaTokenManager? {
        return OktaAuth.tokens
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    @IBAction func signInTapped() {
        self.showProgress()

        OktaAuth.signInWithBrowser().start(self)
        . then { _ in
            self.hideProgress()
            self.showSignInSucceeded()
            self.updateUI()
        }.catch { error in
            self.hideProgress()
            self.showError(message: error.localizedDescription)
        }
    }
    
    @IBAction func signOutTapped() {
        self.showProgress()
        
        OktaAuth.signOutOfOkta().start(self)
        .then {
            self.authState?.clear()
            
            self.hideProgress()
            self.showSignOutSucceeded()
            self.updateUI()
        }.catch { error in
            self.hideProgress()
            self.showError(message: error.localizedDescription)
        }
    }
    
    @IBAction func userProfileTapped() {
        guard OktaAuth.isAuthenticated() else { return }
        
        self.showProgress()
        
        OktaAuth.getUser { response, error in
            self.hideProgress()
            
            guard let response = response else {
                self.showError(message: error?.localizedDescription ?? "Unable to get user info. Try re-authorize.")
                return
            }
            
            self.presentUserInfo(response)
        }
    }
}

// UI Utils
private extension SingInViewController {
    func updateUI() {
        guard isViewLoaded else { return }
    
        guard OktaAuth.isAuthenticated() else {
            loggedInUserInfoContainer.isHidden = true
            statusLabel.text = "Unathenticated ✗"
            
            signInButton.isHidden = false
            signOutButton.isHidden = true
            return
        }
        
        loggedInUserInfoContainer.isHidden = false
        statusLabel.text = "Athenticated ✓"
        
        signInButton.isHidden = true
        signOutButton.isHidden = false
    }
    
    func showSignInSucceeded() {
        let alert = UIAlertController(title: "Signed In!", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "User Profile", style: .default, handler: { _ in
            self.userProfileTapped()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showSignOutSucceeded() {
        let alert = UIAlertController(title: "Signed Out!", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showProgress() {
        self.activityIndicator.startAnimating()

        self.signInButton.isEnabled = false
        self.signOutButton.isEnabled = false
        self.userProfileButton.isEnabled = false
    }
    
    func hideProgress() {
        self.activityIndicator.stopAnimating()
        
        self.signInButton.isEnabled = true
        self.signOutButton.isEnabled = true
        self.userProfileButton.isEnabled = true
    }
    
    func presentUserInfo(_ userInfo: [String:Any]) {
        var userInfoText = ""
        userInfo.forEach { userInfoText += ("\($0): \($1) \n") }
        self.presentDetails(userInfoText, title: "User Profile")
    }
    
    func presentDetails(_ content: String, title: String) {
        let controller = DetailViewController.fromStoryboard()
        controller.content = content
        controller.title = title
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

