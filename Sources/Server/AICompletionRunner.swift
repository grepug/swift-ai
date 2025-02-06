import Foundation
import SwiftAI

public enum AIRunnerError: Error {
    case generateTextNothingReturned
}

public struct AICompletionRunner<Client: AIHTTPClient>: Sendable {
    let modelProvider: AIModelProvider
    let log: (@Sendable (String) -> Void)?

    public init(models: [any AIModel], client: Client.Type, log: (@Sendable (String) -> Void)? = nil) {
        self.modelProvider = AIModelProvider(models: models)
        self.log = log
    }

    public func generate<T: AILLMCompletion>(completion: T) async throws -> T.Output {
        let promptString = try await completion.makePromptString()
        let model = await currentModel
        let client = Client(prompt: promptString, model: model, stream: false)
        let stream = try await client.request()

        do {
            for try await string in stream {
                try await client.shutdown()
                log?(string)
                return completion.makeOutput(string: string)
            }

            throw AIRunnerError.generateTextNothingReturned
        } catch {
            try await client.shutdown()
            throw error
        }
    }

    public func stream<T: AILLMCompletion>(completion: T) async -> AsyncThrowingStream<T.Output, Error> {
        let model = await currentModel
        let (stream, continuation) = AsyncThrowingStream<T.Output, Error>.makeStream()

        do {
            let promptString = try await completion.makePromptString()
            let client = Client(prompt: promptString, model: model, stream: true)
            let stream = try await client.request()

            Task {
                do {
                    var accumulatedString = ""

                    for try await string in stream {
                        let (output, shouldStop) = completion.makeOutput(chunk: string, accumulatedString: &accumulatedString)

                        if let output {
                            continuation.yield(output)
                        }

                        if shouldStop {
                            break
                        }
                    }

                    log?(accumulatedString)
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

extension AICompletionRunner {
    fileprivate var currentModel: any AIModel {
        get async {
            await modelProvider.getModel()
        }
    }
}
