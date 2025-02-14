import Logging
import SwiftAI

// an AITask can be a workflow, it contains multiple tasks to run
public protocol AIWorkflow: AITask {
    associatedtype Tools: Sendable = Void

    func makeOutput(environment: AIWorkflowEnvironment, tools: Tools) async throws -> Output
}

public struct AIWorkflowEnvironment {
    public let client: any AICompletionClientKind
    public let logger: Logger

    public init(client: any AICompletionClientKind, logger: Logger) {
        self.client = client
        self.logger = logger
    }
}

public protocol AIStreamWorkflow: AIStreamTask {
    associatedtype Tools: Sendable = Void

    func streamChunk(environment: AIWorkflowEnvironment, tools: Tools) -> AsyncThrowingStream<StreamChunk, Error>
}
