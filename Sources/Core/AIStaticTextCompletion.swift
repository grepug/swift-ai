public struct AIStaticTextCompletion<Input: AITaskInput>: AIStreamCompletion {
    public let key: String
    public let input: Input
    public let staticTemplate: String

    public static var kind: String {
        "static_text"
    }

    public typealias StreamChunk = String
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

    public func assembleOutput(chunks: [String]) -> String {
        chunks.joined()
    }

    public init(input: Input) {
        fatalError("This should not be called")
    }
}
