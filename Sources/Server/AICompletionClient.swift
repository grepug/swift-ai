import ConcurrencyUtils
import Foundation
import Logging
import SwiftAI

public protocol AIPromptTemplateProvider: Sendable {
    func promptTemplate(forKey key: String) async throws(AIPromptTemplateProviderError) -> String?
}

public protocol AICompletionClientKind: Sendable {
    associatedtype Client: AIHTTPClient

    init(models: [any AIModel], client: Client.Type, promptTemplateProviders: [any AIPromptTemplateProvider], logger: Logger?)

    func generate<T: AILLMCompletion>(completion: T) async throws(AIClientError) -> T.Output
    func stream<T: AIStreamCompletion>(completion: T) async throws(AIClientError) -> AsyncThrowingStream<T.Output, Error>
}

public struct AICompletionClient<Client: AIHTTPClient>: AICompletionClientKind {
    let modelProvider: AIModelProvider
    let promptTemplateProviders: [any AIPromptTemplateProvider]
    let logger: Logger?

    public init(models: [any AIModel], client: Client.Type, promptTemplateProviders: [any AIPromptTemplateProvider], logger: Logger? = nil) {
        self.modelProvider = AIModelProvider(models: models)
        self.promptTemplateProviders = promptTemplateProviders
        self.logger = logger
    }

    public func generate<T: AILLMCompletion>(completion: T) async throws(AIClientError) -> T.Output {
        let stream = try await makeRequestStream(completion: completion, stream: false)

        do {
            for try await string in stream {
                var string = string

                if let startSymbol = completion.startSymbol {
                    // remove anything before the start symbol(included)
                    let escapedStartSymbol = NSRegularExpression.escapedPattern(for: startSymbol)
                    string = string.replacingOccurrences(of: ".*\(escapedStartSymbol)", with: "", options: .regularExpression)
                }

                if let endSymbol = completion.endSymbol {
                    // remove anything after the end symbol(included)
                    let escapedEndSymbol = NSRegularExpression.escapedPattern(for: endSymbol)
                    string = string.replacingOccurrences(of: "\(escapedEndSymbol).*", with: "", options: .regularExpression)
                }

                logger?.info("ai llm completion generate", metadata: ["string": "\(string)"])

                return completion.makeOutput(string: string)
            }
        } catch {
            throw .streamError(error)
        }

        throw .generateTextNothingReturned
    }

    public func stream<T: AIStreamCompletion>(completion: T) async throws(AIClientError) -> AsyncThrowingStream<T.Output, Error> {
        let stream = try await makeRequestStream(completion: completion, stream: true)

        return AsyncThrowingStream<T.Output, Error>.makeCancellable { continuation in
            do {
                var hasMetStartSymbol = completion.startSymbol == nil
                var cache = completion.initialCache()
                var hasYield = false
                var isStopped = false
                var isBroken = false
                var latestOutput: T.Output?

                for try await string in stream {
                    try Task.checkCancellation()
                    var string = string

                    if !hasMetStartSymbol, let startSymbol = completion.startSymbol {
                        hasMetStartSymbol = string.contains(startSymbol)
                        string = string.replacingOccurrences(of: completion.startSymbol ?? "", with: "")
                    }

                    if let endSymbol = completion.endSymbol, hasMetStartSymbol {
                        if string.contains(endSymbol) {
                            string = string.replacingOccurrences(of: endSymbol, with: "")
                            isBroken = true
                            break
                        }
                    }

                    let (output, shouldStop) = completion.makeOutput(chunk: string, cache: &cache)

                    latestOutput = output

                    if let output {
                        hasYield = true
                        continuation.yield(output)
                    }

                    if shouldStop {
                        isStopped = true
                        break
                    }
                }

                logger?.info("ai llm completion stream", metadata: ["cache": "\(cache)"])

                if !hasYield {
                    print(
                        hasYield,
                        """
                        "No output was yielded, 
                        key: \(completion.path),
                        latestOutput: \(latestOutput.debugDescription),
                        isStopped: \(isStopped), 
                        isBroken: \(isBroken),
                        cache: \(cache)",
                        startSymbol: \(completion.startSymbol ?? "nil"),
                        endSymbol: \(completion.endSymbol ?? "nil"),
                        """
                    )
                }

                continuation.finish()
            } catch is CancellationError {
                continuation.finish(throwing: CancellationError())
            } catch {
                assert(error is AIHTTPClientError)
                continuation.finish(throwing: error)
            }
        } onCancel: {
            logger?.warning("ai llm completion stream cancelled", metadata: ["key": "\(completion.path)"])
        }
    }
}

extension AICompletionClient {
    private func getModel<T: AILLMCompletion>(completion: T) async -> any AIModel {
        let result = await modelProvider.getModel(preferredModel: completion.preferredModel)

        if result.usingPreferred {
            logger?.info(
                "using preferred model",
                metadata: [
                    "model": "\(result.model.name)"
                ]
            )

        }

        print("using preferred model", result.model.name, "apiKey: ", result.model.apiKey.suffix(6), "using preferred:", result.usingPreferred)

        return result.model
    }

    private func makeRequestStream<T: AILLMCompletion>(completion: T, stream: Bool) async throws(AIClientError) -> AsyncThrowingStream<String, any Error> {
        var template: String?
        let promptString: String

        for provider in promptTemplateProviders {
            do {
                template = try await provider.promptTemplate(forKey: completion.path)
            } catch {
                throw .promptTemplateError(error)
            }

            if template != nil {
                break
            }
        }

        guard let template else {
            throw .promptTemplateNotFound(key: completion.path)
        }

        do {
            promptString = try await completion.makePromptString(template: template)
        } catch {
            throw .makingPromptError(error)
        }

        let model = await getModel(completion: completion)
        let client = Client(prompt: promptString, model: model, stream: stream, timeout: completion.timeout)

        do {
            return try await client.request()
        } catch {
            throw .requestError(error)
        }
    }
}
