//
//  NetworkMonitor.swift
//  
//
//  Created by Vinicius Leal on 24/08/2024.
//

import Foundation
import Network

public class NetworkMonitor: NetworkMonitoring {
    
    private let monitor: NWPathMonitoring
    
    public init(monitor: NWPathMonitoring = NWPathMonitor()) {
        self.monitor = monitor
    }
    
    public func hasInternetConnection() async -> Bool {
        await monitor.paths.contains(where: { $0.status == .satisfied })
    }
}
