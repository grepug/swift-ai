public struct AIStaticTextCompletion<Input: AITaskInput>: AIStreamCompletion {
    public let key: String
    public let input: Input
    public let staticTemplate: String

    public static var kind: String {
        "static_text"
    }

    public struct Output: AITaskOutput {
        public let text: String
    }

    public typealias StreamChunk = Output

    public init(key: String, input: Input, staticTemplate: String) {
        self.key = key
        self.input = input
        self.staticTemplate = staticTemplate
    }

    public func promptTemplate() async throws -> String {
        staticTemplate
    }

    public func makeOutput(chunk: String, accumulatedString: inout String) -> (output: Output?, shouldStop: Bool) {
        accumulatedString += chunk
        return (Output(text: chunk), false)
    }

    public func makeOutput(string: String) -> Output {
        Output(text: string)
    }

    public func assembleOutput(chunks: [StreamChunk]) -> Output {
        Output(text: chunks.map(\.text).joined())
    }

    public var startSymbol: String? {
        "^^"
    }

    public var endSymbol: String? {
        "$$"
    }

    public init(input: Input) {
        fatalError("This should not be called")
    }
}
