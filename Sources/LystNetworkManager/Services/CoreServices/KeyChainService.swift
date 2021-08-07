//
//  File.swift
//  
//
//  Created by Mohsin Hussain on 07/08/2021.
//

import Foundation
import SwiftKeychainWrapper

public typealias KeychainProtocol = KeychainWriting & KeychainReading

public protocol KeychainWriting {
    func saveAPIKey(_ apiKey: String?)
}

public protocol KeychainReading {
    func fetchAPIKey() -> String?
}

public class KeychainService {

    public let keychain = KeychainWrapper.standard
    public init() {
        
    }
}

// MARK: - KeychainWriting -

extension KeychainService: KeychainWriting {

    public  func saveAPIKey(_ apiKey: String?) {
        guard let apiKey = apiKey else { return }
        keychain.set(apiKey, forKey: .apiKey)
    }
}

// MARK: - KeychainReading -

extension KeychainService: KeychainReading {

    public func fetchAPIKey() -> String? {
        guard let data = keychain.string(forKey: .apiKey) else { return nil }
        return data
    }
}

// MARK: - Keys -

private extension String {
    static let apiKey = "x-api-key"
}
