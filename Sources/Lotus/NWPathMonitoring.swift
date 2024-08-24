//
//  NWPathMonitoring.swift
//  
//
//  Created by Vinicius Leal on 24/08/2024.
//

import Foundation
import Network

public protocol NWPathMonitoring {
    var paths: AsyncStream<NWPath> { get }
}
