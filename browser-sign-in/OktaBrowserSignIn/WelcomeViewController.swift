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
    lazy var auth = WebAuthentication.shared
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var ephemeralSwitch: UISwitch!
    @IBOutlet weak var clientIdLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        if let clientId = auth?.signInFlow.client.configuration.clientId {
            clientIdLabel.text = "Client ID: \(clientId)"
        } else {
            clientIdLabel.text = "Client ID is not configured"
            signInButton.isEnabled = false
        }
    }
    
    func navigateToDetailsPage() {
        guard Credential.default != nil else { return }
        performSegue(withIdentifier: "show-details", sender: self)
    }
    
    @IBAction private func signInTapped() {
        auth?.ephemeralSession = ephemeralSwitch.isOn
        auth?.signIn(from: view.window) { result in
            switch result {
            case .success(let token):
                do {
                    try Credential.store(token)
                    self.performSegue(withIdentifier: "show-details", sender: self)
                } catch {
                    self.show(title: "Error", error: error.localizedDescription, after: 3.0)
                    return
                }
            case .failure(let error):
                self.show(title: "Error", error: error.localizedDescription)
                return
            }
        }
    }
}

extension UIViewController {
    func show(title: String? = nil, error: String? = nil, after delay: TimeInterval = 0.0) {
        // There's currently no way to know when the ASWebAuthenticationSession will be dismissed,
        // so to ensure the alert can be displayed, we must delay presenting an error until the
        // dismissal is complete.
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let alert = UIAlertController(
                title: title,
                message: error,
                preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            
            self.present(alert, animated: true)
        }
    }
}
