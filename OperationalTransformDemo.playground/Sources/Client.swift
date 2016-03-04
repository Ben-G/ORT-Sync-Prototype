import Foundation

public class Client {
    let identifier: String
    // Set of server commit logs that this client is aware about
    var serverCommitLogSet: Set<Int> = []
    var serverPermissionIndex: Int = -1

    public var state: State
    var backend: Backend
    var serverState: State {
        didSet {
            (self.state, _) = handleOperations(serverState, operations: self.commitLog.map { $0.0 })
        }
    }

    var commitLog: [(Operation, OperationMetadata)] = []
    var failureLog: [OperationFailure] = []

    public init(identifier: String, state: State, backend: Backend) {
        self.identifier = identifier
        self.state = state
        self.serverState = state
        self.backend = backend
    }

    public func sync() {
        let (missedOperations, syncedCommits, entitiesGained, entitiesLost, serverPermissionIndex) = backend.operationsSince(self.serverCommitLogSet, permissionIndex: self.serverPermissionIndex, client: self)

        print(missedOperations, syncedCommits, entitiesGained, entitiesLost, serverPermissionIndex)

        self.serverPermissionIndex = serverPermissionIndex

        for commit in syncedCommits {
            self.serverCommitLogSet.insert(commit)
        }

        (self.serverState, _) = handleOperations(self.serverState, operations: missedOperations)

        let errors = backend.commitOperations(self.commitLog)

        for error in errors {
            if let index = self.commitLog.indexOf({ $0.0.identifier == error.failedOperation.identifier }) {
                self.commitLog.removeAtIndex(index)
            }
        }

        (self.state, _) = handleOperations(self.serverState, operations: self.commitLog.map { $0.0 })

        self.failureLog.appendContentsOf(errors)

        self.commitLog.removeAll()
    }

    public func performOperations(operations: [Operation]) {
        // apply operations to local state
        (self.state, _) = handleOperations(self.state, operations: operations)

        let commitOperations = operations.map { operation in
            return (operation, OperationMetadata(author: self.identifier, timestamp: NSDate().timeIntervalSince1970))
        }

        self.commitLog.appendContentsOf(commitOperations)
    }
}