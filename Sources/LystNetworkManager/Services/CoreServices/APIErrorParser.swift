//
//  File.swift
//  
//
//  Created by Mohsin Hussain on 07/08/2021.
//

import Foundation

public class APIErrorParser {
    
    // MARK: - Private -

    public init() {
        
    }
    private func validationError(from json: [String: Any]) -> APIError? {
        guard let status = json["status"] as? Int,
            let errors = json["errors"] as? [String: [String]] else {
                return nil
        }
        
        // concatenate all error messages into single string
        let errorMessages = errors.flatMap { $1 }
        return BackendError(statusCode: status, message: errorMessages.joined(separator: "\n"), reason: .generic, response: "")
    }
    
    private func failure(from json: [String: Any]) -> APIError? {
        guard let success = json["succeeded"] as? Bool,
            let message = json["message"] as? String else {
                return nil
        }
        
        
        return success ? nil : BackendError(statusCode: -1001, message: message, reason: .requestTimeOut, response: "")
    }
    
    private func exception(from json: [String: Any], statusCode: Int) -> APIError? {
        guard let message = json["error"] as? String
              else { return nil }
        let response = json["responseObject"] as? String
        debugPrint("Response_Error: \(message)")
        return BackendError(statusCode: statusCode, message: message, reason: .generic, response: response ?? "")
    }
    
    private func isCodeValid(_ statusCode: Int) -> Bool {
        return (200...299).contains(statusCode)
    }
}

extension APIErrorParser: APIErrorParsing {
    
    public  func parse(response: HTTPURLResponse, data: Data?) -> APIError? {
        guard let data = data,
            let json = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any] else {
                return isCodeValid(response.statusCode) ? nil : BackendError.serverError(withCode: response.statusCode)
        }
                
        return validationError(from: json) ?? exception(from: json, statusCode: response.statusCode) ?? failure(from: json)
    }
}
