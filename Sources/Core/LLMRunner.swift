import Foundation

public enum LLMRunnerError: Error {
    case generateTextNothingReturned
}

final public class LLMRunner<PromptProvider: LLMPromptProvider, Client: LLMHTTPClient>: Sendable {
    let promptProvider: PromptProvider
    let modelProvider: LLMModelProvider

    public init(models: [any LLMModel], promptProvider: PromptProvider, client: Client.Type) {
        self.modelProvider = LLMModelProvider(models: models)
        self.promptProvider = promptProvider
    }

    public func generateText(key: PromptProvider.Key, params: PromptProvider.Params) async throws -> String {
        let prompt = try await promptProvider.prompt(key: key, params: params)
        let model = await currentModel
        let client = Client(prompt: prompt, model: model, stream: false)
        let stream = try await client.request()

        for try await item in stream {
            try await client.shutdown()
            return item
        }

        try await client.shutdown()
        throw LLMRunnerError.generateTextNothingReturned
    }

    public func streamText(key: PromptProvider.Key, params: PromptProvider.Params) async -> AsyncThrowingStream<String, Error> {
        let model = await currentModel
        let (stream, continuation) = AsyncThrowingStream<String, Error>.makeStream()

        do {
            let prompt = try await promptProvider.prompt(key: key, params: params)
            let client = Client(prompt: prompt, model: model, stream: true)
            let stream = try await client.request()

            Task {
                do {
                    for try await item in stream {
                        continuation.yield(item)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }

                try? await client.shutdown()
            }
        } catch {
            continuation.finish(throwing: error)
        }

        return stream
    }
}

extension LLMRunner {
    fileprivate var currentModel: any LLMModel {
        get async {
            await modelProvider.getModel()
        }
    }
}
