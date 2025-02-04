public struct LLMTextPrompt<Key: Sendable, Input: LLMPromptInput>: LLMPrompt {
    public typealias Result = String

    public let key: Key
    public let input: Input
    public let template: String

    public init(key: Key, input: Input, template: String) {
        self.key = key
        self.input = input
        self.template = template
    }
}
