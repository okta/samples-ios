/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import UIKit
import OktaIdxAuth

protocol SigninController {
    var auth: OktaIdxAuth? { get set }
    func show(error: Error)
}

extension SigninController where Self: UIViewController {
    func show(error: Error) {
        let alert = UIAlertController(title: nil,
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "OK",
                              style: .default,
                              handler: { (action) in
            
        }))
        present(alert, animated: true)
    }
}

class LandingViewController: UIViewController, SigninController {
    @IBOutlet weak var signInButtonStackView: UIStackView!
    @IBOutlet weak var registerButton: SigninButton!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var footerView: UIView!
    var auth: OktaIdxAuth?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var targetController = segue.destination
        if let targetNavigationController = targetController as? UINavigationController,
           let topController = targetNavigationController.topViewController
        {
            targetController = topController
        }
        
        if var signinController = targetController as? SigninController {
            signinController.auth = auth
        }
    }
}
