import Foundation
import Logging
import SwiftAI
import SwiftAIServer

/// Mock implementation of AIWorkflow for testing purposes
public struct MockAIWorkflow: AIWorkflow {
    public typealias Input = MockInput
    public typealias Output = String

    public static let kind: String = "mock-workflow"

    public let input: MockInput
    public let mockOutput: String
    public let shouldThrowError: Bool
    public let errorMessage: String?

    // Track method calls for verification
    public static var makeOutputCallCount = 0
    public static var lastEnvironment: AIWorkflowEnvironment?

    public init(
        input: MockInput = MockInput(),
        mockOutput: String = "Mock workflow output",
        shouldThrowError: Bool = false,
        errorMessage: String? = nil
    ) {
        self.input = input
        self.mockOutput = mockOutput
        self.shouldThrowError = shouldThrowError
        self.errorMessage = errorMessage
    }

    public init(input: MockInput) {
        self.input = input
        self.mockOutput = "Mock workflow output"
        self.shouldThrowError = false
        self.errorMessage = nil
    }

    public func makeOutput(environment: AIWorkflowEnvironment, tools: Void) async throws -> String {
        Self.makeOutputCallCount += 1
        Self.lastEnvironment = environment

        if shouldThrowError {
            throw NSError(domain: "MockWorkflowError", code: 500, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? "Mock workflow error"])
        }

        return mockOutput
    }

    public static func resetState() {
        makeOutputCallCount = 0
        lastEnvironment = nil
    }
}

/// Mock implementation of AIStreamWorkflow for testing purposes
public struct MockAIStreamWorkflow: AIStreamWorkflow {
    public typealias Input = MockInput
    public typealias Output = String
    public typealias StreamChunk = String

    public static let kind: String = "mock-stream-workflow"

    public let input: MockInput
    public let mockChunks: [String]
    public let shouldThrowError: Bool
    public let errorMessage: String?

    // Track method calls for verification
    public static var streamChunkCallCount = 0
    public static var lastEnvironment: AIWorkflowEnvironment?

    public init(
        input: MockInput = MockInput(),
        mockChunks: [String] = ["Chunk1", "Chunk2", "Chunk3"],
        shouldThrowError: Bool = false,
        errorMessage: String? = nil
    ) {
        self.input = input
        self.mockChunks = mockChunks
        self.shouldThrowError = shouldThrowError
        self.errorMessage = errorMessage
    }

    public init(input: MockInput) {
        self.input = input
        self.mockChunks = ["Chunk1", "Chunk2", "Chunk3"]
        self.shouldThrowError = false
        self.errorMessage = nil
    }

    public func streamChunk(environment: AIWorkflowEnvironment, tools: Void) -> AsyncThrowingStream<String, Error> {
        Self.streamChunkCallCount += 1
        Self.lastEnvironment = environment

        return AsyncThrowingStream { continuation in
            Task {
                if shouldThrowError {
                    continuation.finish(throwing: NSError(domain: "MockStreamWorkflowError", code: 500, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? "Mock stream workflow error"]))
                    return
                }

                for chunk in mockChunks {
                    continuation.yield(chunk)
                }

                continuation.finish()
            }
        }
    }

    public func initialOutput() -> String {
        return ""
    }

    public func reduce(partialOutput: inout String, chunk: String) {
        partialOutput += chunk
    }

    public static func resetState() {
        streamChunkCallCount = 0
        lastEnvironment = nil
    }
}
