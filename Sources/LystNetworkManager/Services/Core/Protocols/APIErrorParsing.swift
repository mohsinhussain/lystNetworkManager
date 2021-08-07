//
//  File.swift
//  
//
//  Created by Mohsin Hussain on 07/08/2021.
//

import Foundation

public protocol APIErrorParsing {
    func parse(response: HTTPURLResponse, data: Data?) -> APIError?
}
