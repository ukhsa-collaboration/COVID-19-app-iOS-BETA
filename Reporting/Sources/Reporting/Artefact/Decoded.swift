import Foundation

enum Decoded<Wrapped: Decodable>: Decodable {
    case some(Wrapped)
    case error(Error)
    
    init(from decoder: Decoder) throws {
        do {
            self = .some(try Wrapped(from: decoder))
        } catch {
            self = .error(error)
        }
    }
    
}
