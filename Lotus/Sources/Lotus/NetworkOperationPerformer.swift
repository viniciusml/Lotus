
import Foundation
import Network

public protocol CancellableTask {
    var operation: (() -> Void)? { get }
    
    func cancel()
}

public class NetworkOperationPerformer {
    public typealias TimerAction = (TimeInterval, Bool, (@escaping @Sendable (Timer) -> Void)) -> Timer
    
    private final class NetworkTask: CancellableTask {
        private(set) var operation: (() -> Void)?
        
        init(operation: (() -> Void)?) {
            self.operation = operation
        }
        
        func cancel() {
            operation = nil
        }
    }
    
    private let networkMonitor: NetworkMonitoring
    private let notificationCenter: NotificationCenter
    private let timerAction: TimerAction
    
    private var timer: Timer?
    private var currentTask: CancellableTask?
    
    public init(networkMonitor: NetworkMonitoring,
                notificationCenter: NotificationCenter = .default,
                timerAction: @escaping TimerAction = Timer.scheduledTimer) {
        self.networkMonitor = networkMonitor
        self.notificationCenter = notificationCenter
        self.timerAction = timerAction
    }
    
    /// Attempts to perform a network operation using the given `closure`, within the given `timeoutDuration`.
    /// If the network is not accessible within the given `timeoutDuration`, the operation is not performed.
    @discardableResult
    public func performNetworkOperation(using closure: @escaping () -> Void, withinSeconds timeoutDuration: TimeInterval) -> CancellableTask {
        let task = NetworkTask(operation: closure)
        self.currentTask = task
        if self.networkMonitor.hasInternetConnection() {
            closure()
        } else {
            tryPerformingNetworkOperation(withinSeconds: timeoutDuration)
        }
        return task
    }
    
    @discardableResult
    public func perform(withinSeconds timeoutDuration: TimeInterval, operation: @escaping () async -> ()) async -> CancellableTask {
        return await Task {
            
            self.performNetworkOperation(using: {
                Task {
                    await operation()
                }
            }, withinSeconds: timeoutDuration)
        }.value
    }
    
    private func tryPerformingNetworkOperation(withinSeconds timeoutDuration: TimeInterval) {
        notificationCenter.addObserver(
            self,
            selector: #selector(networkStatusDidChange(_:)), name: .networkStatusDidChange,
            object: nil
        )
        self.timer = timerAction(timeoutDuration, false) { [weak self] _ in
            guard let self else { return }
            self.currentTask = nil
            self.timer = nil
            self.notificationCenter.removeObserver(self)
        }
    }
    
    @objc func networkStatusDidChange(_ notification: Notification) {
        guard let connected = notification.userInfo?["connected"] as? Bool,
              connected,
              let closure = currentTask?.operation else { return }
        closure()
    }
}

private class NetworkMonitor: NetworkMonitoring {
    
    private let monitor = NWPathMonitor()
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { _ in
            NotificationCenter.default.post(name: .networkStatusDidChange, object: nil, userInfo: ["connected": self.hasInternetConnection()])
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
    
    public func hasInternetConnection() -> Bool {
        return monitor.currentPath.status == .satisfied
    }
}

private extension Notification.Name {
    static let networkStatusDidChange = Notification.Name("NetworkStatusDidChange")
}
