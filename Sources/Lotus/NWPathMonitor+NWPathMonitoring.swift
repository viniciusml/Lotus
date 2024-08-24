//
//  NWPathMonitor+NWPathMonitoring.swift
//
//
//  Created by Vinicius Leal on 24/08/2024.
//

import Network

extension NWPathMonitor: NWPathMonitoring {
    
    public var paths: AsyncStream<NWPath> {
        AsyncStream { continuation in
            pathUpdateHandler = { path in
                continuation.yield(path)
            }
            continuation.onTermination = { [weak self] _ in
                self?.cancel()
            }
            start(queue: DispatchQueue(label: "NetworkMonitor"))
        }
    }
}
