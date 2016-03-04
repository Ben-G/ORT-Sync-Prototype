import Foundation

public struct Sheet: Entity {
    var user: User
    var annotations: [Annotation]
}

public struct User: Entity {
    var name: String
}

public struct Annotation: Entity {
    var user: User
    var positionX: Double
    var positionY: Double
}

public protocol Entity {}
