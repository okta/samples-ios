//
//  OnboardingError.swift
//  OktaDirectAuth
//
//  Created by Mike Nachbaur on 2021-04-19.
//

import Foundation

enum OnboardingError: Error, LocalizedError {
    case missingViewController
    case missingResponse
    
    var errorDescription: String? {
        switch self {
        case .missingViewController:
            return "Missing view controller"
        case .missingResponse:
            return "Missing authentication response"
        }
    }
}
