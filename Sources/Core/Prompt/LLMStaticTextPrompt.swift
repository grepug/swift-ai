public struct LLMStaticTextPrompt<Input: LLMPromptInput>: LLMPrompt {
    public let key: String
    public let input: Input
    public let staticTemplate: String

    public init(key: String, input: Input, staticTemplate: String) {
        self.key = key
        self.input = input
        self.staticTemplate = staticTemplate
    }

    public func template() async throws -> String {
        staticTemplate
    }

    public func transform(chunk: String, accumulatedString: inout String) -> (output: String?, shouldStop: Bool) {
        return (chunk, false)
    }

    public func transform(finalText text: String) -> String {
        text
    }
}
