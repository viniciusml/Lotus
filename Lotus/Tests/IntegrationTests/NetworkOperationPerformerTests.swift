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
        let sut = makeSUT()
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
    }
    
    func test_operationIsExecuted_inAbnormalNetworkConditions() {
        NetworkMonitorStub.stubHasInternetConnection(false)
        let exp = expectation(description: #function).inverted()
        let sut = makeSUT()
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
    }
}

private extension NetworkOperationPerformerTests {
    
    func makeSUT() -> NetworkOperationPerformer {
        let networkMonitor = NetworkMonitorStub()
        return NetworkOperationPerformer(networkMonitor: networkMonitor)
    }
    
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

private extension XCTestExpectation {
    
    func inverted() -> Self {
        isInverted = true
        return self
    }
}
