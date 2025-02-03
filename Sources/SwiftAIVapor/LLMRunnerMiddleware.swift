import Dependencies
import SwiftAI
import Vapor

public struct LLMRunnerMiddleware<PromptProvider: LLMPromptProvider>: AsyncMiddleware {
    let models: [any LLMModel]
    let promptProvider: PromptProvider
    let setupStorage: (Request, LLMRunner<PromptProvider, LLMClient>) -> Void

    public init(
        models: [any LLMModel],
        promptProvider: PromptProvider,
        setupStorage: @escaping (Request, LLMRunner<PromptProvider, LLMClient>) -> Void
    ) {
        self.models = models
        self.promptProvider = promptProvider
        self.setupStorage = setupStorage
    }

    public func respond(
        to request: Request,
        chainingTo responder: AsyncResponder
    ) async throws -> Response {
        let runner = LLMRunner(
            models: models,
            promptProvider: promptProvider,
            client: LLMClient.self
        )

        setupStorage(request, runner)

        return try await withDependencies {
            $0.request = request
        } operation: {
            try await responder.respond(to: request)
        }
    }
}
