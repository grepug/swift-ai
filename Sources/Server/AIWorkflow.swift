import Logging
import SwiftAI

// an AITask can be a workflow, it contains multiple tasks to run
public protocol AIWorkflow: AITask {
    associatedtype Tools: Sendable = Void

    func makeOutput(environment: AIWorkflowEnvironment, tools: Tools) async throws -> Output
}

public struct AIWorkflowEnvironment {
    var client: any AICompletionClientKind
    var logger: Logger
}

public protocol AIStreamWorkflow: AIStreamTask {
    associatedtype Tools: Sendable = Void

    func streamChunk(environment: AIWorkflowEnvironment, tools: Tools) -> AsyncThrowingStream<StreamChunk, Error>
}
