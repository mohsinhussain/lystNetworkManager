//
//  File.swift
//  
//
//  Created by Mohsin Hussain on 07/08/2021.
//

import Foundation

public protocol APIError: Error {
    var statusCode: Int { get }
    var message: String { get }
    var reason: Reason { get }
}
