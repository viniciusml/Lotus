import XCTest
import Lotus

final class AsyncIntegrationTests: XCTestCase {
    
    // If the network is initially available, the given closure is invoked
    func testAsyncOperationExecutedWithConnectionAvailable() {
        let sut = NetworkOperationPerformer(networkMonitor: NetworkMonitorStub(connection: true))
        let exp = expectation(description: #function)
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
    }
    
    // If no network is available, the given closure is not invoked
    func testAsyncOperationNotExecutedWithNoConnectionAvailable() {
        let sut = NetworkOperationPerformer(networkMonitor: NetworkMonitorStub(connection: false))
        let exp = expectation(description: #function).inverted()
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
    }
    
    // If the network is initially not available but becomes available within the given timeout duration, the given closure is invoked
    func testAsyncOperationExecutedWithNoConnectionAvailableButResumedInTime() {
        let networkMonitor = NetworkMonitorStub(connection: false)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor)
        let exp = expectation(description: #function)
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 0.1)
        networkMonitor.flipConnectionStubbedStatusAndSimulateNotification()
        
        wait(for: [exp], timeout: 0.2)
    }
    
    // If the network is initially not available and becomes available only after the given timeout duration, the given closure is not invoked
    func testAsyncOperationNotExecutedWithNoConnectionAvailableButNotResumedInTime() {
        let networkMonitor = NetworkMonitorStub(connection: false)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor)
        let exp = expectation(description: #function).inverted()
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 0.1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            networkMonitor.flipConnectionStubbedStatusAndSimulateNotification()
        })
        
        wait(for: [exp], timeout: 0.1)
    }
}

private extension AsyncIntegrationTests {
    
    final class NetworkMonitorStub: NetworkMonitoring {
        
        private var stubbedHasInternetConnection: Bool
        
        init(connection stubbedHasInternetConnection: Bool) {
            self.stubbedHasInternetConnection = stubbedHasInternetConnection
        }
        
        func hasInternetConnection() -> Bool {
            stubbedHasInternetConnection
        }
        
        func flipConnectionStubbedStatusAndSimulateNotification() {
            stubbedHasInternetConnection = true
            NotificationCenter.default.post(
                name: Notification.Name("NetworkStatusDidChange"),
                object: nil,
                userInfo: ["connected": self.hasInternetConnection()]
            )
        }
    }
}

private extension XCTestExpectation {
    
    func inverted() -> Self {
        isInverted = true
        return self
    }
}
