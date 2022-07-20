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

final class WelcomeViewController: UIViewController {
    var auth: WebAuthentication?
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var ephemeralSwitch: UISwitch!
    @IBOutlet weak var clientIdLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        if let clientId = auth?.signInFlow.client.configuration.clientId {
            self.clientIdLabel.text = "clientId: \(clientId)"
        } else {
            self.clientIdLabel.text = "Not configured"
            self.signInButton.isEnabled = false
        }
    }
    
    func navigateToDetailsPage() {
        guard Credential.default != nil else { return }
        self.performSegue(withIdentifier: "show-details", sender: self)
    }
    
    @IBAction func ephemeralSwitchChanged(_ sender: Any) {
        guard let sender = sender as? UISwitch else { return }
        self.auth?.ephemeralSession = sender.isOn
    }
    
    @IBAction private func signInTapped() {
        auth?.signIn(from: self.view.window) { result in
            switch result {
            case .success(let token):
                do {
                    try Credential.store(token)
                    self.performSegue(withIdentifier: "show-details", sender: self)
                } catch {
                    self.show(titile: "Error", error: error.localizedDescription, after: 3.0)
                    return
                }
            case .failure(let error):
                self.show(titile: "Error", error: error.localizedDescription)
                return
            }
        }
    }
}

extension UIViewController {
    func show(titile: String? = nil, error: String? = nil, after delay: TimeInterval = 0.0) {
        // There's currently no way to know when the ASWebAuthenticationSession will be dismissed,
        // so to ensure the alert can be displayed, we must delay presenting an error until the
        // dismissal is complete.
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let alert = UIAlertController(
                title: titile,
                message: error,
                preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            
            self.present(alert, animated: true)
        }
    }
}
