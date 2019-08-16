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
                handleSuccessStatus(status: status)
            
            case .passwordWarning:
                handlePasswordWarning(status: status)
            
            case .passwordExpired:
                handlePasswordExpired(status: status)

            case .MFARequired:
                self.handleFactorRequired(status: status)
            
            case .MFAChallenge:
                handleFactorChallenge(status: status)
            
            case .MFAEnroll:
                handleFactorEnrollment(status: status)
                 
            case .MFAEnrollActivate:
                handleFactorEnrollActivate(status: status)
            
            case .recoveryChallenge:
                handlePasswordRecoveryChallenge(status: status)
            
            case .recovery:
                handlePasswordRecovery(status: status)

            case .passwordReset:
                handlePasswordReset(status: status)
            
            case .lockedOut:
                handleLockedOut(status: status)
            
            case     .unauthenticated:
                let authBaseViewController = rootViewController.topViewController as! AuthBaseViewController
                authBaseViewController.showError(message: "Unexpected status")
            
            case .unknown(_):
                let authBaseViewController = rootViewController.topViewController as! AuthBaseViewController
                authBaseViewController.showError(message: "Recieved unknown status")
        }
    }

    func handleSuccessStatus(status: OktaAuthStatus) {
        let successStatus = status as! OktaAuthStatusSuccess
        if let _ = successStatus.sessionToken {
            let userProfileViewController = AuthBaseViewController.instantiate(with: status,
                                                                               flowCoordinatorDelegate: self,
                                                                               storyBoardName: "UserProfile",
                                                                               viewControllerIdentifier: "UserProfile")
            rootViewController.pushViewController(userProfileViewController, animated: true)
        } else {
            handleLockedOutSuccess(status: successStatus)
        }
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

    func handleFactorRequired(status: OktaAuthStatus) {
        let factorRequiredViewController = AuthBaseViewController.instantiate(with: status,
                                                                              flowCoordinatorDelegate: self,
                                                                              storyBoardName: "MFA",
                                                                              viewControllerIdentifier: "MFAViewController")
        rootViewController.pushViewController(factorRequiredViewController, animated: true)
    }

    func handleFactorChallenge(status: OktaAuthStatus) {
        let factorChallenge: OktaAuthStatusFactorChallenge = status as! OktaAuthStatusFactorChallenge
        handleChallengeForFactor(factor: factorChallenge.factor, status: status)
    }

    func handleChallengeForFactor(factor: OktaFactor, status: OktaAuthStatus) {
        
        var viewController: UIViewController?
        
        switch factor.type {
        case .sms, .call:
            viewController = AuthBaseViewController.instantiate(with: status,
                                                                flowCoordinatorDelegate: self,
                                                                storyBoardName: "MFASMS",
                                                                viewControllerIdentifier: "MFASMSViewController")
            
        case .TOTP:
            viewController = AuthBaseViewController.instantiate(with: status,
                                                                flowCoordinatorDelegate: self,
                                                                storyBoardName: "MFATOTP",
                                                                viewControllerIdentifier: "MFATOTPViewController")
            
        case .question:
            viewController = AuthBaseViewController.instantiate(with: status,
                                                                flowCoordinatorDelegate: self,
                                                                storyBoardName: "MFASecurityQuestion",
                                                                viewControllerIdentifier: "MFASecurityQuestionViewController")
            
        case .push:
            viewController = AuthBaseViewController.instantiate(with: status,
                                                                flowCoordinatorDelegate: self,
                                                                storyBoardName: "MFAPush",
                                                                viewControllerIdentifier: "MFAPushViewController")

        case .tokenHardware:
            viewController = AuthBaseViewController.instantiate(with: status,
                                                                flowCoordinatorDelegate: self,
                                                                storyBoardName: "MFAYubiKey",
                                                                viewControllerIdentifier: "MFAYubiKeyViewController")

        default:
            let authBaseViewController = rootViewController.topViewController as! AuthBaseViewController
            authBaseViewController.showError(message: "Not implemented!\nNo factor handler for \(factor.type.rawValue)")
        }

        if let viewController = viewController {
            rootViewController.pushViewController(viewController, animated: true)
        }
    }

    func handleFactorEnrollment(status: OktaAuthStatus) {
        let mfaEnrollmentViewController = AuthBaseViewController.instantiate(with: status,
                                                                             flowCoordinatorDelegate: self,
                                                                             storyBoardName: "MFAEnrollment",
                                                                             viewControllerIdentifier: "MFAEnrollment")
        rootViewController.pushViewController(mfaEnrollmentViewController, animated: true)
    }

    func handleFactorEnrollActivate(status: OktaAuthStatus) {
        let factorActivate: OktaAuthStatusFactorEnrollActivate = status as! OktaAuthStatusFactorEnrollActivate
        handleActivateForFactor(factor: factorActivate.factor, status: status)
    }

    func handleActivateForFactor(factor: OktaFactor, status: OktaAuthStatus) {
        var viewController: UIViewController?
        switch factor.type {
            case .sms, .call:
                viewController = AuthBaseViewController.instantiate(with: status,
                                                                    flowCoordinatorDelegate: self,
                                                                    storyBoardName: "MFASMS",
                                                                    viewControllerIdentifier: "MFASMSViewController")
            case .push:
                viewController = AuthBaseViewController.instantiate(with: status,
                                                                    flowCoordinatorDelegate: self,
                                                                    storyBoardName: "MFActivatePushTotp",
                                                                    viewControllerIdentifier: "MFActivatePushTotpViewController")
            case .TOTP:
                viewController = AuthBaseViewController.instantiate(with: status,
                                                                    flowCoordinatorDelegate: self,
                                                                    storyBoardName: "MFActivatePushTotp",
                                                                    viewControllerIdentifier: "MFActivatePushTotpViewController")
            default:
                let authBaseViewController = rootViewController.topViewController as! AuthBaseViewController
                authBaseViewController.showError(message: "Not implemented!\nNo factor handler for \(factor.type.rawValue)")
        }

        if let viewController = viewController {
            rootViewController.pushViewController(viewController, animated: true)
        }
    }

    func handlePasswordRecoveryChallenge(status: OktaAuthStatus) {
        let passwordRecoveryViewController = AuthBaseViewController.instantiate(with: status,
                                                                                flowCoordinatorDelegate: self,
                                                                                storyBoardName: "PasswordRecoveryChallenge",
                                                                                viewControllerIdentifier: "PasswordRecoveryChallengeViewController")
        rootViewController.pushViewController(passwordRecoveryViewController, animated: true)
    }

    func handlePasswordRecovery(status: OktaAuthStatus) {
        let passwordRecoveryViewController = AuthBaseViewController.instantiate(with: status,
                                                                                flowCoordinatorDelegate: self,
                                                                                storyBoardName: "PasswordRecovery",
                                                                                viewControllerIdentifier: "PasswordRecoveryViewController")
        rootViewController.pushViewController(passwordRecoveryViewController, animated: true)
    }

    func handlePasswordReset(status: OktaAuthStatus) {
        let passwordResetViewController = AuthBaseViewController.instantiate(with: status,
                                                                             flowCoordinatorDelegate: self,
                                                                             storyBoardName: "PasswordReset",
                                                                             viewControllerIdentifier: "PasswordResetViewController")
        rootViewController.pushViewController(passwordResetViewController, animated: true)
    }

    func handleLockedOut(status: OktaAuthStatus) {
        rootViewController.popToRootViewController(animated: true)
        let signInViewController = rootViewController.topViewController as! SignInViewController
        signInViewController.handleLockedOutStatus(status: status as! OktaAuthStatusLockedOut)
    }

    func handleLockedOutSuccess(status: OktaAuthStatus) {
        rootViewController.popToRootViewController(animated: true)
        let signInViewController = rootViewController.topViewController as! SignInViewController
        signInViewController.handleLockedOutSuccessStatus()
    }
}

extension AuthFlowCoordinator: AuthFlowCoordinatorProtocol {
    func onStatusChanged(status: OktaAuthStatus) {
        self.handleStatus(status: status)
    }
    
    func onCancel() {
        rootViewController.popToRootViewController(animated: true)
    }

    func onReturn(prevStatus: OktaAuthStatus) {
        let authViewController = rootViewController.viewControllers.first { viewController in
            let authViewController = viewController as! AuthBaseViewController
            if authViewController.status?.statusType == prevStatus.statusType {
                return true
            }
            return false
        }
        
        if let authViewController = authViewController as? AuthBaseViewController {
            authViewController.status = prevStatus
            rootViewController.popViewController(animated: true)
        }
    }
    
    func onLoggedOut() {
        rootViewController.popToRootViewController(animated: true)
    }
}
