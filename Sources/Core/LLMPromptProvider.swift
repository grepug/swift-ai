import Foundation

public typealias AnyCodable = Sendable & Codable

public protocol LLMPromptProvider: Sendable {
    associatedtype Params: Sendable = AnyCodable
    associatedtype Key: Hashable & Sendable

    func validate(key: Key, params: Params) -> Bool
    func prompt(key: Key, params: Params) async throws -> String
}

public enum LLMPromptProviderError: Error {
    case invalidPromptParams
}
