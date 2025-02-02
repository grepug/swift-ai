import Foundation

public protocol LLMPromptProvider: Sendable {
    associatedtype Params: Sendable & Codable
    associatedtype Key: Hashable & Sendable

    func validate(key: Key, params: Params) -> Bool
    func prompt(key: Key, params: Params) async throws -> String
}

public enum LLMPromptProviderError: Error {
    case invalidPromptParams
}
