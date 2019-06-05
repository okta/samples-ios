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
    private let config: OktaOidcConfig
    
    private(set) var user: User?
    
    lazy private var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }()
    
    init(config: OktaOidcConfig, stateManager: OktaOidcStateManager) {
        self.config = config
        self.stateManager = stateManager
    }

    func getUser(completion: @escaping ((User?, Error?) -> Void)) {
        guard let token = self.stateManager.accessToken else {
            completion(nil, OktaOidcError.noBearerToken)
            return
        }
        
        var url = URL(string: self.config.issuer)!
        url.appendPathComponent("/api/v1/users/me")
        
        var request = URLRequest(url: url)
        request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")
    
        performRequest(request) { data, error in
            guard nil == error else {
                completion(nil, OktaOidcError.APIError(error!.localizedDescription))
                return
            }

            guard let data = data else {
                completion(nil, OktaOidcError.APIError("No response data"))
                return
            }

            do {
                let user = try self.decoder.decode(User.self, from: data)
                
                self.user = user
                completion(user, nil)
            } catch {
                print(error)
                completion(nil, OktaOidcError.parseFailure)
            }
        }
    }
    
    
    func changePassword(old: String, new: String, completion: @escaping ((Error?) -> Void)) {
        guard let token = self.stateManager.accessToken else {
            completion(OktaOidcError.noBearerToken)
            return
        }
        
        var url = URL(string: self.config.issuer)!
        url.appendPathComponent("/api/v1/users/me/credentials/change_password")
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        
        let passwordInfo = PasswordChange(old: old, new: new)
        request.httpBody = try? JSONEncoder().encode(passwordInfo)
    
        performRequest(request) { data, error in
            guard nil == error else {
                completion(OktaOidcError.APIError(error!.localizedDescription))
                return
            }

            guard let data = data else {
                completion(OktaOidcError.APIError("No response data"))
                return
            }

            do {
                let userPatch = try self.decoder.decode(User.self, from: data)
                self.user?.updated(with: userPatch)
                completion(nil)
            } catch {
                print(error)
                completion(OktaOidcError.parseFailure)
            }
        }
    }
    
    // MARK: - Private
    
    func performRequest(_ request: URLRequest, completion: @escaping ((Data?, Error?) -> Void)) {
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        
        task.resume()
    }
}
