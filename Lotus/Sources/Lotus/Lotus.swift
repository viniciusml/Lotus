
import Foundation
import Network

public class NetworkOperationPerformer {
    
    private let networkMonitor: NetworkMonitoring
    private var timer: Timer?
    private var closure: (() -> Void)?
    
    public init(networkMonitor: NetworkMonitoring) {
        self.networkMonitor = networkMonitor
    }
    
    /// Attempts to perform a network operation using the given `closure`, within the given `timeoutDuration`.
    /// If the network is not accessible within the given `timeoutDuration`, the operation is not performed.
    public func performNetworkOperation(using closure: @escaping () -> Void, withinSeconds timeoutDuration: TimeInterval) {
        self.closure = closure
        if self.networkMonitor.hasInternetConnection() {
            closure()
        } else {
            tryPerformingNetworkOperation(withinSeconds: timeoutDuration)
        }
    }
    
    private func tryPerformingNetworkOperation(withinSeconds timeoutDuration: TimeInterval) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusDidChange(_:)), name: .networkStatusDidChange,
            object: nil
        )
        self.timer = Timer.scheduledTimer(withTimeInterval: timeoutDuration, repeats: false) { _ in
            self.closure = nil
            self.timer = nil
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    @objc func networkStatusDidChange(_ notification: Notification) {
        guard let connected = notification.userInfo?["connected"] as? Bool, connected, let closure else { return }
        closure()
    }
}

public protocol NetworkMonitoring {
    func hasInternetConnection() -> Bool
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
