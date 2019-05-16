/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
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
import OneTimePassword
import Base32

class ManualCodeEntryController: UIViewController {
    
    @IBOutlet var nameField: UITextField!
    @IBOutlet var issuerField: UITextField!
    @IBOutlet var keyField: UITextField!
    
    var completion: ((Token) -> Void)?
    
    static func create() -> ManualCodeEntryController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ManualCodeEntryController")
            as! ManualCodeEntryController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.viewDidAppear(animated)
        
        let item = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(create))
        navigationItem.setRightBarButton(item, animated: false)
    }
    
    @IBAction func create() {
        guard let name = nameField.text,
            let issuer = issuerField.text,
            let key = keyField.text,
            !name.isEmpty, !issuer.isEmpty, !key.isEmpty else {
                presentAlert("All fields are required!")
                return
        }
        
        guard let secretData = MF_Base32Codec.data(fromBase32String: key),
            !secretData.isEmpty else {
                presentAlert("Invalid Secret!")
                return
        }
        
        guard let generator = Generator(
            factor: .timer(period: 30),
            secret: secretData,
            algorithm: .sha1,
            digits: 6) else {
                presentAlert("Invalid generator parameters")
                return
        }
        
        let token = Token(name: name, issuer: issuer, generator: generator)
        
        navigationController?.popViewController(animated: true)
        completion?(token)
    }
    
    private func presentAlert(_ message: String) {
        let controller = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default))
        present(controller, animated: true)
    }
}
