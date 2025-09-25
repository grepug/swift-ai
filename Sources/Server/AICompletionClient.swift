import ConcurrencyUtils
import ErrorKit
import Foundation
import Logging
import SwiftAI

public protocol AIPromptTemplateProvider: Sendable {
    func promptTemplate(forKey key: String) async throws(AIPromptTemplateProviderError) -> String?
}

public protocol AIModelProviderProtocol: Sendable {
    func model(forKey key: String) async throws -> any AIModel
}

public enum AICompletionClientEventStopReason: Codable, Equatable {
    case llmFinishReasonStop
    case streamFinished
    case cancelled
    case error(String)
}

public protocol AICompletionClientEventHandler: Sendable {
    func setParams(
        _ params: String,
    )

    func onChunkReceived(
        chunk: AIHTTPResponseChunk,
        forKey key: String,
    )

    func onStop(
        reason: AICompletionClientEventStopReason,
        forKey key: String,
    )
}

public protocol AICompletionClientKind: Sendable {
    associatedtype Client: AIHTTPClient
    associatedtype EventHandler: AICompletionClientEventHandler

    init(
        client: Client.Type,
        modelProvider: any AIModelProviderProtocol,
        promptTemplateProviders: [any AIPromptTemplateProvider],
        eventHandler: EventHandler,
        logger: Logger?
    )

    func generate<T: AILLMCompletion>(completion: T) async throws(AIClientError) -> T.Output
    func stream<T: AIStreamCompletion>(completion: T) async throws(AIClientError) -> AsyncThrowingStream<T.Output, Error>
}

public struct AICompletionClient<Client: AIHTTPClient, EventHandler: AICompletionClientEventHandler>: AICompletionClientKind {
    let modelProvider: any AIModelProviderProtocol
    let promptTemplateProviders: [any AIPromptTemplateProvider]
    let eventHandler: EventHandler
    let logger: Logger?

    public init(
        client: Client.Type,
        modelProvider: any AIModelProviderProtocol,
        promptTemplateProviders: [any AIPromptTemplateProvider],
        eventHandler: EventHandler,
        logger: Logger? = nil
    ) {
        self.modelProvider = modelProvider
        self.promptTemplateProviders = promptTemplateProviders
        self.eventHandler = eventHandler
        self.logger = logger
    }

    public func generate<T: AILLMCompletion>(completion: T) async throws(AIClientError) -> T.Output {
        let stream = try await makeRequestStream(completion: completion, stream: false)

        eventHandler.setParams(
            String(data: try! JSONEncoder().encode(completion.input.normalized), encoding: .utf8) ?? "",
        )

        do {
            for try await chunk in stream {
                // Notify the event handler about the received chunk
                eventHandler.onChunkReceived(
                    chunk: chunk,
                    forKey: completion.path,
                )

                if case .stop = chunk.finishReason {
                    // Handle completion
                    eventHandler.onStop(
                        reason: .llmFinishReasonStop,
                        forKey: completion.path,
                    )
                }

                var string = chunk.content

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

                logger?.debug("ai llm completion generate", metadata: ["string": "\(string)"])

                return completion.makeOutput(string: string)
            }
        } catch {
            assertionFailure("Error occurred while generating: \(error) for key: \(completion.path)")

            eventHandler.onStop(
                reason: .error(error.localizedDescription),
                forKey: completion.path,
            )

            throw .streamError(error)
        }

        throw .generateTextNothingReturned
    }

    public func stream<T: AIStreamCompletion>(completion: T) async throws(AIClientError) -> AsyncThrowingStream<T.Output, Error> {
        let stream = try await makeRequestStream(completion: completion, stream: true)

        eventHandler.setParams(
            String(data: try! JSONEncoder().encode(completion.input.normalized), encoding: .utf8) ?? "",
        )

        return .makeCancellable { continuation in
            do {
                var hasMetStartSymbol = completion.startSymbol == nil
                var cache = completion.initialCache()
                var hasYield = false
                var isStopped = false
                var isBroken = false
                var latestOutput: T.Output?

                for try await chunk in stream {
                    // Notify the event handler about the received chunk
                    eventHandler.onChunkReceived(
                        chunk: chunk,
                        forKey: completion.path,
                    )

                    // Handle completion
                    if case .stop = chunk.finishReason {
                        eventHandler.onStop(
                            reason: .llmFinishReasonStop,
                            forKey: completion.path,
                        )
                    }

                    guard !isStopped && !isBroken else {
                        continue
                    }

                    var string = chunk.content

                    if !hasMetStartSymbol, let startSymbol = completion.startSymbol {
                        hasMetStartSymbol = string.contains(startSymbol)
                        string = string.replacingOccurrences(of: completion.startSymbol ?? "", with: "")
                    }

                    if let endSymbol = completion.endSymbol, hasMetStartSymbol {
                        if string.contains(endSymbol) {
                            string = string.replacingOccurrences(of: endSymbol, with: "")
                            isBroken = true
                            continue
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
                        continue
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

                eventHandler.onStop(
                    reason: .streamFinished,
                    forKey: completion.path,
                )

                continuation.finish()
            } catch is CancellationError {
                // Handle cancellation
                assertionFailure("Cancellation error occurred")

                eventHandler.onStop(
                    reason: .cancelled,
                    forKey: completion.path,
                )
            } catch {
                eventHandler.onStop(
                    reason: .error(error.localizedDescription),
                    forKey: completion.path,
                )

                logger?.warning("Error occurred while streaming", metadata: ["error": "\(error)"])

                continuation.finish(throwing: error)

                assertionFailure("Error occurred while streaming: \(error)")
            }
        } onError: { error in
            print("@@@ Error occurred while streaming: \(String(describing: error))")
        } onCancel: {
            logger?.warning("ai llm completion stream cancelled", metadata: ["key": "\(completion.path)"])

            eventHandler.onStop(
                reason: .cancelled,
                forKey: completion.path,
            )
        }
    }
}

extension AICompletionClient {
    private func getModel<T: AILLMCompletion>(completion: T) async throws(AIClientError) -> any AIModel {
        do {
            return try await modelProvider.model(forKey: completion.path)
        } catch {
            logger?.warning("Error occurred while fetching model", metadata: ["error": "\(error)", "key": "\(completion.path)"])
            assertionFailure("Model not found")
            throw AIClientError.modelNotFound(key: completion.path)
        }
    }

    private func makeRequestStream<T: AILLMCompletion>(completion: T, stream: Bool) async throws(AIClientError) -> AsyncThrowingStream<AIHTTPResponseChunk, any Error> {
        var template: String?
        let promptString: String

        for provider in promptTemplateProviders {
            do {
                template = try await provider.promptTemplate(forKey: completion.path)
            } catch {
                logger?.critical(
                    "Error occurred while fetching prompt template",
                    metadata: [
                        "error": "\(error)",
                        "key": "\(completion.path)",
                    ])
                throw .promptTemplateError(error)
            }

            if template != nil {
                break
            }
        }

        guard let template else {
            logger?.critical("Prompt template not found", metadata: ["key": "\(completion.path)"])

            throw .promptTemplateNotFound(key: completion.path)
        }

        do {
            promptString = try await completion.makePromptString(template: template)
        } catch {
            logger?.warning("Error occurred while making prompt string", metadata: ["error": "\(error)"])

            throw .makingPromptError(error)
        }

        let model = try await getModel(completion: completion)
        let client = Client(prompt: promptString, model: model, stream: stream, timeout: completion.timeout)

        do {
            return try await client.request()
        } catch {
            logger?.warning("Error occurred while making request", metadata: ["error": "\(error)"])
            throw .requestError(error)
        }
    }
}
