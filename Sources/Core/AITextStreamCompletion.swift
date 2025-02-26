public struct AITextStreamCompletionOutput: AITaskOutput {
    public var text: String

    public init(text: String) {
        self.text = text
    }
}

public protocol AITextStreamCompletion: AIStreamCompletion {
}

extension AITextStreamCompletion where Output == AITextStreamCompletionOutput, StreamChunk == AITextStreamCompletionOutput {
    public func reduce(partialOutput: inout Output, chunk: StreamChunk) {
        partialOutput.text += chunk.text
    }

    public func initialOutput() -> Output {
        Output(text: "")
    }

    public func makeOutput(chunk: String, cache: inout String) -> (output: Output?, shouldStop: Bool) {
        cache += chunk
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
