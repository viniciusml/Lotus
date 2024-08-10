import XCTest
import Lotus

final class AsyncIntegrationTests: XCTestCase {
    
    func testAsyncOperationExecutedWithConnectionAvailable() {
        let sut = NetworkOperationPerformer(networkMonitor: NetworkMonitorStub(connection: true))
        let exp = expectation(description: #function)
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
    }
    
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
