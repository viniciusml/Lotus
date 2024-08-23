import XCTest
import Lotus

final class AsyncIntegrationTests: XCTestCase {
    
    private var notificationCenter: NotificationCenter!
    
    override func setUp() {
        super.setUp()
        
        notificationCenter = NotificationCenter()
    }
    
    override func tearDown() {
        
        notificationCenter = nil
        super.tearDown()
    }
    
    // If the network is initially available, the given closure is invoked
    func testAsyncOperationExecutedWithConnectionAvailable() {
        let networkMonitor = NetworkMonitorStub(connection: true, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function)
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
    }
    
    func testAsyncOperationExecutedWithConnectionAvailableAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: true, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function)
        
        await sut.perform(withinSeconds: 3) {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 0.1)
    }
    
    // If no network is available, the given closure is not invoked
    func testAsyncOperationNotExecutedWithNoConnectionAvailable() {
        let networkMonitor = NetworkMonitorStub(connection: false, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function).inverted()
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        
        wait(for: [exp], timeout: 0.1)
    }
    
    func testAsyncOperationNotExecutedWithNoConnectionAvailableAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: false, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function).inverted()
        
        await sut.perform(withinSeconds: 3) {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 0.1)
    }
    
    // If the network is initially not available but becomes available within the given timeout duration, the given closure is invoked
    func testAsyncOperationExecutedWithNoConnectionAvailableButResumedInTime() {
        let networkMonitor = NetworkMonitorStub(connection: false, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function)
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 0.1)
        networkMonitor.flipConnectionStubbedStatusAndSimulateNotification()
        
        wait(for: [exp], timeout: 0.2)
    }
    
    func testAsyncOperationExecutedWithNoConnectionAvailableButResumedInTimeAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: false, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function)
        
        await networkMonitor.flipConnectionStubbedStatus(after: 0.1)
        await sut.perform(withinSeconds: 0.2) {
            exp.fulfill()
        }
        
        await fulfillment(of: [exp], timeout: 0.3)
    }
    
    // If the network is initially not available and becomes available only after the given timeout duration, the given closure is not invoked
    func testAsyncOperationNotExecutedWithNoConnectionAvailableButNotResumedInTime() {
        let networkMonitor = NetworkMonitorStub(connection: false, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function).inverted()
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 0.1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            networkMonitor.flipConnectionStubbedStatusAndSimulateNotification()
        })
        
        wait(for: [exp], timeout: 0.1)
    }
    
    func testAsyncOperationNotExecutedWithNoConnectionAvailableButNotResumedInTimeAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: false, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function).inverted()
        
        await sut.perform(withinSeconds: 0.1) {
            exp.fulfill()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            networkMonitor.flipConnectionStubbedStatusAndSimulateNotification()
        })
        
        await fulfillment(of: [exp], timeout: 0.1)
    }
    
    // If the network is initially not available and is cancelled before network being available in the given timeout, the given closure is not invoked
    func testAsyncOperationNotExecutedWithNoConnectionAvailableAndCancelledBeforeNetworkResumedInTime() {
        let networkMonitor = NetworkMonitorStub(connection: false, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function).inverted()
        
        let task = sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 0.1)
        task.cancel()
        networkMonitor.flipConnectionStubbedStatusAndSimulateNotification()
        
        wait(for: [exp], timeout: 0.2)
    }
    
    func testAsyncOperationNotExecutedWithNoConnectionAvailableAndCancelledBeforeNetworkResumedInTimeAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: false, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function).inverted()
        
        let task = await sut.perform(withinSeconds: 0.1) {
            exp.fulfill()
        }
        task.cancel()
        networkMonitor.flipConnectionStubbedStatusAndSimulateNotification()
        
        await fulfillment(of: [exp], timeout: 0.1)
    }
    
    // If the network is initially available, the given closure is invoked even if the task is cancelled
    func testAsyncOperationExecutedWithConnectionAvailableAndTaskCancelled() {
        let networkMonitor = NetworkMonitorStub(connection: true, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function)
        
        sut.performNetworkOperation(using: {
            exp.fulfill()
        }, withinSeconds: 3)
        .cancel()
        
        wait(for: [exp], timeout: 0.1)
    }
    
    func testAsyncOperationExecutedWithConnectionAvailableAndTaskCancelledAsync() async {
        let networkMonitor = NetworkMonitorStub(connection: true, notificationCenter: notificationCenter)
        let sut = NetworkOperationPerformer(networkMonitor: networkMonitor, notificationCenter: notificationCenter)
        let exp = expectation(description: #function)
        
        await sut.perform(withinSeconds: 3) {
            exp.fulfill()
        }.cancel()
        
        await fulfillment(of: [exp], timeout: 0.1)
    }
}

private extension AsyncIntegrationTests {
    
    final class NetworkMonitorStub: NetworkMonitoring {
        
        private let notificationCenter: NotificationCenter
        private var stubbedHasInternetConnection: Bool
        
        init(connection stubbedHasInternetConnection: Bool, notificationCenter: NotificationCenter) {
            self.stubbedHasInternetConnection = stubbedHasInternetConnection
            self.notificationCenter = notificationCenter
        }
        
        func hasInternetConnection() -> Bool {
            stubbedHasInternetConnection
        }
        
        func hasInternetConnection() async -> Bool {
            stubbedHasInternetConnection
        }
        
        func flipConnectionStubbedStatus(after timeInterval: TimeInterval) async {
            try? await Task.sleep(nanoseconds: UInt64(timeInterval.nanoseconds))
            stubbedHasInternetConnection = true
        }
        
        func flipConnectionStubbedStatusAndSimulateNotification() {
            stubbedHasInternetConnection = true
            notificationCenter.post(
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
