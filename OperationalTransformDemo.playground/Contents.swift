//: Playground - noun: a place where people can play

import Cocoa

let initialState = State()
var backend = Backend(state: initialState)

let client1 = Client(identifier: "Client1", state: initialState, backend: backend)
let client2 = Client(identifier: "Client2", state: initialState, backend: backend)

backend.addAdmin(client1)

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


