
import Foundation
import Network

public class NetworkOperationPerformer: NetworkOperationPerforming {
    public typealias SleepAction = (UInt64) async throws -> Void
    
    private let networkMonitor: NetworkMonitoring
    private let sleepAction: SleepAction
    
    public init(
        networkMonitor: NetworkMonitoring = NetworkMonitor(),
        sleepAction: @escaping SleepAction = Task.sleep(nanoseconds:)
    ) {
        self.networkMonitor = networkMonitor
        self.sleepAction = sleepAction
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
}

public class NetworkMonitor: NetworkMonitoring {
    
    private let monitor = NWPathMonitor()
    
    public init() {}
    
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
            start(queue: DispatchQueue(label: "NetworkMonitor"))
        }
    }
}
