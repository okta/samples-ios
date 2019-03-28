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
import LocalAuthentication

open class OktaSecureStorage: NSObject {

    static let keychainErrorDomain = "com.okta.securestorage"

    @objc open func set(_ string: String, forKey key: String) throws {
        
        try set(string, forKey: key, behindBiometrics: false)
    }
    
    @objc open func set(_ string: String, forKey key: String, behindBiometrics: Bool) throws {

        try set(string, forKey: key, behindBiometrics: behindBiometrics, accessGroup: nil, accessibility: nil)
    }
    
    @objc open func set(_ string: String,
                        forKey key: String,
                        behindBiometrics: Bool,
                        accessibility: CFString) throws {

        try set(string, forKey: key, behindBiometrics: behindBiometrics, accessGroup: nil, accessibility: accessibility)
    }
    
    @objc open func set(_ string: String,
                        forKey key: String,
                        behindBiometrics: Bool,
                        accessGroup: String) throws {

        try set(string, forKey: key, behindBiometrics: behindBiometrics, accessGroup: accessGroup, accessibility: nil)
    }
    
    @objc open func set(_ string: String,
                        forKey key: String,
                        behindBiometrics: Bool,
                        accessGroup: String?,
                        accessibility: CFString?) throws {
        
        guard let bytesStream = string.data(using: .utf8) else {
            throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errSecParam), userInfo: nil)
        }

        try set(data: bytesStream, forKey: key, behindBiometrics: behindBiometrics, accessGroup: accessGroup, accessibility: accessibility)
    }
    
    @objc open func set(data: Data, forKey key: String) throws {
        
        try set(data: data, forKey: key, behindBiometrics: false)
    }
    
    @objc open func set(data: Data, forKey key: String, behindBiometrics: Bool) throws {
        
        try set(data: data, forKey: key, behindBiometrics: behindBiometrics, accessGroup: nil, accessibility: nil)
    }
    
    @objc open func set(data: Data,
                        forKey key: String,
                        behindBiometrics: Bool,
                        accessibility: CFString) throws {
        
        try set(data: data, forKey: key, behindBiometrics: false, accessGroup: nil, accessibility: accessibility)
    }
    
    @objc open func set(data: Data,
                        forKey key: String,
                        behindBiometrics: Bool,
                        accessGroup: String) throws {
        
        try set(data: data, forKey: key, behindBiometrics: behindBiometrics, accessGroup: accessGroup, accessibility: nil)
    }
    
    @objc open func set(data: Data,
                        forKey key: String,
                        behindBiometrics: Bool,
                        accessGroup: String?,
                        accessibility: CFString?) throws {

        var query = baseQuery()
        query[kSecValueData as String] = data
        query[kSecAttrAccount as String] = key
        
        if behindBiometrics {
            
            var cfError: Unmanaged<CFError>?
            
            var flags = SecAccessControlCreateFlags()
            if #available(iOS 11.3, *) {
                flags = SecAccessControlCreateFlags.biometryCurrentSet
            } else {
                flags = SecAccessControlCreateFlags.touchIDCurrentSet
            }

            let secAccessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                   accessibility ?? kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                                   [flags,
                                                                    SecAccessControlCreateFlags.or,
                                                                    SecAccessControlCreateFlags.devicePasscode],
                                                                   &cfError)
            
            if let error: Error = cfError?.takeRetainedValue() {
                
                throw error
            }
            
            query[kSecAttrAccessControl as String] = secAccessControl

        } else {
            query[kSecAttrAccessible as String] = accessibility ?? kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }

        var errorCode = SecItemAdd(query as CFDictionary, nil)
        if errorCode == noErr {
            return
        } else if errorCode == errSecDuplicateItem {
            
            errorCode = SecItemDelete(query as CFDictionary)
            if errorCode != noErr {
                throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errorCode), userInfo: nil)
            }

            errorCode = SecItemAdd(query as CFDictionary, nil)
            if errorCode != noErr {
                throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errorCode), userInfo: nil)
            }
        } else {
            throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errorCode), userInfo: nil)
        }
    }

    @objc open func get(key: String, biometricPrompt prompt: String? = nil) throws -> String {
        
        let data = try getData(key: key, biometricPrompt: prompt)
        guard let string = String(data: data, encoding: .utf8) else {
            throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errSecInvalidData), userInfo: nil)
        }
        
        return string
    }

    @objc open func getData(key: String, biometricPrompt prompt: String? = nil) throws -> Data {
        
        var query = findQuery(for: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        if let prompt = prompt {
            query[kSecUseOperationPrompt as String] = prompt
        }
        
        var ref: AnyObject? = nil
        
        let errorCode = SecItemCopyMatching(query as CFDictionary, &ref)
        guard errorCode == noErr, let data = ref as? Data else {
            throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errorCode), userInfo: nil)
        }

        return data
    }

    @objc open func delete(key: String) throws {
        
        let query = findQuery(for: key)
        let errorCode = SecItemDelete(query as CFDictionary)
        if errorCode != noErr && errorCode != errSecItemNotFound {
            throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errorCode), userInfo: nil)
        }
    }
    
    @objc open func clear() throws {
        
        let query = baseQuery()
        let errorCode = SecItemDelete(query as CFDictionary)
        if errorCode != noErr && errorCode != errSecItemNotFound {
            throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errorCode), userInfo: nil)
        }
    }

    @objc open func isTouchIDSupported() -> Bool  {
        
        let laContext = LAContext()
        var touchIdSupported = false
        if #available(iOS 11.0, *) {
            let touchIdEnrolled = laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            touchIdSupported = laContext.biometryType == .touchID && touchIdEnrolled
        } else {
            touchIdSupported = laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        }
        return touchIdSupported
    }
    
    @objc open func isFaceIDSupported() -> Bool {
        
        let  laContext = LAContext()
        let biometricsEnrolled = laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        var faceIdSupported = false
        if #available(iOS 11.0, *) {
            faceIdSupported = laContext.biometryType == .faceID
        }
        return biometricsEnrolled && faceIdSupported
    }
    
    @objc open func bundleSeedId() throws -> String {

        var query = baseQuery()
        query[kSecAttrAccount as String] = "bundleSeedID"
        query[kSecReturnAttributes as String] = kCFBooleanTrue

        var ref: AnyObject? = nil

        var errorCode = SecItemCopyMatching(query as CFDictionary, &ref)
        if errorCode == errSecItemNotFound {
            errorCode = SecItemAdd(query as CFDictionary, &ref)
            guard errorCode == noErr else {
                throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errorCode), userInfo: nil)
            }
        }

        guard let returnedDictionary = ref as? Dictionary<String, Any> else {
            throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errSecDecode), userInfo: nil)
        }

        guard let accessGroup = returnedDictionary[kSecAttrAccessGroup as String] as? String else {
           throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errSecDecode), userInfo: nil)
        }

        let components = accessGroup.components(separatedBy: ".")

        guard let teamId = components.first else {
            throw NSError(domain: OktaSecureStorage.keychainErrorDomain, code: Int(errSecDecode), userInfo: nil)
        }

        return teamId
    }
    
    //MARK: Private
    
    private func baseQuery() -> Dictionary<String, Any> {
        
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: "OktaSecureStorage"]

        return query
    }
    
    private func findQuery(for key: String) -> Dictionary<String, Any> {
        
        var query = baseQuery()
        query[kSecAttrAccount as String] = key

        return query
    }
}
