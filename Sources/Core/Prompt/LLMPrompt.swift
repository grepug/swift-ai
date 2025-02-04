import Foundation

public typealias LLMPromptOutput = Codable & Sendable

public protocol LLMPrompt: Sendable {
    associatedtype Key
    associatedtype Input: LLMPromptInput
    associatedtype Output: LLMPromptOutput

    var key: Key { get }
    var input: Input { get }

    func template() async throws -> String

    func transform(finalText text: String) -> Output
    func transform(chunk: String, accumulatedString: inout String) -> (output: Output?, shouldStop: Bool)
}

extension LLMPrompt {
    public func makePromptString() async throws -> String {
        var prompt = try await template()

        for (key, value) in input.normalized {
            prompt = prompt.replacingOccurrences(of: "{{\(key)}}", with: value)
        }

        // validate if there is no {{}}
        if prompt.contains("{{") {
            throw LLMPromptProviderError.invalidPromptParams
        }

        return prompt
    }
}
