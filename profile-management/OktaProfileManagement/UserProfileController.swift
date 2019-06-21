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
import SVProgressHUD

class UserProfileController: UIViewController {
    private var profileManager: ProfileManager?
    private var currentUser: User? {
        return profileManager?.user
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var mobilePhoneLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var activatedLabel: UILabel!
    @IBOutlet weak var statusChangedLabel: UILabel!
    @IBOutlet weak var lastLoginLabel: UILabel!
    @IBOutlet weak var lastUpdateLabel: UILabel!
    @IBOutlet weak var passwordChangedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserInfo()
    }

    private func loadUserInfo() {
        guard let stateManager = AppDelegate.shared.stateManager,
              let config = AppDelegate.shared.oktaOidc?.configuration else {
            return
        }
    
        SVProgressHUD.show()
        profileManager = ProfileManager(config: config, stateManager: stateManager)
    
        profileManager?.getUser(completion: { [weak self] user, error in
            SVProgressHUD.dismiss()
            guard let user = user else {
                let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
                    self?.loadUserInfo()
                }))
                self?.present(alert, animated: true, completion: nil)
                return
            }
            
            self?.updateUI(user)
        })
    }
    
    @IBAction func signOutTapped() {
        guard let stateManager = AppDelegate.shared.stateManager else { return }
        
        AppDelegate.shared.oktaOidc?.signOutOfOkta(stateManager, from: self, callback: { [weak self] error in
            if let error = error {
                self?.presentAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            AppDelegate.shared.stateManager?.clear()
            AppDelegate.shared.stateManager = nil
            
            self?.navigationController?.popViewController(animated: true)
        })
    }
    
    @IBAction func changePassword() {
        guard let profileManager = profileManager,
              let user = profileManager.user else {
                self.presentAlert(title: "Error", message: "User object is not available")
              return
        }
        
        presentChangePasswordAlert { [weak self] old, new in
            profileManager.changePassword(old: old, new: new, completion: { error in
                if let error = error {
                    self?.presentAlert(title: "Error", message: error.localizedDescription)
                }
                
                self?.presentAlert(title: "Password Changed!")
                self?.updateUI(user)
            })
        }
    }
    
    // MARK: - Private
    
    private func updateUI(_ user: User) {
        var name = (user.profile?.firstName ?? "")
        name += name.count > 0 ? " " : ""
        name += (user.profile?.lastName ?? "")
        updateLabel(titleLabel, with: name.count > 0 ? name : nil)
        
        updateLabel(subtitleLabel, with: user.profile?.login)
        updateLabel(emailLabel, with: user.profile?.email)
        updateLabel(mobilePhoneLabel, with: user.profile?.mobilePhone)
        updateLabel(statusLabel, with: user.status)
        updateLabel(createdLabel, with: user.created)
        updateLabel(activatedLabel, with: user.activated)
        updateLabel(statusChangedLabel, with: user.statusChanged)
        updateLabel(lastLoginLabel, with: user.lastLogin)
        updateLabel(lastUpdateLabel, with: user.lastUpdated)
        updateLabel(passwordChangedLabel, with: user.passwordChanged)
    }
    
    private func updateLabel(_ label: UILabel, with date: Date?) {
        guard let date = date else {
            updateLabel(label, with: nil as String?)
            return
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        updateLabel(label, with: formatter.string(from: date))
    }
    
    private func updateLabel(_ label: UILabel, with value: String?) {
        label.text = value ?? "--"
    }
    
    private func presentChangePasswordAlert(completion: @escaping (String, String) -> Void) {
        let alert = UIAlertController(title: "Change Password", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.isSecureTextEntry = true
            field.placeholder = "Old Password"
        }
        
        alert.addTextField { field in
            field.isSecureTextEntry = true
            field.placeholder = "New Password"
        }
        
        alert.addAction(UIAlertAction(title: "Change", style: .default, handler: { action in
            guard let old = alert.textFields?[0].text,
                  let new = alert.textFields?[1].text else {
                return
            }
            
            completion(old, new)
        }))
        
        present(alert, animated: true)
    }
    
    private func presentAlert(title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
