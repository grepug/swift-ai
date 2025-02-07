import SwiftAI

// an AITask can be a workflow, it contains multiple tasks to run
public protocol AIWorkflow: AITask {
    associatedtype Tools: Sendable = Void

    func makeOutput(client: any AICompletionClientKind, tools: Tools) async throws -> Output
}

public protocol AIStreamWorkflow: AIStreamTask {
    associatedtype Tools: Sendable = Void

    func streamChunk(client: any AICompletionClientKind, tools: Tools) -> AsyncThrowingStream<StreamChunk, Error>
}
