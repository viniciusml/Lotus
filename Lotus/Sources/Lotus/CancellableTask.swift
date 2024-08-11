//
//  CancellableTask.swift
//  
//
//  Created by Vinicius Leal on 11/08/2024.
//

import Foundation

public protocol CancellableTask {
    
    /// The underlying operation of the task.
    var operation: (() -> Void)? { get }
    
    
    /// This method returns immediately, marking the task as being canceled. 
    /// Once a task is marked as being canceled, `operation` is nulled.
    /// This method may be called on a task that is suspended.
    func cancel()
}
