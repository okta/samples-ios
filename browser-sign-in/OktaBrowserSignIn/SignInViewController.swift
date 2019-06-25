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
import OktaOidc

class SignInViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserInfo()
    }
    
    private func loadUserInfo() {
        AppDelegate.shared.stateManager?.getUser { [weak self] response, error in
            DispatchQueue.main.async {
                guard let response = response else {
                    let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                    return
                }
                self?.updateUI(info: response)
            }
        }
    }
    
    private func updateUI(info: [String:Any]?) {        
        titleLabel.text = "Welcome, \(info?["given_name"] as? String ?? "")"
        subtitleLabel.text = info?["preferred_username"] as? String
        timezoneLabel.text = info?["zoneinfo"] as? String
        if let updated = info?["updated_at"] as? Double {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day]
            formatter.unitsStyle = .full
            let days = formatter.string(from: Date(timeIntervalSince1970: updated), to: Date())
            updatedLabel.text = "\(days ?? "?") ago"
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var timezoneLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    
    @IBAction func signOutTapped() {
        guard let stateManager = AppDelegate.shared.stateManager else { return }
        
        AppDelegate.shared.oktaOidc.signOutOfOkta(stateManager, from: self, callback: { [weak self] error in
            if let error = error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
                return
            }
            
            AppDelegate.shared.stateManager?.clear()
            AppDelegate.shared.stateManager = nil
            
            self?.navigationController?.popViewController(animated: true)
        })
    }
}
