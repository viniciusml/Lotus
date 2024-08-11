# Lotus

`Lotus` is a framework to perform network operations. It observes the network reachability, and if the connection is not present, tries to execute the operation once the network is back available if it happens within a given timeout. 

-----

The code is made testable by allowing all dependencies to be injected and by utilizing interfaces (protocols) rather than concrete implementations.
For the `NetworkOperationPerformer`, there are two methods:

An `async` version:
```swift
    /// Performs an async network operation using the given `operation`, within the given `timeoutDuration`.
    /// If the network is not accessible within the given `timeoutDuration`, the operation is not performed.
    /// - Parameters:
    ///   - operation: the operation to be invoked
    ///   - timeoutDuration: the specified time interval for performing a re-try operation.
    /// - Returns: `CancellableTask` - a task that can be cancelled
    @discardableResult
    func perform(withinSeconds timeoutDuration: TimeInterval, operation: @escaping () async -> ()) async -> CancellableTask
```

And a closure-based version, to support backwards compatibility:
```swift
    /// Performs a network operation using the given `closure`, within the given `timeoutDuration`.
    /// If the network is not accessible within the given `timeoutDuration`, the operation is not performed.
    /// - Parameters:
    ///   - closure: the operation to be invoked
    ///   - timeoutDuration: the specified time interval for performing a re-try operation.
    /// - Returns: `CancellableTask` - a task that can be cancelled
    @discardableResult
    func performNetworkOperation(using closure: @escaping () -> Void, withinSeconds timeoutDuration: TimeInterval) -> CancellableTask
```

The main interface takes into consideration a few directives:
- If no network is available, the given closure is not invoked
- If the network is initially available, the given closure is invoked
- If the network is initially not available but becomes available within the given timeout duration, the given closure is invoked
- If the network is initially not available and becomes available only after the given timeout duration, the given closure is not invoked
- **If the network is initially not available and is cancelled before network being available in the given timeout, the given closure is not invoked**
- **If the network is initially available, the given closure is invoked even if the task is cancelled**

### A few areas of improvement

- [ ] Currently, it's only possible to handle one task at a time, which means that if for the same instance of `NetworkOperationPerformer`, there are two calls to `perform` methods, the first task will be overwritten.
- [ ] The operation performer relies on notifications, which means that two instances might receive conflicting messages.
- [x] There is the risk of causing a memory leak when triggering the timer, by not explicitly making `self weak`. **Fixed in https://github.com/viniciusml/Lotus/commit/e14029ba11465d8a0e64422c1d8a3f356679d874**
