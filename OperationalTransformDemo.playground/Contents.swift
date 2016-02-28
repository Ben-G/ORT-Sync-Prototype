//: Playground - noun: a place where people can play

import Cocoa

var backend = Backend(state: State())

/// Frontend:

class Client {
    let identifier: String
    var state: State
    var commitLog: [(Operation, OperationMetadata)] = []
    var failureLog: [OperationFailure] = []

    init(identifier: String, state: State) {
        self.identifier = identifier
        self.state = state
    }

    func sync() {
        let (newState, errors) = backend.commitOperations(self.commitLog)
        self.state = newState
        self.failureLog.appendContentsOf(errors)

        self.commitLog.removeAll()
    }

    func performOperations(operations: [Operation]) {
        let commitOperations = operations.map { operation in
            return (operation, OperationMetadata(author: self.identifier, timestamp: NSDate().timeIntervalSince1970))
        }
        
        self.commitLog.appendContentsOf(commitOperations)
    }
}

let client1 = Client(identifier: "Client1", state: backend.state)
let client2 = Client(identifier: "Client2", state: backend.state)

let op1 = createUserOperation("Benji")
client1.performOperations([op1])
let rename = changeUsernameOperation("Benji", newUsername: "Mike")
client2.performOperations([op1, rename])

client1.sync()
client2.sync()
client1.sync()

for (index, commit) in backend.commitLog.enumerate() {
    print("[\(index)]: \(commit)")
    print("")
}

print("")

print(client1.state)
print(client2.state)
print(backend.state)

