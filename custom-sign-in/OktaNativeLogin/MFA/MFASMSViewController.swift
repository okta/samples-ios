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

class MFASMSViewController: AuthBaseViewController {

    lazy var factor: OktaFactor = {
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        return mfaChallengeStatus.factor
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if let phoneNumber = factor.factor.profile?.phoneNumber {
            phoneNumberLabel.isHidden = false
            phoneNumberLabel.text = phoneNumber
        } else {
            phoneNumberLabel.isHidden = true
        }

        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        resendButton.isHidden = !mfaChallengeStatus.canResend()
        verifyButton.isHidden = !mfaChallengeStatus.canVerify()
        cancelButton.isHidden = !mfaChallengeStatus.canCancel()
    }

    @IBAction func resendButtonTapped() {
        activityIndicator.startAnimating()
        buttonsStack.isUserInteractionEnabled = false
        let mfaChallengeStatus = status as! OktaAuthStatusFactorChallenge
        mfaChallengeStatus.resendFactor(onStatusChange: { status in
            self.buttonsStack.isUserInteractionEnabled = true
        }) { error in
            self.buttonsStack.isUserInteractionEnabled = true
            self.showError(message: error.description)
        }
    }
    
    @IBAction func verifyButtonTapped() {
        guard let code = codeTextField.text else { return }
        activityIndicator.startAnimating()
        buttonsStack.isUserInteractionEnabled = false
        factor.verify(passCode: code,
                      answerToSecurityQuestion: nil,
                      onStatusChange:
            { status in
                self.buttonsStack.isUserInteractionEnabled = true
                self.activityIndicator.stopAnimating()
                self.flowCoordinatorDelegate?.onStatusChanged(status: status)
            },
                      onError:
            { error in
                self.buttonsStack.isUserInteractionEnabled = true
                self.activityIndicator.stopAnimating()
                self.showError(message: error.description)
        })
    }

    @IBAction func cancelButtonTapped() {
        self.processCancel()
    }

    @IBOutlet private var phoneNumberLabel: UILabel!
    @IBOutlet private var codeTextField: UITextField!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var verifyButton: UIButton!
    @IBOutlet private var resendButton: UIButton!
    @IBOutlet private var cancelButton: UIButton!
    @IBOutlet private var buttonsStack: UIStackView!
}
