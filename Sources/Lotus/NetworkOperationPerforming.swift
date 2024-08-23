//
//  NetworkOperationPerforming.swift
//
//
//  Created by Vinicius Leal on 11/08/2024.
//

import Foundation

public protocol NetworkOperationPerforming {
    
    /// Performs a network operation using the given `closure`, within the given `timeoutDuration`.
    /// If the network is not accessible within the given `timeoutDuration`, the operation is not performed.
    /// - Parameters:
    ///   - closure: the operation to be invoked
    ///   - timeoutDuration: the specified time interval for performing a re-try operation.
    /// - Returns: `CancellableClosureBasedTask` - a task that can be cancelled and retains an `operation` closure
    @discardableResult
    func performNetworkOperation(using closure: @escaping () -> Void, withinSeconds timeoutDuration: TimeInterval) -> CancellableClosureBasedTask
    
    /// Performs an async network operation using the given `operation`, within the given `timeoutDuration`.
    /// If the network is not accessible within the given `timeoutDuration`, the operation is not performed.
    /// - Parameters:
    ///   - operation: the operation to be invoked
    ///   - timeoutDuration: the specified time interval for performing a re-try operation.
    /// - Returns: `Cancellable` - a task that can be cancelled
    @discardableResult
    func perform(withinSeconds timeoutDuration: TimeInterval, operation: @Sendable @escaping () async -> ()) async -> Cancellable
}
