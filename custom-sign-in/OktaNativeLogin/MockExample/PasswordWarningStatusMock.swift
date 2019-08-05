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

class PasswordWarningStatusMock: OktaAuthStatusPasswordWarning {
    
    override func canCancel() -> Bool {
        return true
    }
    
    override func canChange() -> Bool {
        return true
    }
    
    override func cancel(onSuccess: (() -> Void)?, onError: ((OktaError) -> Void)?) {
        super.cancel(onSuccess: onSuccess, onError: onError)
    }

    override func skipPasswordChange(onStatusChange: @escaping (OktaAuthStatus) -> Void, onError: @escaping (OktaError) -> Void) {
        let successStatus = try? OktaAuthStatusSuccess(currentState: self, model: self.model)
        if let successStatus = successStatus {
            successStatus.sessionToken = "session_token"
            onStatusChange(successStatus)
        }
    }
    
    override func changePassword(oldPassword: String,
                                 newPassword: String,
                                 onStatusChange: @escaping (OktaAuthStatus) -> Void,
                                 onError: @escaping (OktaError) -> Void) {
        let successStatus = try? OktaAuthStatusSuccess(currentState: self, model: self.model)
        if let successStatus = successStatus {
            successStatus.sessionToken = "session_token"
            onStatusChange(successStatus)
        }
    }
}
