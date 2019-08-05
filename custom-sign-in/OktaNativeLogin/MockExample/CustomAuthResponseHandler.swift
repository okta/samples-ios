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

class CustomAuthResponseHandler: OktaAuthStatusResponseHandler {
    
    override func createAuthStatus(basedOn response: OktaAPISuccessResponse,
                                   and currentStatus: OktaAuthStatus) throws -> OktaAuthStatus {
        
        guard let statusType = response.status else {
            throw OktaError.invalidResponse
        }

        var authStatus = try super.createAuthStatus(basedOn: response, and: currentStatus)
        
        if statusType == .passwordExpired {
            authStatus = try! PasswordExpiredStatusMock(currentState: currentStatus, model: response)
        } else if (statusType == .passwordWarning) {
            authStatus = try! PasswordWarningStatusMock(currentState: currentStatus, model: response)
        }

        return authStatus
    }
}
