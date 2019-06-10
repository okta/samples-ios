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
import OktaOidc

class ProfileManager {
    private let stateManager: OktaOidcStateManager
    private let oktaApi: OktaApi
    
    private(set) var user: User?
    
    init(config: OktaOidcConfig, stateManager: OktaOidcStateManager) {
        self.stateManager = stateManager
        self.oktaApi = OktaApi(config: config)
    }

    func getUser(completion: @escaping ((User?, Error?) -> Void)) {
        guard let token = self.stateManager.accessToken else {
            completion(nil, OktaOidcError.noBearerToken)
            return
        }
    
        oktaApi.getUser(accessToken: token) { user, error in
            self.user = user
            completion(user, error)
        }
    }
    
    
    func changePassword(old: String, new: String, completion: @escaping ((Error?) -> Void)) {
        guard let token = self.stateManager.accessToken else {
            completion(OktaOidcError.noBearerToken)
            return
        }
        
        oktaApi.changePassword(accessToken: token, old: old, new: new) { user, error in
            guard let user = user else {
                completion(error)
                return
            }
            
            self.user?.updated(with: user)
            completion(nil)
        }
    }
}
