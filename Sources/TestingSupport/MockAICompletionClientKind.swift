import Foundation
import Logging
import SwiftAI
import SwiftAIServer

/// Mock implementation of AICompletionClientKind for testing purposes
public final class MockAICompletionClientKind: AICompletionClientKind, @unchecked Sendable {
    public typealias Client = MockAIHTTPClient
    public typealias EventHandler = MockAICompletionClientEventHandler

    // Mock configuration
    public var mockGenerateResults: [String: Any] = [:]
    public var mockStreamResults: [String: [Any]] = [:]
    public var shouldThrowError: Bool = false
    public var errorToThrow: AIClientError?

    // Track method calls for verification
    public var initCallCount = 0
    public var generateCallCount = 0
    public var streamCallCount = 0
    public var lastGenerateCompletion: (any AILLMCompletion)?
    public var lastStreamCompletion: (any AIStreamCompletion)?

    // Dependencies (stored for verification)
    public let clientType: Client.Type
    public let modelProvider: any AIModelProviderProtocol
    public let promptTemplateProviders: [any AIPromptTemplateProvider]
    public let eventHandler: EventHandler
    public let logger: Logger?

    public required init(
        client: Client.Type,
        modelProvider: any AIModelProviderProtocol,
        promptTemplateProviders: [any AIPromptTemplateProvider],
        eventHandler: EventHandler,
        logger: Logger? = nil
    ) {
        self.clientType = client
        self.modelProvider = modelProvider
        self.promptTemplateProviders = promptTemplateProviders
        self.eventHandler = eventHandler
        self.logger = logger
        self.initCallCount += 1
    }

    public func generate<T: AILLMCompletion>(completion: T) async throws(AIClientError) -> T.Output {
        generateCallCount += 1
        lastGenerateCompletion = completion

        if shouldThrowError {
            throw errorToThrow ?? .generateTextNothingReturned
        }

        // Try to return a configured mock result for this completion type
        if let mockResult = mockGenerateResults[completion.path] as? T.Output {
            return mockResult
        }

        // If no specific mock result is configured, try to create a default one
        if T.Output.self == String.self {
            return "Mock generate result for \(completion.path)" as! T.Output
        }

        // For other types, we'll need to use the completion's makeOutput method
        return completion.makeOutput(string: "Mock generate result for \(completion.path)")
    }

    public func stream<T: AIStreamCompletion>(completion: T) async throws(AIClientError) -> AsyncThrowingStream<T.Output, Error> {
        streamCallCount += 1
        lastStreamCompletion = completion

        if shouldThrowError {
            throw errorToThrow ?? .streamError(NSError(domain: "MockStreamError", code: 500))
        }

        return AsyncThrowingStream { continuation in
            Task {
                // Get configured mock results or use defaults
                let chunks = mockStreamResults[completion.path] as? [T.Output] ?? []

                if chunks.isEmpty {
                    // Generate default chunks if none configured
                    let defaultChunks = ["Mock", " stream", " chunk", " for ", completion.path]
                    var cache = completion.initialCache()

                    for chunk in defaultChunks {
                        let (output, shouldStop) = completion.makeOutput(chunk: chunk, cache: &cache)
                        if let output = output {
                            continuation.yield(output)
                        }
                        if shouldStop {
                            break
                        }
                    }
                } else {
                    // Use configured chunks
                    for chunk in chunks {
                        continuation.yield(chunk)
                    }
                }

                continuation.finish()
            }
        }
    }

    // Convenience methods for testing
    public func setMockGenerateResult<T>(_ result: T, forKey key: String) {
        mockGenerateResults[key] = result
    }

    public func setMockStreamResults<T>(_ results: [T], forKey key: String) {
        mockStreamResults[key] = results
    }

    public func reset() {
        mockGenerateResults.removeAll()
        mockStreamResults.removeAll()
        shouldThrowError = false
        errorToThrow = nil
        generateCallCount = 0
        streamCallCount = 0
        lastGenerateCompletion = nil
        lastStreamCompletion = nil
    }
}

/// Builder for creating MockAICompletionClientKind with different configurations
public struct MockAICompletionClientKindBuilder {
    private var modelProvider: (any AIModelProviderProtocol)?
    private var promptTemplateProviders: [any AIPromptTemplateProvider] = []
    private var eventHandler: MockAICompletionClientEventHandler?
    private var logger: Logger?

    public init() {}

    public func withModelProvider(_ provider: any AIModelProviderProtocol) -> MockAICompletionClientKindBuilder {
        var builder = self
        builder.modelProvider = provider
        return builder
    }

    public func withPromptTemplateProvider(_ provider: any AIPromptTemplateProvider) -> MockAICompletionClientKindBuilder {
        var builder = self
        builder.promptTemplateProviders.append(provider)
        return builder
    }

    public func withPromptTemplateProviders(_ providers: [any AIPromptTemplateProvider]) -> MockAICompletionClientKindBuilder {
        var builder = self
        builder.promptTemplateProviders = providers
        return builder
    }

    public func withEventHandler(_ handler: MockAICompletionClientEventHandler) -> MockAICompletionClientKindBuilder {
        var builder = self
        builder.eventHandler = handler
        return builder
    }

    public func withLogger(_ logger: Logger) -> MockAICompletionClientKindBuilder {
        var builder = self
        builder.logger = logger
        return builder
    }

    public func build() -> MockAICompletionClientKind {
        let modelProvider = self.modelProvider ?? MockAIModelProvider()
        let eventHandler = self.eventHandler ?? MockAICompletionClientEventHandler()

        return MockAICompletionClientKind(
            client: MockAIHTTPClient.self,
            modelProvider: modelProvider,
            promptTemplateProviders: promptTemplateProviders,
            eventHandler: eventHandler,
            logger: logger
        )
    }
}

// Convenience extension for easy mock creation
extension MockAICompletionClientKind {
    public static func builder() -> MockAICompletionClientKindBuilder {
        MockAICompletionClientKindBuilder()
    }
}
