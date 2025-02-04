import Foundation

public protocol LLMPrompt: Sendable {
    associatedtype Input: LLMPromptInput
    associatedtype Result: Codable & Sendable
    associatedtype Key

    var key: Key { get }
    var input: Input { get }
    var template: String { get }
}
