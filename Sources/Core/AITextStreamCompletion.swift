public struct AITextStreamCompletionOutput: AITaskOutput {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

public protocol AITextStreamCompletion: AIStreamTask where Output == AITextStreamCompletionOutput, StreamChunk == AITextStreamCompletionOutput {
}

extension AITextStreamCompletion {
    public func assembleOutput(chunks: [StreamChunk]) -> Output {
        Output(text: chunks.map(\.text).joined())
    }
}
