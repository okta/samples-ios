/*
 * Copyright (c) 2021, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation
import OktaIdx

class User: Codable {
    let token: IDXClient.Token
    lazy var profileInfo: [String:Any]? = {
        token.profile
    }()
    
    lazy var authenticatedAt: Date? = {
        guard let epoch = profileInfo?["auth_at"] as? TimeInterval else { return nil }
        return Date(timeIntervalSince1970: epoch)
    }()
    
    lazy var expiresAt: Date? = {
        guard let epoch = profileInfo?["exp"] as? TimeInterval else { return nil }
        return Date(timeIntervalSince1970: epoch)
    }()
    
    lazy var authenticatorMethods: [String]? = {
        profileInfo?["amr"] as? [String]
    }()
    
    init(with token: IDXClient.Token) {
        self.token = token
    }
    
    subscript(key: ProfileKey) -> String? {
        profileInfo?[key.rawValue] as? String
    }
    
    enum ProfileKey: String, CaseIterable {
        case id, name, email, profile, nickname, zoneinfo, locale
        case username = "preferred_username"
        case givenName = "given_name"
        case middleName = "middle_name"
        case familyName = "family_name"
        case phoneNumber = "phone_number"
    }
}
