//
//  NetworkOperationPerformerTests.swift
//
//
//  Created by Vinicius Leal on 07/08/2024.
//

import Lotus
import XCTest

final class NetworkOperationPerformerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        SleeperSpy.resetLog()
    }
    
    override func tearDown() {
        SleeperSpy.resetLog()
        super.tearDown()
    }
    
    func test_operationIsExecutedAsync_inNormalNetworkConditions() async {
        NetworkMonitorStub.stubHasInternetConnection(true)
        let exp = expectation(description: #function)
        let sut = makeSUT()
        
        await sut.perform(withinSeconds: 3) {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 0.1)
    }
    
    func test_operationIsNotExecutedAsync_inAbnormalNetworkConditions() async {
        NetworkMonitorStub.stubHasInternetConnection(false)
        let exp = expectation(description: #function).inverted()
        let sut = makeSUT()
        
        await sut.perform(withinSeconds: 3) {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 0.1)
        XCTAssertEqual(SleeperSpy.log, [.sleep(3000000000)])
    }
}

private extension NetworkOperationPerformerTests {
    
    func makeSUT() -> NetworkOperationPerformer {
        let networkMonitor = NetworkMonitorStub()
        return NetworkOperationPerformer(
            networkMonitor: networkMonitor,
            sleepAction: SleeperSpy.sleep(nanoseconds:))
    }
    
    final class NetworkMonitorStub: NetworkMonitoring {
        
        private static var stubbedHasInternetConnection: Bool = false
        
        func hasInternetConnection() async -> Bool {
            Self.stubbedHasInternetConnection
        }
        
        static func stubHasInternetConnection(_ value: Bool) {
            stubbedHasInternetConnection = value
        }
    }
    
    final class SleeperSpy {
        
        enum MethodCall: Equatable {
            case sleep(UInt64)
        }
        
        private(set) static var log: [MethodCall] = []
        
        static func sleep(nanoseconds duration: UInt64) async throws {
            log.append(.sleep(duration))
        }
        
        static func resetLog() {
            log = []
        }
    }
}

private extension XCTestExpectation {
    
    func inverted() -> Self {
        isInverted = true
        return self
    }
}
