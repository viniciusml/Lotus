//
//  NetworkOperationPerformerTests.swift
//
//
//  Created by Vinicius Leal on 07/08/2024.
//

import Lotus
import XCTest

final class NetworkOperationPerformerTests: XCTestCase {
    
    func test_operationIsExecuted_inNormalNetworkConditions() {
        NetworkMonitorStub.stubHasInternetConnection(true)
        let exp = expectation(description: #function)
        let sut = NetworkOperationPerformer(networkMonitor: NetworkMonitorStub())
        let networkOperationClosure: () -> Void = {
            exp.fulfill()
        }
        
        sut.performNetworkOperation(using: networkOperationClosure, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
    }
}

private extension NetworkOperationPerformerTests {
    
    final class NetworkMonitorStub: NetworkMonitoring {
        
        private static var stubbedHasInternetConnection: Bool = false
        
        func hasInternetConnection() -> Bool {
            Self.stubbedHasInternetConnection
        }
        
        static func stubHasInternetConnection(_ value: Bool) {
            stubbedHasInternetConnection = value
        }
    }
}
