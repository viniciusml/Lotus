//
//  Cancellable.swift
//  
//
//  Created by Vinicius Leal on 11/08/2024.
//

import Foundation

public protocol OperationDefining {
    
    /// The underlying operation of the task.
    var operation: (() -> Void)? { get }
}

public protocol Cancellable {
    
    /// This method returns immediately, marking the task as being canceled.
    /// Once a task is marked as being canceled, `operation` is nulled.
    /// This method may be called on a task that is suspended.
    func cancel()
}

public typealias CancellableClosureBasedTask = Cancellable & OperationDefining
