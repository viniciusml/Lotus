
import Foundation
import Network

public class NetworkOperationPerformer: NetworkOperationPerforming {
    public typealias TimerAction = (TimeInterval, Bool, (@escaping @Sendable (Timer) -> Void)) -> Timer
    public typealias SleepAction = (UInt64) async throws -> Void
    
    private final class NetworkTask: CancellableClosureBasedTask {
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
    private let sleepAction: SleepAction
    
    private var timer: Timer?
    private var currentTask: CancellableClosureBasedTask?
    
    public init(networkMonitor: NetworkMonitoring = NetworkMonitor(),
                sleepAction: @escaping SleepAction = Task.sleep(nanoseconds:),
                notificationCenter: NotificationCenter = .default,
                timerAction: @escaping TimerAction = Timer.scheduledTimer) {
        self.networkMonitor = networkMonitor
        self.sleepAction = sleepAction
        self.notificationCenter = notificationCenter
        self.timerAction = timerAction
    }
    
    /// Attempts to perform a network operation using the given `closure`, within the given `timeoutDuration`.
    /// If the network is not accessible within the given `timeoutDuration`, the operation is not performed.
    @discardableResult
    public func performNetworkOperation(using closure: @escaping () -> Void, withinSeconds timeoutDuration: TimeInterval) -> CancellableClosureBasedTask {
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
    public func perform(withinSeconds timeoutDuration: TimeInterval, operation: @Sendable @escaping () async -> ()) async -> Cancellable {
        async let hasInternetConnection = await networkMonitor.hasInternetConnection()
        
        if await hasInternetConnection {
            return Task(operation: operation)
        } else {
            
            if !timeoutDuration.isZero {
                try? await sleepAction(UInt64(timeoutDuration.nanoseconds))
                return await perform(withinSeconds: .zero, operation: operation)
            }
        }
        
        return Task {}
    }
    
    private func shouldBreakCircuit(_ timeoutDuration: TimeInterval) async -> Bool {
        timeoutDuration.isZero
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

public class NetworkMonitor: NetworkMonitoring {
    
    private let monitor = NWPathMonitor()
    
    public init() {
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
    
    public func hasInternetConnection() async -> Bool {
        await monitor.paths.contains(where: { $0.status == .satisfied })
    }
}

private extension NWPathMonitor {
    
    var paths: AsyncStream<NWPath> {
        AsyncStream { continuation in
            pathUpdateHandler = { path in
                continuation.yield(path)
            }
            continuation.onTermination = { [weak self] _ in
                self?.cancel()
            }
        }
    }
}

private extension Notification.Name {
    static let networkStatusDidChange = Notification.Name("NetworkStatusDidChange")
}
