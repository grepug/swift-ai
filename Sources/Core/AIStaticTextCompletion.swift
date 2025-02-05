public struct AIStaticTextCompletion<Input: AITaskInput>: AILLMCompletion {
    public let key: String
    public let input: Input
    public let staticTemplate: String

    public typealias Output = String

    public init(key: String, input: Input, staticTemplate: String) {
        self.key = key
        self.input = input
        self.staticTemplate = staticTemplate
    }

    public func promptTemplate() async throws -> String {
        staticTemplate
    }

    public func makeOutput(chunk: String, accumulatedString: inout String) -> (output: String?, shouldStop: Bool) {
        return (chunk, false)
    }

    public func makeOutput(string: String) -> String {
        string
    }
}
