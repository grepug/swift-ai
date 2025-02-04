import Foundation

public protocol LLMPromptProvider: Sendable {
    func makePromptString(_ prompt: any LLMPrompt) async throws -> String
}

public enum LLMPromptProviderError: Error {
    case invalidPromptParams
}
