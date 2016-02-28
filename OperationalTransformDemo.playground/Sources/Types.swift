import Foundation

public struct Sheet {
    var user: User
    var annotations: [Annotation]
}

public struct User {
    var name: String
}

public struct Annotation {
    var user: User
    var positionX: Double
    var positionY: Double
}