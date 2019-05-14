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

import Foundation
import UIKit
import OktaAuthSdk
import OktaOidc

class AuthFlowCoordinator {
    
    public let rootViewController: UINavigationController
    var currentStatus: OktaAuthStatus?
    
    public class func instantiate() -> AuthFlowCoordinator {
        let signInViewController = AuthBaseViewController.instantiate(with: nil,
                                                                      flowCoordinatorDelegate: nil,
                                                                      storyBoardName: "SignIn",
                                                                      viewControllerIdentifier: "SignIn") as! AuthBaseViewController
        let navigationViewController = UINavigationController(rootViewController: signInViewController)
        let flowCoordinator = AuthFlowCoordinator(with: navigationViewController)
        signInViewController.flowCoordinatorDelegate = flowCoordinator
        return flowCoordinator
    }
    
    public init(with rootViewController: UINavigationController) {
        self.rootViewController = rootViewController
    }

    func handleStatus(status: OktaAuthStatus) {
        
        currentStatus = status
        
        switch status.statusType {
            
        case .success:
            let successState: OktaAuthStatusSuccess = status as! OktaAuthStatusSuccess
            handleSuccessStatus(status: successState)
            
        case .passwordWarning:
            handlePasswordWarning(status: status)
            
        case .passwordExpired:
            handlePasswordExpired(status: status)
            
        case .MFAEnroll:
            let mfaEnroll: OktaAuthStatusFactorEnroll = status as! OktaAuthStatusFactorEnroll
            //self.handleEnrollment(enrollmentStatus: mfaEnroll)
            
        case .MFAEnrollActivate:
            let mfaEnrollActivate: OktaAuthStatusFactorEnrollActivate = status as! OktaAuthStatusFactorEnrollActivate
            //self.handleActivateEnrollment(status: mfaEnrollActivate)
            
        case .MFARequired:
            let mfaRequired: OktaAuthStatusFactorRequired = status as! OktaAuthStatusFactorRequired
            //self.handleFactorRequired(factorRequiredStatus: mfaRequired)
            
        case .MFAChallenge:
            let mfaChallenge: OktaAuthStatusFactorChallenge = status as! OktaAuthStatusFactorChallenge
            let factor = mfaChallenge.factor
            /*switch factor.type {
             case .sms:
             let smsFactor = factor as! OktaFactorSms
             self.handleSmsChallenge(factor: smsFactor)
             case .TOTP:
             let totpFactor = factor as! OktaFactorTotp
             self.handleTotpChallenge(factor: totpFactor)
             case .question:
             let questionFactor = factor as! OktaFactorQuestion
             self.handleQuestionChallenge(factor: questionFactor)
             case .push:
             let pushFactor = factor as! OktaFactorPush
             self.handlePushChallenge(factor: pushFactor)
             default:
             let alert = UIAlertController(title: "Error", message: "Recieved challenge for unsupported factor", preferredStyle: .alert)
             alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
             present(alert, animated: true, completion: nil)
             self.cancelTransaction()
             }*/
            
        case .recovery,
             .recoveryChallenge,
             .passwordReset,
             .lockedOut,
             .unauthenticated:
            let alert = UIAlertController(title: "Error", message: "No handler for \(status.statusType.description)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            //present(alert, animated: true, completion: nil)
            //self.cancelTransaction()
            
        case .unknown(_):
            let alert = UIAlertController(title: "Error", message: "Recieved unknown status", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            //present(alert, animated: true, completion: nil)
            //self.cancelTransaction()
        }
    }

    func handleSuccessStatus(status: OktaAuthStatusSuccess) {
        let userProfileViewController = AuthBaseViewController.instantiate(with: status,
                                                                           flowCoordinatorDelegate: self,
                                                                           storyBoardName: "UserProfile",
                                                                           viewControllerIdentifier: "UserProfile")
        rootViewController.pushViewController(userProfileViewController, animated: true)
    }

    func handlePasswordWarning(status: OktaAuthStatus) {
        let passwordManagementViewController = AuthBaseViewController.instantiate(with: status,
                                                                                  flowCoordinatorDelegate: self,
                                                                                  storyBoardName: "PasswordManagement",
                                                                                  viewControllerIdentifier: "PasswordManagement")
        rootViewController.pushViewController(passwordManagementViewController, animated: true)
    }

    func handlePasswordExpired(status: OktaAuthStatus) {
        let passwordManagementViewController = AuthBaseViewController.instantiate(with: status,
                                                                                  flowCoordinatorDelegate: self,
                                                                                  storyBoardName: "PasswordManagement",
                                                                                  viewControllerIdentifier: "PasswordManagement")
        rootViewController.pushViewController(passwordManagementViewController, animated: true)
    }
}

extension AuthFlowCoordinator: AuthFlowCoordinatorProtocol {
    func onStatusChanged(status: OktaAuthStatus) {
        self.handleStatus(status: status)
    }
    
    func onCancel() {
        rootViewController.popToRootViewController(animated: true)
    }
    
    func onPrevious() {
        
    }
}
