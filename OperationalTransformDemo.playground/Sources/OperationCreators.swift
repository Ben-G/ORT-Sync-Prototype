import Foundation

public func createUserOperation(username: String) -> Operation {
    return Operation(
        type: OperationTypes.AddUser.rawValue,
        payload: ["username": username]
    )
}

public func changeUsernameOperation(oldUsername: String, newUsername: String) -> Operation {
    return Operation(
        type: OperationTypes.ChangeUsername.rawValue,
        payload: ["old_username": oldUsername, "new_username": newUsername]
    )
}
