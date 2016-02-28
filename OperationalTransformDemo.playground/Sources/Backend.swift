import Foundation

public enum OperationTypes: String {
    case AddUser
    case ChangeUsername
}

public struct Operation {
    let type: String
    let identifier: String = NSUUID().UUIDString
    let payload: [String: Any]

    public init(type: String, payload: [String: Any]) {
        self.type = type
        self.payload = payload
    }
}

public struct OperationMetadata {
    let author: String
    let timestamp: Double

    public init(author: String, timestamp: Double) {
        self.author = author
        self.timestamp = timestamp
    }
}

public struct OperationFailure {
    let operationIdentifier: String
}

public struct State {
    var users: [User] = []
    var sheets: [Sheet] = []

    public init() {}
}

public class Backend {
    private (set) public var state: State
    private (set) public var commitLog: [(Operation, OperationMetadata)] = []

    public init(state: State) {
        self.state = state
    }

    public func commitOperations(operationCommits: [(Operation, OperationMetadata)]) -> (State, [OperationFailure]) {
        var failures: [OperationFailure]
        let operations = operationCommits.map { $0.0 }
        (self.state, failures) = handleOperations(self.state, operations: operations)

        // Get list of successfully commited operations
        let successfullCommits = operationCommits.filter { operation, metadata in
            !failures.contains { operation.identifier == $0.operationIdentifier }
        }

        self.commitLog.appendContentsOf(successfullCommits)

        return (self.state, failures)
    }
}
