import Foundation

public protocol AIModel: Sendable {
    var name: String { get }
    var baseURL: URL { get }
    var apiKey: String { get }

    var thinkingDisabled: Bool? { get }
}

extension AIModel {
    public var thinkingDisabled: Bool? { nil }
}
