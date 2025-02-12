public struct AITextStreamCompletionOutput: AITaskOutput {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

public protocol AITextStreamCompletion: AIStreamCompletion {
}

extension AITextStreamCompletion where Output == AITextStreamCompletionOutput, StreamChunk == AITextStreamCompletionOutput {
    public func assembleOutput(chunks: [StreamChunk]) -> Output {
        Output(text: chunks.map(\.text).joined())
    }

    public func makeOutput(chunk: String, accumulatedString: inout String) -> (output: Output?, shouldStop: Bool) {
        accumulatedString += chunk
        return (Output(text: chunk), false)
    }

    public func makeOutput(string: String) -> Output {
        Output(text: string)
    }

    public var startSymbol: String? {
        "^^"
    }

    public var endSymbol: String? {
        "$$"
    }
}
