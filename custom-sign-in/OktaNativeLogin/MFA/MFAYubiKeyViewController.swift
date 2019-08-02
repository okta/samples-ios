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
import OktaAuthSdk
import SVProgressHUD

class MFAYubiKeyViewController: AuthBaseViewController {

    var factor: OktaFactorOther {
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
         return mfaChallengeStatus.factor as! OktaFactorOther
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "YubiKey"
        providerLabel.text = factor.factor.provider?.rawValue
    }

    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var providerLabel: UILabel!

    @IBAction func verifyButtonTapped() {
        guard let code = codeTextField.text,
              let mfaChallengeStatus = status as? OktaAuthStatusFactorChallenge else {
            return
        }

        SVProgressHUD.show()
        OktaYubiKeyFactor.verifyFactor(factor,
                                       stateToken: mfaChallengeStatus.stateToken,
                                       passCode: code,
                                       onStatusChange: { [weak self] status in
                                        SVProgressHUD.dismiss()
                                        self?.flowCoordinatorDelegate?.onStatusChanged(status: status)
        },
                                       onError: { [weak self] error in
                                        SVProgressHUD.dismiss()
                                        self?.showError(message: error.description)
        })
    }
    
    @IBAction func cancelButtonTapped() {
        self.processCancel()
    }
}
