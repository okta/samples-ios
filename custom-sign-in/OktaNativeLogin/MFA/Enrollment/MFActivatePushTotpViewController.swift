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

import OktaAuthSdk
import SVProgressHUD
import UIKit

class MFActivatePushTotpViewController: AuthBaseViewController {
    var factor: OktaFactor {
        let mfaActivate = status as! OktaAuthStatusFactorEnrollActivate
        return mfaActivate.factor
    }

    var pushFactorHandler: MFAPushFactorHandler = MFAPushFactorHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.show(withStatus: "Downloading QR code...")
        if let qrCodeUrl = factor.factor.embedded?.activation?.links?.qrcode?.href{
            DispatchQueue.global().async {
                let imageData = try? Data(contentsOf: qrCodeUrl)
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    guard let imageData = imageData else {
                        self.showError(message: "Can't download qr code from url: \(qrCodeUrl)")
                        return
                    }
                    self.qrCodeImageView.image = UIImage(data: imageData)
                }
            }
        }

        pushFactorHandler.delegate = self

        factorResultLabel.flash()

        if let factor = factor as? OktaFactorPush {
            codeTextField.removeFromSuperview()
            factor.activate(onStatusChange:
                { [weak self] status in
                    self?.pushFactorHandler.handlePushFactorResponse(status: status)
            },
                            onError:
                { [weak self] error in
                    self?.showError(message: error.description)
            })
        } else {
            factorResultLabel.removeFromSuperview()
            let activateButton = UIBarButtonItem(title: "Activate",
                                             style: .plain,
                                             target: self,
                                             action: #selector(activateTotp))
            self.navigationItem.setRightBarButton(activateButton, animated: true)
        }
    }

    override func backButtonTapped() {
        super.backButtonTapped()
        self.pushFactorHandler.cancel()
        self.pushFactorHandler.delegate = nil
    }

    @objc func activateTotp() {
        guard let code = codeTextField.text, !code.isEmpty else { return }
        factor.activate(passCode: code,
                        onStatusChange:
            { [weak self] status in
                if status.statusType == self?.status?.statusType {
                    if let factorResult = status.factorResult {
                        self?.factorResultLabel.text = factorResult.rawValue
                        if factorResult != OktaAPISuccessResponse.FactorResult.waiting {
                            self?.factorResultLabel.layer.removeAllAnimations()
                        }
                    }
                    return
                }
                self?.flowCoordinatorDelegate?.onStatusChanged(status: status)
        },
                        onError:
            { [weak self] error in
                self?.showError(message: error.description)
        })
    }
    
    @IBAction private func cancelTapped() {
        self.processCancel()
    }
    
    @IBOutlet private var qrCodeImageView: UIImageView!
    @IBOutlet private var factorResultLabel: UILabel!
    @IBOutlet private var codeTextField: UITextField!
}

extension MFActivatePushTotpViewController: MFAPushFactorHandlerProtocol {
    func onStatusChanged(status: OktaAuthStatus) {
        self.flowCoordinatorDelegate?.onStatusChanged(status: status)
    }

    func onPollingProgress(status: OktaAuthStatus) {
        self.status = status
    }
    
    func onPollingStopped(status: OktaAuthStatus) {
        self.factorResultLabel.layer.removeAllAnimations()
        self.factorResultLabel.text = status.factorResult?.rawValue ?? "Unknown factor result"
    }
    
    func onError(error: OktaError) {
        self.showError(message: error.description)
    }
}
