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

final class WelcomeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = AppDelegate.shared.stateManager?.accessToken {
            performSegue(withIdentifier: "show-details", sender: self)
        }
    }
    
    @IBAction private func signInTapped() {   
        AppDelegate.shared.oktaOidc.signInWithBrowser(from: self, callback: { stateManager, error in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
                return
            }
            AppDelegate.shared.stateManager?.clear()
            AppDelegate.shared.stateManager = stateManager
            stateManager?.writeToSecureStorage()
            
            DispatchQueue.main.async { [weak self] in
                self?.performSegue(withIdentifier: "show-details", sender: self)
            }
        })
    }
}
