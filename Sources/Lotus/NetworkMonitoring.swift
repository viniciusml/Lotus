//
//  NetworkMonitoring.swift
//
//
//  Created by Vinicius Leal on 10/08/2024.
//

import Foundation

public protocol NetworkMonitoring {
    
    /// Returns state of internet connection.
    /// - Returns: `Bool`
    func hasInternetConnection() -> Bool
    
    /// Returns a Boolean value that indicates whether the asynchronous condition is satisfied.
    /// - Returns: `Bool`
    func hasInternetConnection() async -> Bool
}
