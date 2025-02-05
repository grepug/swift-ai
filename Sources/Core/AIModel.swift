import Foundation

public protocol AIModel: Sendable {
    var name: String { get }
    var baseURL: URL { get }
    var apiKey: String { get }
}
