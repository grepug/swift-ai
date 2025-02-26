import Foundation
import Logging
import SwiftAI

public protocol AIPromptTemplateProvider: Sendable {
    func promptTemplate(forKey key: String) async throws(AIPromptTemplateProviderError) -> String
}

public protocol AICompletionClientKind: Sendable {
    associatedtype Client: AIHTTPClient
    associatedtype PromptTemplateProvider: AIPromptTemplateProvider

    init(models: [any AIModel], client: Client.Type, promptTemplateProvider: PromptTemplateProvider, logger: Logger?)

    func generate<T: AILLMCompletion>(completion: T) async throws(AIClientError) -> T.Output
    func stream<T: AIStreamCompletion>(completion: T) async throws(AIClientError) -> AsyncThrowingStream<T.Output, Error>
}

public struct AICompletionClient<Client: AIHTTPClient, PromptTemplateProvider: AIPromptTemplateProvider>: AICompletionClientKind {
    let modelProvider: AIModelProvider
    let promptTemplateProvider: PromptTemplateProvider
    let logger: Logger?

    public init(models: [any AIModel], client: Client.Type, promptTemplateProvider: PromptTemplateProvider, logger: Logger? = nil) {
        self.modelProvider = AIModelProvider(models: models)
        self.promptTemplateProvider = promptTemplateProvider
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
        let (newStream, continuation) = AsyncThrowingStream<T.Output, Error>.makeStream()
        let stream = try await makeRequestStream(completion: completion, stream: true)

        Task {
            do {
                var hasMetStartSymbol = completion.startSymbol == nil
                var accumulatedString = ""
                var hasYield = false
                var isStopped = false
                var isBroken = false
                var latestOutput: T.Output?

                for try await string in stream {
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

                    let (output, shouldStop) = completion.makeOutput(chunk: string, accumulatedString: &accumulatedString)

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

                logger?.info("ai llm completion stream", metadata: ["string": "\(accumulatedString)"])

                if !hasYield {
                    print(
                        hasYield,
                        """
                        "No output was yielded, 
                        key: \(completion.key),
                        latestOutput: \(latestOutput),
                        isStopped: \(isStopped), 
                        isBroken: \(isBroken),
                        string: \(accumulatedString)",
                        startSymbol: \(completion.startSymbol ?? "nil"),
                        endSymbol: \(completion.endSymbol ?? "nil"),
                        """
                    )

                    assertionFailure()
                }

                continuation.finish()
            } catch {
                assert(error is AIHTTPClientError)

                continuation.finish(throwing: error)
            }
        }

        return newStream
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
        let template: String
        let promptString: String

        do {
            template = try await promptTemplateProvider.promptTemplate(forKey: completion.key)
        } catch {
            throw .promptTemplateError(error)
        }

        do {
            promptString = try await completion.makePromptString(template: template)

            print("prompt string", promptString)
        } catch {
            throw .makingPromptError(error)
        }

        let model = await getModel(completion: completion)
        let client = Client(prompt: promptString, model: model, stream: stream)

        do {
            return try await client.request()
        } catch {
            throw .requestError(error)
        }
    }
}
