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

class MFASMSViewController: AuthBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        var factor: OktaFactor?
        if let mfaChallengeStatus = status as? OktaAuthStatusFactorChallenge {
            factor = mfaChallengeStatus.factor
            resendButton.isHidden = !mfaChallengeStatus.canResend()
            verifyButton.isHidden = !mfaChallengeStatus.canVerify()
            cancelButton.isHidden = !mfaChallengeStatus.canCancel()
        }
        if let mfaActivateStatus = status as? OktaAuthStatusFactorEnrollActivate {
            factor = mfaActivateStatus.factor
            resendButton.isHidden = !mfaActivateStatus.canResend()
            cancelButton.isHidden = !mfaActivateStatus.canCancel()
            verifyButton.isHidden = factor != nil ? !factor!.canActivate() : true
        }
        if let phoneNumber = factor?.factor.profile?.phoneNumber {
            phoneNumberLabel.isHidden = false
            phoneNumberLabel.text = phoneNumber
        } else {
            phoneNumberLabel.isHidden = true
        }
    }

    @IBAction func resendButtonTapped() {
        SVProgressHUD.show(withStatus: "Resending factor...")
        if let mfaChallengeStatus = status as? OktaAuthStatusFactorChallenge {
            mfaChallengeStatus.resendFactor(onStatusChange: { status in
                SVProgressHUD.dismiss()
            }) { [weak self] error in
                SVProgressHUD.dismiss()
                self?.showError(message: error.description)
            }
        }
        if let mfaActivateStatus = status as? OktaAuthStatusFactorEnrollActivate {
            mfaActivateStatus.resendFactor(onStatusChange: { status in
                SVProgressHUD.dismiss()
            }) { [weak self] error in
                SVProgressHUD.dismiss()
                self?.showError(message: error.description)
            }
        }
    }
    
    @IBAction func verifyButtonTapped() {
        guard let code = codeTextField.text else { return }
        
        SVProgressHUD.show()
        if let mfaChallengeStatus = status as? OktaAuthStatusFactorChallenge {
            let factor = mfaChallengeStatus.factor
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
        if let mfaActivateStatus = status as? OktaAuthStatusFactorEnrollActivate {
            let factor = mfaActivateStatus.factor
            factor.activate(passCode: code,
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
