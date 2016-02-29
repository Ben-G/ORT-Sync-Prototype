//: Playground - noun: a place where people can play

import Cocoa

let initialState = State()
var backend = Backend(state: initialState)

/// Frontend:

class Client {
    let identifier: String
    // Pointer to the position in the server commit log that this client is aware about
    var serverCommitLogCount: Int = 0
    var state: State
    var serverState: State {
        didSet {
            (self.state, _) = handleOperations(serverState, operations: self.commitLog.map { $0.0 })
        }
    }

    var commitLog: [(Operation, OperationMetadata)] = []
    var failureLog: [OperationFailure] = []

    init(identifier: String, state: State) {
        self.identifier = identifier
        self.state = state
        self.serverState = state
    }

    func sync() {
        let (missedOperations, newHead) = backend.operationsSince(self.serverCommitLogCount)
        self.serverCommitLogCount = newHead
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

    func performOperations(operations: [Operation]) {
        // apply operations to local state
        (self.state, _) = handleOperations(self.state, operations: operations)

        let commitOperations = operations.map { operation in
            return (operation, OperationMetadata(author: self.identifier, timestamp: NSDate().timeIntervalSince1970))
        }
        
        self.commitLog.appendContentsOf(commitOperations)
    }
}

let client1 = Client(identifier: "Client1", state: initialState)
let client2 = Client(identifier: "Client2", state: initialState)

client1.performOperations([createUserOperation("Benji")])
client1.sync()

client2.sync()
client2.performOperations([changeUsernameOperation("Benji", newUsername: "Mary")])
client2.sync()

client1.performOperations([changeUsernameOperation("Benji", newUsername: "Sarah")])
client1.sync()

client1.performOperations([changeUsernameOperation("Mary", newUsername: "Benji")])
client1.sync()

for (index, commit) in backend.commitLog.enumerate() {
    print("[\(index)]: \(commit)")
    print("")
}

print("")

client1.sync()
client2.sync()

print("C1: \(client1.state)")
print("C2: \(client2.state)")
print("BE: \(backend)")

