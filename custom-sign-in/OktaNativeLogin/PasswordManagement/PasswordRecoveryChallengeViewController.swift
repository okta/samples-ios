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

class PasswordRecoveryChallengeViewController: AuthBaseViewController {
    
    lazy var recoveryChallengeStatus: OktaAuthStatusRecoveryChallenge = {
        return status as! OktaAuthStatusRecoveryChallenge
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if recoveryChallengeStatus.factorType == .email {
            emailRecoveryView.isHidden = false
            smsCallRecoveryView.isHidden = true
            self.navigationItem.setHidesBackButton(false, animated: false)
        } else {
            emailRecoveryView.isHidden = true
            smsCallRecoveryView.isHidden = false
            recoveryTypeLabel.text = "Recovery type: \(recoveryChallengeStatus.recoveryType?.rawValue ?? "Unknown")"
        }
        verifyButton.isHidden = !recoveryChallengeStatus.canVerify()
        resendButton.isHidden = !recoveryChallengeStatus.canResend()
        cancelButton.isHidden = !recoveryChallengeStatus.canCancel()
    }

    // MARK: - IB
    
    @IBAction private func openMailAppButtonTapped() {
        let url = URL(string: "message://")
        if let url = url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    @IBAction private func verifyButtonTapped() {
        guard let code = passCodeTextField.text else { return }
        SVProgressHUD.show()
        recoveryChallengeStatus.verifyFactor(passCode: code,
                                             onStatusChange:
            { [weak self]status in
                SVProgressHUD.dismiss()
                self?.flowCoordinatorDelegate?.onStatusChanged(status: status)
        })  { [weak self] error in
                SVProgressHUD.dismiss()
                self?.showError(message: error.description)
        }
    }

    @IBAction private func resendButtonTapped() {
        SVProgressHUD.show()
        recoveryChallengeStatus.resendFactor(onStatusChange:
            { status in
                SVProgressHUD.dismiss()
        })  { [weak self] error in
            SVProgressHUD.dismiss()
            self?.showError(message: error.description)
        }
    }

    @IBAction private func cancelButtonTapped() {
        processCancel()
    }
    
    @IBOutlet weak var passCodeTextField: UITextField!
    @IBOutlet weak var recoveryTypeLabel: UILabel!
    @IBOutlet weak var openMailAppButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var emailRecoveryView: UIView!
    @IBOutlet weak var smsCallRecoveryView: UIView!
}
