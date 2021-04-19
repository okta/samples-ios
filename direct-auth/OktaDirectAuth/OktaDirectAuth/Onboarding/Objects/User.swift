//
//  User.swift
//  OktaDirectAuth
//
//  Created by Mike Nachbaur on 2021-04-19.
//

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
