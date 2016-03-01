import Foundation

public enum OperationTypes: String {
    case AddUser
    case ChangeUsername
}

public struct Operation {
    public let type: String
    public let identifier: String = NSUUID().UUIDString
    public let payload: [String: Any]

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
    public let failedOperation: Operation
}

public struct State {
    var users: [User] = []
    var sheets: [Sheet] = []
    // Clients that have permission to see/modify users
    var userAdmins: [Client] = []

    public init() {}
}

public class Backend: CustomStringConvertible {
    private var state: State
    private (set) public var commitLog: [(Operation, OperationMetadata)] = []

    public var description: String { return "\(state)" }

    public init(state: State) {
        self.state = state
    }

    public func addAdmin(client: Client) {
        if !(self.state.userAdmins.contains { $0.identifier == client.identifier }) {
            self.state.userAdmins.append(client)
        }
    }

    /// Retrieve the operations a client might have missed
    public func operationsSince(commitLogPosition: Int, client: Client) -> (operations: [Operation], newHead: Int) {
        let missedCommits = self.commitLog[commitLogPosition..<self.commitLog.endIndex].map { $0.0 }.filter { operation in

            if operation.type == OperationTypes.AddUser.rawValue || operation.type == OperationTypes.ChangeUsername.rawValue {
                return self.state.userAdmins.contains { $0.identifier == client.identifier }
            }
            return true
        }

        return (missedCommits, self.commitLog.endIndex)
    }

    public func commitOperations(operationCommits: [(Operation, OperationMetadata)]) -> [OperationFailure] {
        var failures: [OperationFailure]
        let operations = operationCommits.map { $0.0 }
        (self.state, failures) = handleOperations(self.state, operations: operations)

        // Get list of successfully commited operations
        let successfullCommits = operationCommits.filter { operation, metadata in
            !failures.contains { operation.identifier == $0.failedOperation.identifier }
        }

        self.commitLog.appendContentsOf(successfullCommits)

        return failures
    }
}
