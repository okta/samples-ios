//
//  WelcomeViewController.swift
//  OktaBrowserSignIn
//
//  Created by Alex on 18 Apr 19.
//  Copyright © 2019 Okta. All rights reserved.
//

import UIKit

final class WelcomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = AppDelegate.shared.stateManager {
            performSegue(withIdentifier: "show-details", sender: self)
        }
    }
    
    @IBAction private func signInTapped() {   
        AppDelegate.shared.oktaOidc.signInWithBrowser(from: self, callback: { [weak self] stateManager, error in
            if let error = error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
                return
            }
            AppDelegate.shared.stateManager?.clear()
            AppDelegate.shared.stateManager = stateManager
            stateManager?.writeToSecureStorage()
            self?.performSegue(withIdentifier: "show-details", sender: self)
        })
    }
}
