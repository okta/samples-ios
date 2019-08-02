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

class MFAEnrollmentViewController: AuthBaseViewController {
    var factors: [OktaFactor] {
        let mfaEnrollStatus = status as! OktaAuthStatusFactorEnroll
        return mfaEnrollStatus.availableFactors
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(false, animated: false)
        if let enrollStatus = status as? OktaAuthStatusFactorEnroll, enrollStatus.canSkipEnrollment() {
            let activateButton = UIBarButtonItem(title: "Skip",
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(skip))
            self.navigationItem.setRightBarButton(activateButton, animated: true)
        }
    }

    @objc func skip() {
        let enrollStatus = status as! OktaAuthStatusFactorEnroll
        enrollStatus.skipEnrollment(onStatusChange: { [weak self] status in
            SVProgressHUD.dismiss()
            self?.flowCoordinatorDelegate?.onStatusChanged(status: status)
        }) { [weak self] error in
            SVProgressHUD.dismiss()
            self?.showError(message: error.description)
        }
    }

    @IBAction private func cancelTapped() {
        self.processCancel()
    }

    @IBOutlet private var table: UITableView!
}

extension MFAEnrollmentViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.factors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MFAFactorCell") ??
            UITableViewCell(style: .default, reuseIdentifier: "MFAFactorCell")
        
        let factor = self.factors[indexPath.row]
        cell.textLabel?.text = "\(factor.factor.factorType.rawValue) (\(factor.factor.enrollment?.lowercased() ?? ""))"
        cell.detailTextLabel?.text = "Status: \(factor.factor.status?.description ?? "Unknown status") Vendor: \(factor.factor.vendorName ?? "Unknown vendor")"
        
        return cell
    }
}

extension MFAEnrollmentViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let factor = self.factors[indexPath.row]
        switch factor.type {
        case .call, .sms:
            handleSmsOrCallFactor(factor: factor)
        case .question:
            handleQuestionFactor(factor: factor as! OktaFactorQuestion)
        case .push:
            handlePushFactor(factor: factor as! OktaFactorPush)
        case .TOTP:
            handleTotpFactor(factor: factor as! OktaFactorTotp)
        case .tokenHardware:
            handleYubiKeyFactor(factor: factor as! OktaFactorOther)
        default:
            showError(message: "Not implemented!\nNo factor handler for \(factor.type.rawValue)")
        }
    }
}

// MARK: factors handling

extension MFAEnrollmentViewController {
    private func handleSmsOrCallFactor(factor: OktaFactor) {
        
        let alert = UIAlertController(title: "MFA Enroll", message: "Please enter phone number", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Phone" }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            guard let phone = alert.textFields?[0].text else { return }
            SVProgressHUD.show()
            factor.enroll(questionId: nil,
                          answer: nil,
                          credentialId: nil,
                          passCode: nil,
                          phoneNumber: phone,
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
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func handlePushFactor(factor: OktaFactorPush) {
        SVProgressHUD.show()
        factor.enroll(onStatusChange:
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

    private func handleTotpFactor(factor: OktaFactorTotp) {
        SVProgressHUD.show()
        factor.enroll(onStatusChange:
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

    private func handleYubiKeyFactor(factor: OktaFactorOther) {
        let alert = UIAlertController(title: "MFA Enroll", message: "Please enter pass code", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Pass code" }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            guard let passCode = alert.textFields?[0].text else { return }
            let mfaEnrollStatus = self.status as! OktaAuthStatusFactorEnroll
            SVProgressHUD.show()
            OktaYubiKeyFactor.verifyFactor(factor,
                                           stateToken: mfaEnrollStatus.stateToken,
                                           passCode: passCode,
                                           onStatusChange: { [weak self] status in
                SVProgressHUD.dismiss()
                self?.flowCoordinatorDelegate?.onStatusChanged(status: status)
            }, onError: { [weak self] error in
                SVProgressHUD.dismiss()
                self?.showError(message: error.description)
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    private func handleQuestionFactor(factor: OktaFactorQuestion) {
        SVProgressHUD.show(withStatus: "Downloading questions...")
        factor.downloadSecurityQuestions(onDownloadComplete: { [weak self] questions in
            SVProgressHUD.dismiss()
            let alert = UIAlertController(title: "Select question", message: nil, preferredStyle: .actionSheet)
            questions.forEach({ question in
                    alert.addAction(UIAlertAction(title: question.questionText, style: .default, handler: { _ in
                        self?.handleChosenQuestion(question: question, for: factor)
                }))
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }) { [weak self] error in
            SVProgressHUD.dismiss()
            self?.showError(message: error.description)
        }
    }

    private func handleChosenQuestion(question: SecurityQuestion, for factor: OktaFactorQuestion) {
        let alert = UIAlertController(title: "Question factor enroll",
                                      message: "Please enter answer to the question:\n\(question.questionText ?? "Unknown question")",
                                      preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Answer" }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            guard let answer = alert.textFields?[0].text else { return }
            SVProgressHUD.show()
            factor.enroll(questionId: question.question!,
                          answer: answer,
                          onStatusChange:
                    { [weak self] status in
                        SVProgressHUD.dismiss()
                        self?.flowCoordinatorDelegate?.onStatusChanged(status: status)
                    },
                          onError:
                    { [weak self] error in
                        SVProgressHUD.dismiss()
                        self?.showError(message: error.description)
                    }
            )
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
