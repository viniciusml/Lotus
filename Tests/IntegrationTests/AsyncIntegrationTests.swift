import XCTest
import Lotus

final class AsyncIntegrationTests: XCTestCase {
    
    // If the network is initially available, the given closure is invoked
    func testAsyncOperationExecutedWithConnectionAvailableAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: true)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor)
        let exp = expectation(description: #function)
        
        await sut.perform(withinSeconds: 3) {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 0.1)
    }
    
    // If no network is available, the given closure is not invoked
    func testAsyncOperationNotExecutedWithNoConnectionAvailableAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: false)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor)
        let exp = expectation(description: #function).inverted()
        
        await sut.perform(withinSeconds: 3) {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 0.1)
    }
    
    // If the network is initially not available but becomes available within the given timeout duration, the given closure is invoked
    func testAsyncOperationExecutedWithNoConnectionAvailableButResumedInTimeAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: false)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor)
        let exp = expectation(description: #function)
        
        await networkMonitor.flipConnectionStubbedStatus(after: 0.1)
        await sut.perform(withinSeconds: 0.2) {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 0.3)
    }
    
    // If the network is initially not available and becomes available only after the given timeout duration, the given closure is not invoked
    func testAsyncOperationNotExecutedWithNoConnectionAvailableButNotResumedInTimeAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: false)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor)
        let exp = expectation(description: #function).inverted()
        
        await sut.perform(withinSeconds: 0.1) {
            exp.fulfill()
        }
        await networkMonitor.flipConnectionStubbedStatus(after: 0.2)
        
        await fulfillment(of: [exp], timeout: 0.1)
    }
    
    // If the network is initially not available and is cancelled before network being available in the given timeout, the given closure is not invoked
    func testAsyncOperationNotExecutedWithNoConnectionAvailableAndCancelledBeforeNetworkResumedInTimeAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: false)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor)
        let exp = expectation(description: #function).inverted()
        
        let task = await sut.perform(withinSeconds: 0.1) {
            exp.fulfill()
        }
        await networkMonitor.flipConnectionStubbedStatus(after: 0.2)
        task.cancel()
        
        await fulfillment(of: [exp], timeout: 0.1)
    }
    
    // If the network is initially available, the given closure is invoked even if the task is cancelled
    func testAsyncOperationExecutedWithConnectionAvailableAndTaskCancelledAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: true)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor)
        let exp = expectation(description: #function)
        
        await sut.perform(withinSeconds: 3) {
            exp.fulfill()
        }.cancel()
        
        await fulfillment(of: [exp], timeout: 0.1)
    }
}

private extension AsyncIntegrationTests {
    
    final class NetworkMonitorStub: NetworkMonitoring {
        
        private var stubbedHasInternetConnection: Bool
        
        init(connection stubbedHasInternetConnection: Bool) {
            self.stubbedHasInternetConnection = stubbedHasInternetConnection
        }
        
        func hasInternetConnection() async -> Bool {
            stubbedHasInternetConnection
        }
        
        func flipConnectionStubbedStatus(after timeInterval: TimeInterval) async {
            try? await Task.sleep(nanoseconds: UInt64(timeInterval.nanoseconds))
            stubbedHasInternetConnection = true
        }
    }
}

private extension XCTestExpectation {
    
    func inverted() -> Self {
        isInverted = true
        return self
    }
}
