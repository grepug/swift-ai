import Foundation
import SwiftAI
import SwiftAIServer

/// Mock implementation of AIHTTPClient for testing purposes
public final class MockAIHTTPClient: AIHTTPClient, @unchecked Sendable {
    public let prompt: String
    public let timeout: TimeInterval
    public let model: any AIModel
    public let stream: Bool

    // Mock response configuration
    public var mockResponses: [AIHTTPResponseChunk] = []
    public var shouldThrowError: Bool = false
    public var errorToThrow: Error?
    public var responseDelay: TimeInterval = 0

    // Track method calls for verification
    public static var initCallCount = 0
    public var requestCallCount = 0

    public required init(prompt: String, model: any AIModel, stream: Bool, timeout: TimeInterval) {
        self.prompt = prompt
        self.model = model
        self.stream = stream
        self.timeout = timeout
        Self.initCallCount += 1
    }

    public func request() async throws(AIHTTPClientError) -> AsyncThrowingStream<AIHTTPResponseChunk, any Error> {
        requestCallCount += 1

        if shouldThrowError {
            if let error = errorToThrow as? AIHTTPClientError {
                throw error
            } else {
                throw AIHTTPClientError(error: errorToThrow ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
            }
        }

        return AsyncThrowingStream { continuation in
            Task {
                if responseDelay > 0 {
                    try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
                }

                for response in mockResponses {
                    continuation.yield(response)
                }

                continuation.finish()
            }
        }
    }

    // Convenience methods for testing
    public func addMockResponse(_ content: String, finishReason: AIHTTPResponseChunk.FinishReason? = nil, promptTokens: Int = 0, completionTokens: Int = 0) {
        let chunk = AIHTTPResponseChunk(
            content: content,
            reasoningContent: nil,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            finishReason: finishReason
        )
        mockResponses.append(chunk)
    }

    public func setMockResponses(_ responses: [AIHTTPResponseChunk]) {
        mockResponses = responses
    }

    public func reset() {
        mockResponses.removeAll()
        shouldThrowError = false
        errorToThrow = nil
        responseDelay = 0
        requestCallCount = 0
    }

    public static func resetGlobalState() {
        initCallCount = 0
    }
}
