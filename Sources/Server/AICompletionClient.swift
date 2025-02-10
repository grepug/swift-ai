import Foundation
import SwiftAI

public enum AIClientError: Error {
    case generateTextNothingReturned
}

public protocol AICompletionClientKind: Sendable {
    associatedtype Client: AIHTTPClient

    init(models: [any AIModel], client: Client.Type, log: (@Sendable (String) -> Void)?)

    func generate<T: AILLMCompletion>(completion: T) async throws -> T.Output
    func stream<T: AIStreamCompletion>(completion: T) async -> AsyncThrowingStream<T.Output, Error>
}

public struct AICompletionClient<Client: AIHTTPClient>: AICompletionClientKind {
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

            throw AIClientError.generateTextNothingReturned
        } catch {
            try await client.shutdown()
            throw error
        }
    }

    public func stream<T: AIStreamCompletion>(completion: T) async -> AsyncThrowingStream<T.Output, Error> {
        let model = await currentModel
        let (stream, continuation) = AsyncThrowingStream<T.Output, Error>.makeStream()

        do {
            let promptString = try await completion.makePromptString()
            let client = Client(prompt: promptString, model: model, stream: true)
            let stream = try await client.request()

            var hasMetStartSymbol = completion.startSymbol == nil

            Task {
                do {
                    var accumulatedString = ""

                    for try await string in stream {
                        var string = string

                        if !hasMetStartSymbol, let startSymbol = completion.startSymbol {
                            hasMetStartSymbol = string.contains(startSymbol)
                            string = string.replacingOccurrences(of: completion.startSymbol ?? "", with: "")
                        }

                        if let endSymbol = completion.endSymbol, hasMetStartSymbol {
                            if string.contains(endSymbol) {
                                string = string.replacingOccurrences(of: endSymbol, with: "")
                                break
                            }
                        }

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

extension AICompletionClient {
    fileprivate var currentModel: any AIModel {
        get async {
            await modelProvider.getModel()
        }
    }
}
