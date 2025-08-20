import Foundation
import Logging
import SwiftAI
import SwiftAIClient
import SwiftAIServer

/// Utilities for creating common test configurations and setups
public struct TestingUtilities {

    /// Creates a mock AICompletionClient with all mocked dependencies
    public static func createMockCompletionClient(
        templates: [String: String] = [:],
        models: [String: any AIModel] = [:],
        defaultModel: (any AIModel)? = MockAIModel()
    ) -> AICompletionClient<MockAIHTTPClient, MockAICompletionClientEventHandler> {

        let templateProvider = MockAIPromptTemplateProvider()
        templateProvider.templates = templates

        let modelProvider = MockAIModelProvider()
        modelProvider.models = models
        if let defaultModel = defaultModel {
            modelProvider.setDefaultModel(defaultModel)
        }

        let eventHandler = MockAICompletionClientEventHandler()
        let logger = Logger(label: "test-logger")

        return AICompletionClient(
            client: MockAIHTTPClient.self,
            modelProvider: modelProvider,
            promptTemplateProviders: [templateProvider],
            eventHandler: eventHandler,
            logger: logger
        )
    }

    /// Creates a mock AICompletionClientKind for testing
    public static func createMockCompletionClientKind(
        templates: [String: String] = [:],
        models: [String: any AIModel] = [:],
        defaultModel: (any AIModel)? = MockAIModel()
    ) -> MockAICompletionClientKind {

        let templateProvider = MockAIPromptTemplateProvider()
        templateProvider.templates = templates

        let modelProvider = MockAIModelProvider()
        modelProvider.models = models
        if let defaultModel = defaultModel {
            modelProvider.setDefaultModel(defaultModel)
        }

        return MockAICompletionClientKind.builder()
            .withModelProvider(modelProvider)
            .withPromptTemplateProvider(templateProvider)
            .withLogger(Logger(label: "test-logger"))
            .build()
    }

    /// Creates a mock AIWorkflowEnvironment for testing workflows
    public static func createMockWorkflowEnvironment(
        client: (any AICompletionClientKind)? = nil
    ) -> AIWorkflowEnvironment {
        let mockClient = client ?? createMockCompletionClient()
        let logger = Logger(label: "test-workflow-logger")

        return AIWorkflowEnvironment(
            client: mockClient,
            logger: logger
        )
    }

    /// Creates a set of common mock HTTP response chunks
    public static func createMockHTTPResponseChunks(
        contents: [String] = ["Hello", " ", "World", "!"],
        includeStopChunk: Bool = true
    ) -> [AIHTTPResponseChunk] {
        var chunks: [AIHTTPResponseChunk] = []

        for (index, content) in contents.enumerated() {
            let isLast = index == contents.count - 1
            let finishReason: AIHTTPResponseChunk.FinishReason? = (isLast && includeStopChunk) ? .stop : nil

            chunks.append(
                AIHTTPResponseChunk(
                    content: content,
                    reasoningContent: nil,
                    promptTokens: index == 0 ? 10 : 0,  // Only count prompt tokens in first chunk
                    completionTokens: 1,
                    finishReason: finishReason
                ))
        }

        return chunks
    }

    /// Creates a mock logger that captures log messages for testing
    public static func createMockLogger() -> Logger {
        var logger = Logger(label: "test-logger")
        logger.logLevel = .trace
        return logger
    }

    /// Helper to wait for async operations in tests
    public static func waitFor<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError()
            }

            guard let result = try await group.next() else {
                throw TimeoutError()
            }

            group.cancelAll()
            return result
        }
    }

    /// Helper to collect stream results for testing
    public static func collectStreamResults<T>(
        from stream: AsyncThrowingStream<T, Error>,
        maxResults: Int = 100
    ) async throws -> [T] {
        var results: [T] = []

        for try await result in stream {
            results.append(result)
            if results.count >= maxResults {
                break
            }
        }

        return results
    }
}

/// Custom timeout error for testing utilities
public struct TimeoutError: LocalizedError {
    public let errorDescription: String? = "Operation timed out"

    public init() {}
}

/// Assertion helpers for testing
public struct TestAssertions {

    /// Assert that two async sequences produce the same elements
    public static func assertAsyncSequencesEqual<S1: AsyncSequence, S2: AsyncSequence>(
        _ sequence1: S1,
        _ sequence2: S2,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws where S1.Element: Equatable, S1.Element == S2.Element {

        var iter1 = sequence1.makeAsyncIterator()
        var iter2 = sequence2.makeAsyncIterator()

        var index = 0
        while true {
            let element1 = try await iter1.next()
            let element2 = try await iter2.next()

            if element1 == nil && element2 == nil {
                break  // Both sequences ended
            }

            guard element1 == element2 else {
                fatalError("Sequences differ at index \(index): \(String(describing: element1)) != \(String(describing: element2))", file: file, line: line)
            }

            index += 1
        }
    }

    /// Assert that an async operation completes within a timeout
    public static func assertCompletesWithin<T>(
        timeout: TimeInterval,
        operation: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> T {
        do {
            return try await TestingUtilities.waitFor(timeout: timeout, operation: operation)
        } catch is TimeoutError {
            fatalError("Operation did not complete within \(timeout) seconds", file: file, line: line)
        } catch {
            throw error
        }
    }
}
