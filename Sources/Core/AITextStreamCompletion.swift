public struct AITextStreamCompletionOutput: AITaskOutput {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

public protocol AITextStreamCompletion: AIStreamTask {
}

extension AITextStreamCompletion where Output == AITextStreamCompletionOutput, StreamChunk == AITextStreamCompletionOutput {
    public func assembleOutput(chunks: [StreamChunk]) -> Output {
        Output(text: chunks.map(\.text).joined())
    }
}
