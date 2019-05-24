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

class MFATOTPViewController: AuthBaseViewController {

    var factor: OktaFactor {
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        return mfaChallengeStatus.factor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = factor.factor.vendorName ?? "Unknown Vendor"
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        verifyButton.isHidden = !mfaChallengeStatus.canVerify()
        cancelButton.isHidden = !mfaChallengeStatus.canCancel()
    }
    
    @IBAction func verifyButtonTapped() {
        guard let code = codeTextField.text, !code.isEmpty else { return }
        SVProgressHUD.show()
        factor.verify(passCode: code,
                      answerToSecurityQuestion: nil,
                      onStatusChange:
            { [weak self] status in
                SVProgressHUD.dismiss()
                self?.flowCoordinatorDelegate?.onStatusChanged(status: status)
        },
                      onError:
            { [weak self] error in
                SVProgressHUD.dismiss()
                self?.showError(message: error.description)
        })
    }
    
    @IBAction func cancelButtonTapped() {
        self.processCancel()
    }

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var codeTextField: UITextField!
    @IBOutlet private var verifyButton: UIButton!
    @IBOutlet private var cancelButton: UIButton!
    @IBOutlet private var buttonsStack: UIStackView!
}
