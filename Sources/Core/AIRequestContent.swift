public struct AIClientRequestContent<T: AITask>: Codable, Sendable {
    public let task: T

    public init(task: T) {
        self.task = task
    }
}

public struct AIServerResponseContent<T: AITask>: Codable, Sendable {
    public let output: T.Output
    public let finished: Bool

    public init(output: T.Output, finished: Bool) {
        self.output = output
        self.finished = finished
    }
}

public struct AIServerStreamResponseContent<T: AIStreamTask>: Codable, Sendable {
    public let chunk: T.StreamChunk
    public let finished: Bool

    public init(chunk: T.StreamChunk, finished: Bool) {
        self.chunk = chunk
        self.finished = finished
    }
}
