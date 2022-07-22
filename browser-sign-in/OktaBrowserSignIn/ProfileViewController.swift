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
import WebAuthenticationUI

class ProfileViewController: UIViewController {
    var credential: Credential? {
        didSet {
            updateUI(info: credential?.userInfo)
            credential?.automaticRefresh = true
            credential?.refreshIfNeeded { _ in
                self.credential?.userInfo { result in
                    guard case let .success(userInfo) = result else { return }
                    DispatchQueue.main.async {
                        self.updateUI(info: userInfo)
                    }
                }
            }
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var timezoneLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(forName: .defaultCredentialChanged,
                                               object: nil,
                                               queue: .main) { (notification) in
            guard let user = notification.object as? Credential else { return }
            self.credential = user
        }
        self.credential = Credential.default
    }
    
    func updateUI(info: UserInfo?) {
        self.titleLabel.text = "Welcome, \(info?.givenName ?? "")"
        self.subtitleLabel.text = info?.preferredUsername
        self.timezoneLabel.text = info?.zoneinfo
        if let updatedAt = info?.updatedAt {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            self.updatedLabel.text = dateFormatter.string(for: updatedAt)
        } else {
            self.updatedLabel.text = "N/A"
        }
    }
    
    @IBAction func signOutTapped() {
        guard let credential = credential else {
            self.show(error: "Unexpected error with the token lifecycle.")
            return
        }
        
        guard let auth = WebAuthentication.shared else {
            self.show(error: "Client configuration is not set.")
            return
        }
        
        auth.signOut(token: credential.token) { result in
            switch result {
            case .success:
                try? credential.remove()
                self.navigationController?.popViewController(animated: true)
            case .failure(let error):
                self.show(title: "Sign out failed", error: error.localizedDescription)
            }
        }
    }
}
