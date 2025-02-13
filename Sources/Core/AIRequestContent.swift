public struct AIClientRequestContent<T: AITask>: Codable, Sendable {
    public let task: T

    public init(task: T) {
        self.task = task
    }
}

public struct AIServerResponseContent<T: AITaskOutput>: Codable, Sendable {
    public let output: T

    public init(output: T) {
        self.output = output
    }
}

public struct AIServerStreamResponseContent<T: AITaskOutput>: Codable, Sendable {
    public let chunk: T
    public let finished: Bool

    public init(chunk: T, finished: Bool) {
        self.chunk = chunk
        self.finished = finished
    }
}
