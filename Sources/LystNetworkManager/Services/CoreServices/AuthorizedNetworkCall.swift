//
//  File.swift
//  
//
//  Created by Mohsin Hussain on 07/08/2021.
//

import Foundation

public protocol AuthorizedNetworking: Networking {
    
    func executeAuthorizedRequest<Response: APIResponseProtocol>(_ request: APIRequestProtocol,
                                                                 completion: @escaping (Response?, APIError?) -> Void)
}

public class AuthorizedNetworkService: LystNetworkService {
    
    private let keychainService: KeychainProtocol
    private var apiKey: String? = ""
    
    public override init(errorParser: APIErrorParsing, keychainService: KeychainProtocol) {
        self.keychainService = keychainService
        self.apiKey = keychainService.fetchAPIKey()
        
        super.init(errorParser: errorParser, keychainService: keychainService)
        
        keychainService.saveAPIKey(self.apiKey)
    }
}

// MARK: - AuthorizedNetworking -

extension AuthorizedNetworkService: AuthorizedNetworking {
    
    public func executeAuthorizedRequest<Response>(_ request: APIRequestProtocol,
                                            completion: @escaping (Response?, APIError?) -> Void) where Response: APIResponseProtocol {
        self.execute(request, completion: completion)
    }
}
