//
//  TimeInterval+Nanoseconds.swift
//
//
//  Created by Vinicius Leal on 23/08/2024.
//

import Foundation

public extension TimeInterval {
    
    /**
     The number of nanoseconds in the `TimeInterval`.
     */
    var nanoseconds: Double {
        self * 1_000_000_000
    }
}
