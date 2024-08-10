import XCTest
import Lotus

final class AsyncIntegrationTests: XCTestCase {
    
    func testAsyncOperationExecutedWithConnectionAvailable() throws {
        let sut = NetworkOperationPerformer(networkMonitor: connectionAvaileble(true))
        let exp = expectation(description: #function)
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
    }
}

private extension AsyncIntegrationTests {
    
    func connectionAvaileble(_ value: Bool) -> NetworkMonitorStub {
        NetworkMonitorStub(value)
    }
    
    final class NetworkMonitorStub: NetworkMonitoring {
        
        private let stubbedHasInternetConnection: Bool
        
        init(_ stubbedHasInternetConnection: Bool) {
            self.stubbedHasInternetConnection = stubbedHasInternetConnection
        }
        
        func hasInternetConnection() -> Bool {
            stubbedHasInternetConnection
        }
    }
}
