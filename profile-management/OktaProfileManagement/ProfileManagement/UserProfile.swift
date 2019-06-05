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

struct User : Codable {
    struct Profile: Codable {
        let login: String
        let firstName: String?
        let lastName: String?
        let email: String?
        let mobilePhone: String?
    }
    
    struct Link: Codable {
        let href: String
    }
    
    struct Credentials: Codable {
        struct RecoveryQuestion: Codable {
            let question: String
        }

        struct Provider: Codable {
            let type: String
            let name: String
        }

        let recoveryQuestion: RecoveryQuestion?
        let provider: Provider?
        
        enum CodingKeys: String, CodingKey {
            case provider
            case recoveryQuestion = "recovery_question"
        }
    }

    private(set) var id: String?
    private(set) var profile: Profile?
    private(set) var credentials: Credentials?
    private(set) var status: String?
    private(set) var created: Date?
    private(set) var activated: Date?
    private(set) var statusChanged: Date?
    private(set) var lastLogin: Date?
    private(set) var lastUpdated: Date?
    private(set) var passwordChanged: Date?
    
    private(set) var links: [String : Link]?
    
    enum CodingKeys: String, CodingKey {
        case id, profile, credentials, status, created, activated, statusChanged, lastLogin, lastUpdated, passwordChanged
        case links = "_links"
    }
}

extension User {
    mutating func updated(with user: User) {
        if let id = user.id {
            self.id = id
        }
        if let profile = user.profile {
            self.profile = profile
        }
        if let credentials = user.credentials {
            self.credentials = credentials
        }
        if let status = user.status {
            self.status = status
        }
        if let created = user.created {
            self.created = created
        }
        if let activated = user.activated {
            self.activated = activated
        }
        if let statusChanged = user.statusChanged {
            self.statusChanged = statusChanged
        }
        if let lastLogin = user.lastLogin {
            self.lastLogin = lastLogin
        }
        if let lastUpdated = user.lastUpdated {
            self.lastUpdated = lastUpdated
        }
        if let passwordChanged = user.passwordChanged {
            self.passwordChanged = passwordChanged
        }
        if let links = user.links {
            self.links = links
        }
    }
}
