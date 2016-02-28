import Foundation

public func handleOperations(var state: State, operations: [Operation]) -> (State, [OperationFailure]) {
    var failures: [OperationFailure?] = []

    operations.forEach { operation in
        var failure: OperationFailure?

        switch operation.type {
        case OperationTypes.AddUser.rawValue:
            (state, failure) = addUser(state, operation: operation)
        case OperationTypes.ChangeUsername.rawValue:
            (state, failure) = changeUsername(state, operation: operation)
        default:
            break
        }

        failures.append(failure)
    }

    return (state, failures.flatMap { $0 })
}


private func addUser(var state: State, operation: Operation) -> (State, OperationFailure?) {
    let username = operation.payload["username"] as! String

    if state.users.contains({ $0.name == username }) {
        return (state, OperationFailure(operationIdentifier: operation.identifier))
    }

    let user = User(name: username)
    state.users.append(user)

    return (state, nil)
}

private func changeUsername(var state: State, operation: Operation) -> (State, OperationFailure?) {
    let oldUsername = operation.payload["old_username"] as! String
    let newUsername = operation.payload["new_username"] as! String

    if let index = state.users.indexOf({ $0.name == oldUsername }) {
        state.users[index].name = newUsername
        return (state, nil)
    } else {
        return (state, OperationFailure(operationIdentifier: operation.identifier))
    }
}
