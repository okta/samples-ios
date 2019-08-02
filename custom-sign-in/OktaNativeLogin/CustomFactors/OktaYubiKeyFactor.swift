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

class OktaYubiKeyFactor {
    
    class func verifyFactor(_ factor: OktaFactorOther,
                            stateToken: String,
                            passCode: String,
                            onStatusChange: @escaping (OktaAuthStatus) -> Void,
                            onError: @escaping (OktaError) -> Void) {
        var bodyParams: Dictionary<String, Any> = [:]
        bodyParams["stateToken"] = stateToken
        bodyParams["factorType"] = "token:hardware"
        bodyParams["passCode"] = passCode
        bodyParams["provider"] = "YUBICO"
        factor.sendRequest(with: factor.factor.links!.next!, keyValuePayload: bodyParams, onStatusChange: { status in
            onStatusChange(status)
        }) { error in
            onError(error)
        }
    }
}
