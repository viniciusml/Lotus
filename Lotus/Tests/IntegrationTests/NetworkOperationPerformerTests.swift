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
    
    func test_operationIsNotExecuted_inAbnormalNetworkConditions() {
        NetworkMonitorStub.stubHasInternetConnection(false)
        let notificationCenter = NotificationCenterSpy()
        let exp = expectation(description: #function).inverted()
        let sut = makeSUT(notificationCenter: notificationCenter)
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
        XCTAssertEqual(notificationCenter.log, [.addObserver(.init("NetworkStatusDidChange"))])
    }
}

private extension NetworkOperationPerformerTests {
    
    func makeSUT(notificationCenter: NotificationCenter = .default) -> NetworkOperationPerformer {
        let networkMonitor = NetworkMonitorStub()
        return NetworkOperationPerformer(
            networkMonitor: networkMonitor,
            notificationCenter: notificationCenter)
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
    
    final class NotificationCenterSpy: NotificationCenter {
        
        enum MethodCall: Equatable {
            case addObserver(NSNotification.Name?)
            case removeObserver
        }
        
        private(set) var log: [MethodCall] = []
        
        override func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?) {
            log.append(.addObserver(aName))
        }
        
        override func removeObserver(_ observer: Any) {
            log.append(.removeObserver)
        }
    }
}

private extension XCTestExpectation {
    
    func inverted() -> Self {
        isInverted = true
        return self
    }
}
