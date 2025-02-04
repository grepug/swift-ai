import Foundation

public enum LLMRunnerError: Error {
    case generateTextNothingReturned
}

final public class LLMRunner<Client: LLMHTTPClient>: Sendable {
    let modelProvider: LLMModelProvider

    public init(models: [any LLMModel], client: Client.Type) {
        self.modelProvider = LLMModelProvider(models: models)
    }

    public func generate<P: LLMPrompt>(prompt: P) async throws -> P.Output {
        let promptString = try await prompt.makePromptString()
        let model = await currentModel
        let client = Client(prompt: promptString, model: model, stream: false)
        let stream = try await client.request()

        do {
            for try await item in stream {
                try await client.shutdown()
                return prompt.transform(finalText: item)
            }

            throw LLMRunnerError.generateTextNothingReturned
        } catch {
            try await client.shutdown()
            throw error
        }
    }

    public func stream<P: LLMPrompt>(prompt: P) async -> AsyncThrowingStream<P.Output, Error> {
        let model = await currentModel
        let (stream, continuation) = AsyncThrowingStream<P.Output, Error>.makeStream()

        do {
            let promptString = try await prompt.makePromptString()
            let client = Client(prompt: promptString, model: model, stream: true)
            let stream = try await client.request()

            Task {
                do {
                    var accumulatedString = ""

                    for try await item in stream {
                        let (output, shouldStop) = prompt.transform(chunk: item, accumulatedString: &accumulatedString)

                        if let output {
                            continuation.yield(output)
                        }

                        if shouldStop {
                            break
                        }
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
