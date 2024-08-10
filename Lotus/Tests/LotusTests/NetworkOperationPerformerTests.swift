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
        let notificationCenter = NotificationCenterSpy()
        let timer = TimerSpy()
        let exp = expectation(description: #function)
        let sut = makeSUT(notificationCenter: notificationCenter, timerAction: timer.scheduledTimer)
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
        XCTAssertEqual(notificationCenter.log, [])
        XCTAssertEqual(timer.log, [])
    }
    
    func test_operationIsExecuted_inNormalNetworkConditions() async {
        NetworkMonitorStub.stubHasInternetConnection(true)
        let notificationCenter = NotificationCenterSpy()
        let timer = TimerSpy()
        let exp = expectation(description: #function)
        let sut = makeSUT(notificationCenter: notificationCenter, timerAction: timer.scheduledTimer)
        
        await sut.perform(withinSeconds: 3) {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp])
        XCTAssertEqual(notificationCenter.log, [])
        XCTAssertEqual(timer.log, [])
    }
    
    func test_operationIsNotExecuted_inAbnormalNetworkConditions() {
        NetworkMonitorStub.stubHasInternetConnection(false)
        let notificationCenter = NotificationCenterSpy()
        let timer = TimerSpy()
        let exp = expectation(description: #function).inverted()
        let sut = makeSUT(notificationCenter: notificationCenter, timerAction: timer.scheduledTimer)
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
        XCTAssertEqual(notificationCenter.log, [.addObserver(.init("NetworkStatusDidChange"))])
        XCTAssertEqual(timer.log, [.scheduledTimer(3)])
    }
    
    func test_operationIsNotExecuted_inAbnormalNetworkConditions() async {
        NetworkMonitorStub.stubHasInternetConnection(false)
        let notificationCenter = NotificationCenterSpy()
        let timer = TimerSpy()
        let exp = expectation(description: #function).inverted()
        let sut = makeSUT(notificationCenter: notificationCenter, timerAction: timer.scheduledTimer)
        
        await sut.perform(withinSeconds: 3) {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp])
        XCTAssertEqual(notificationCenter.log, [.addObserver(.init("NetworkStatusDidChange"))])
        XCTAssertEqual(timer.log, [.scheduledTimer(3)])
    }
}

private extension NetworkOperationPerformerTests {
    
    func makeSUT(
        notificationCenter: NotificationCenter = .default,
        timerAction: @escaping NetworkOperationPerformer.TimerAction = Timer.scheduledTimer
    ) -> NetworkOperationPerformer {
        let networkMonitor = NetworkMonitorStub()
        return NetworkOperationPerformer(
            networkMonitor: networkMonitor,
            notificationCenter: notificationCenter,
            timerAction: timerAction)
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
    
    final class TimerSpy {
        
        enum MethodCall: Equatable {
            case scheduledTimer(TimeInterval)
        }
        
        private(set) var log: [MethodCall] = []
        
        func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
            log.append(.scheduledTimer(interval))
            return Timer()
        }
    }
}

private extension XCTestExpectation {
    
    func inverted() -> Self {
        isInverted = true
        return self
    }
}
