//
//  File.swift
//  
//
//  Created by Mohsin Hussain on 07/08/2021.
//

import Foundation
import Alamofire

public protocol APIRequestProtocol {
    
    var endpoint: String { get }
    var method: HTTPMethod { get }
    var parameters: [String: Any] { get }
    var arrayParameters: [[String: Any]]? { get }
    var formData: Data? { get }
    var formDataParameters: [String: Any]? { get }
    var headers: HTTPHeaders { get }
    var isFormURLEncoded: Bool? { get }
    var xAPIKey: String { get }
    var customEncoding: ParameterEncoding? { get }
}

public extension APIRequestProtocol {

    var method: HTTPMethod { return .get }
    var parameters: [String: Any] { return [:] }
    var arrayParameters: [[String: Any]]? { return [[:]] }
    var headers: HTTPHeaders { return [:] }
    var formData: Data? { return nil }
    var formDataParameters: [String: Any]? { return [:] }
    var isFormURLEncoded: Bool? { return false }
    var customEncoding: ParameterEncoding? { return nil }
}
