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

public enum PermissionChange {
    case Admin
    case NotAdmin
}

public class Backend: CustomStringConvertible {
    private var state: State
    private (set) public var commitLog: [(Operation, OperationMetadata, Int)] = []
    // Maps Client Identifier to Permission Change
    private (set) public var permissionChangeLog: [String: [PermissionChange]] = [:]

    public var description: String { return "\(state)" }

    public init(state: State) {
        self.state = state
    }

    public func addAdmin(client: Client) {
        if !(self.state.userAdmins.contains { $0.identifier == client.identifier }) {
            self.state.userAdmins.append(client)
        }
    }

    public func removeAdmin(client: Client) {
        if let index = (self.state.userAdmins.indexOf { $0.identifier == client.identifier }) {
            self.state.userAdmins.removeAtIndex(index)
        }
    }

    /// Retrieve the operations a client might have missed
    public func operationsSince(commitLogPosition: Set<Int>, permissionIndex: Int, client: Client) -> (operations: [Operation], newHead: Set<Int>, entitiesGained: [User], entitiesLost: [User], newPermissionIndex: Int) {
        let missedCommitMetadata = self.commitLog[0..<self.commitLog.endIndex]
            .filter { _, _, index in
                return !commitLogPosition.contains(index)
            }.filter { operation, _, _ in

            if operation.type == OperationTypes.AddUser.rawValue || operation.type == OperationTypes.ChangeUsername.rawValue {
                return self.state.userAdmins.contains { $0.identifier == client.identifier }
            }
            return true
        }

        let commitIdentifers = Set(missedCommitMetadata.map { $0.2 })
        let missedCommits = missedCommitMetadata.map { $0.0 }

        var entitiesGained: [User] = []
        var entitiesLost: [User] = []

        if permissionIndex == -1 {
            // setup default permission
            self.permissionChangeLog[client.identifier] = [.NotAdmin]
        } else {
            // check for transition
            guard let oldPermissionState = self.permissionChangeLog[client.identifier]?[permissionIndex],
                let newPermissionState = self.permissionChangeLog[client.identifier]?.last else { return ([],[],[],[],0) }

            switch (oldPermissionState, newPermissionState) {
            case (.Admin, .NotAdmin):
                entitiesGained = self.state.users
            case (.NotAdmin, .Admin):
                entitiesLost = self.state.users
            default:
                break
            }
        }

        return (missedCommits, commitIdentifers, entitiesGained, entitiesLost, self.permissionChangeLog[client.identifier]!.count)
    }

    public func commitOperations(operationCommits: [(Operation, OperationMetadata)]) -> [OperationFailure] {
        var failures: [OperationFailure]
        let operations = operationCommits.map { $0.0 }
        (self.state, failures) = handleOperations(self.state, operations: operations)

        // Get list of successfully commited operations
        let successfullCommits = operationCommits.filter { operation, metadata in
            !failures.contains { operation.identifier == $0.failedOperation.identifier }
        }

        for commit in successfullCommits {
            self.commitLog.append((commit.0, commit.1, self.commitLog.count))
        }

        return failures
    }
}
