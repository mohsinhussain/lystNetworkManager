//
//  File.swift
//  
//
//  Created by Mohsin Hussain on 07/08/2021.
//

import Foundation

public enum Reason {
    case generic
    case networkConnectionError
    case serverError
    case requestTimeOut
    case unauthorized
}

public struct BackendError: APIError {
    public var statusCode: Int
    public var message: String
    public var response: String
    public var reason: Reason
    
    public init(statusCode: Int, message: String, reason: Reason, response: String) {
        self.statusCode = statusCode
        self.message = message
        self.reason = reason
        self.response = response
    }
}

extension BackendError {
    
    public static var unauthorized: BackendError {
        return BackendError(statusCode: 401, message: "Unauthorized Call", reason: .generic, response: "")
    }
    
    public static func serverError(withCode code: Int) -> BackendError {
        return BackendError(statusCode: code, message: "Server Error, Code: \(code)", reason: .serverError, response: "")
    }
    
    public  static var requestTimedOut: BackendError {
        return BackendError(statusCode: -1001, message: "Request Timeout", reason: .requestTimeOut, response: "")
    }
}
