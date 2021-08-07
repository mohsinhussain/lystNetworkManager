//
//  File.swift
//  
//
//  Created by Mohsin Hussain on 07/08/2021.
//

import Foundation
import Alamofire

public typealias HTTPMethod = Alamofire.HTTPMethod
public protocol Networking {
    
    func execute<Response: APIResponseProtocol>(_ request: APIRequestProtocol, completion: @escaping (Response?, APIError?) -> Void)
    func executeUnauthorizationRequest<Response: APIResponseProtocol>(_ request: APIRequestProtocol,
                                                                      completion: @escaping (Response?, APIError?) -> Void)
    
    // Intended for requests with [[String: Any]] parameters that is not supported by Alamofire
    func executeArrayParametersRequest<Response: APIResponseProtocol>(_ request: APIRequestProtocol, completion: @escaping (Response?, APIError?) -> Void)
}

open class LystNetworkService: NSObject {
    
    private let keychainService: KeychainProtocol
    private let errorParser: APIErrorParsing
    
    private var apiKey: String? = ""
    
    public init(errorParser: APIErrorParsing, keychainService: KeychainProtocol) {
        self.keychainService = keychainService
        
        self.apiKey = keychainService.fetchAPIKey()
        self.errorParser = errorParser
        
        keychainService.saveAPIKey(apiKey)
    }
    
    // MARK: - Private -
    
    private func validateResponse(request: URLRequest?, response: HTTPURLResponse, data: Data?) -> Request.ValidationResult {
        if let error = errorParser.parse(response: response, data: data) {
            return .failure(error)
        }
        
        let statusCode = response.statusCode
        
        if !(statusCode <= 299 && statusCode >= 200) {
            return .failure(BackendError.serverError(withCode: statusCode))
        }
        
        return .success(())
    }
    
    private func encoding(for method: HTTPMethod) -> ParameterEncoding {
        if method == .get || method == .head {
            return URLEncoding.default
        } else {
            return JSONEncoding.default
        }
    }
    
    private func createAuthorizationHeaders() -> HTTPHeaders? {
        if let apiKey = self.apiKey {
            let headers = getAuthorizationHeader(with: apiKey)
            debugPrint("Authorization headers: \(String(describing: headers))")
            return headers
        } else {
            return nil
        }
        
    }
    
    private func getAuthorizationHeader(with apiKey: String) -> HTTPHeaders {
        let headers: HTTPHeaders = [
            "x-api-key": apiKey,
            "Accept": "application/json"
        ]
        return headers
    }
    
}

// MARK: - Networking -

extension LystNetworkService: Networking {
    
    // Request without the need of api token i.e. Sign in and Sign up
    public func executeUnauthorizationRequest<Response: APIResponseProtocol>(_ request: APIRequestProtocol,
                                                                      completion: @escaping (Response?, APIError?) -> Void) {
        self.execute(request, completion: completion)
    }
    
    public func executeArrayParametersRequest<Response: APIResponseProtocol>(_ request: APIRequestProtocol, completion: @escaping (Response?, APIError?) -> Void) {
        guard let url =  URL(string: request.endpoint) else {
            
            completion(nil, BackendError(statusCode: 0,
                                         message: "Invalid Request", reason: .generic, response: ""))
            
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: request.arrayParameters ?? [[:]])
        
        var requestEncoding: ParameterEncoding = URLEncoding.default
        if let customEncoding = request.customEncoding {
            requestEncoding = customEncoding
        } else {
            // isFormURLEncoded is used for sign in and sign up that needs x-www-form-urlencoded
            requestEncoding = self.encoding(for: request.isFormURLEncoded ?? false ? .get : request.method)
        }
                
        AF.request(request.endpoint,
                   method: request.method,
                   parameters: request.parameters,
                   encoding: requestEncoding,
                   headers: request.headers.count > 0 ? request.headers :
                    self.createAuthorizationHeaders())
            .validate(validateResponse)
            .responseJSON { (response) in
                self.responseJSONHandler(request, response: response, completion: completion)
            }
    }
    
    public func execute<Response: APIResponseProtocol>(_ request: APIRequestProtocol, completion: @escaping (Response?, APIError?) -> Void) {
        debugPrint("Request_: \(request)")
        debugPrint("Request_Endpoint: \(request.endpoint)")
        debugPrint("Request_Method: \(request.method)")
        debugPrint("Request_Parameters: \(request.parameters)")
        debugPrint("Request_Data: \(String(describing: request.formData))")
        debugPrint("Request_FormDataParameters: \(String(describing: request.formDataParameters))")
        debugPrint("Request_X_API_Key: \(String(describing: request.xAPIKey))")
        
        // Re-set variables values from keychain
        // as it won't be called again in this class' init due to override init in AuthorizedNetworkService
        self.apiKey = keychainService.fetchAPIKey()
        
        if request.formData != nil {
            requestMultipartFormData(request, completion: completion)
        } else {
            normalRequest(request, completion: completion)
        }
    }
    
    public func requestMultipartFormData<Response: APIResponseProtocol>(_ request: APIRequestProtocol,
                                                                 completion: @escaping (Response?, APIError?) -> Void) {
        
        guard let requestData = request.formData else {
            return
        }
        
        AF.upload(multipartFormData: { multipartFormData in
            let withName = request.parameters["withName"] as? String
            let fileName = request.parameters["fileName"] as? String
            let mimeType = request.parameters["mimeType"] as? String
            
            // formDataParameters will be appended if available. These are the extra parameters aside from the image data
            if let formDataParameters = request.formDataParameters, formDataParameters.count > 0 {
                for (key, value) in formDataParameters {
                    if let jsonData = try? JSONSerialization.data(withJSONObject: value) {
                        multipartFormData.append(jsonData, withName: key as String)
                    }
                }
            }
            multipartFormData.append(requestData, withName: withName!, fileName: fileName!, mimeType: mimeType!)
        },
                  
            // request.headers with count > 0 means it has a custom headers e.g. SignIn, Sign Up
            to: request.endpoint, usingThreshold: UInt64.init(), method: request.method,
            headers: request.headers.count > 0 ? request.headers :
                self.createAuthorizationHeaders())
            
            .responseJSON { (response) in
                self.responseJSONHandler(request, response: response, completion: completion)
        }
    }
    
    public  func normalRequest<Response: APIResponseProtocol>(_ request: APIRequestProtocol, completion: @escaping (Response?, APIError?) -> Void) {
        var requestEncoding: ParameterEncoding = URLEncoding.default
        if let customEncoding = request.customEncoding {
            requestEncoding = customEncoding
        } else {
            // isFormURLEncoded is used for sign in and sign up that needs x-www-form-urlencoded
            requestEncoding = self.encoding(for: request.isFormURLEncoded ?? false ? .get : request.method)
        }
        
        AF.request(request.endpoint,
                   method: request.method,
                   parameters: request.parameters,
                   encoding: requestEncoding,
                   headers: request.headers.count > 0 ? request.headers :
                    self.createAuthorizationHeaders())
            .validate(validateResponse)
            .responseJSON { (response) in
                self.responseJSONHandler(request, response: response, completion: completion)
            }
    }
    
    public  func responseJSONHandler<Response: APIResponseProtocol>(_ request: APIRequestProtocol,
                                                            response: DataResponse<Any, AFError>,
                                                            completion: @escaping (Response?, APIError?) -> Void) {
        print("response_StatusCode: \(String(describing: response.response?.statusCode)) for Endpoint: \(request.endpoint)")
        
        if response.response?.statusCode == 401 {
            completion(nil, BackendError.unauthorized)
            
        } else {
            switch response.result {
            case .success(let value):
                print("response_JSON: \(request.endpoint) \n \(value)")
                
                let response = Response(with: value)
                completion(response, nil)
            case .failure(let error):
                if error._code == 13 { // NSURLErrorTimedOut
                    completion(nil, BackendError(statusCode: response.response?.statusCode ?? 0,
                                                 message: "", reason: .requestTimeOut, response: ""))
                } else {
                    completion(nil, error.underlyingError as? APIError)
                }

                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("response_ErrorString: \(utf8Text)")
                }
            }
        }
    }
}
