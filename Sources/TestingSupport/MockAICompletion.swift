import Foundation
import SwiftAI

/// Mock implementation of AILLMCompletion for testing purposes
public struct MockAILLMCompletion: AILLMCompletion {
    public typealias Input = MockInput
    public typealias Output = String

    public static let kind: String = "mock-completion"

    public let input: MockInput
    public let timeout: TimeInterval
    public let startSymbol: String?
    public let endSymbol: String?

    // Mock configuration
    public let mockOutput: String

    public init(
        input: MockInput = MockInput(),
        timeout: TimeInterval = 60,
        startSymbol: String? = nil,
        endSymbol: String? = nil,
        mockOutput: String = "Mock completion output"
    ) {
        self.input = input
        self.timeout = timeout
        self.startSymbol = startSymbol
        self.endSymbol = endSymbol
        self.mockOutput = mockOutput
    }

    public init(input: MockInput) {
        self.input = input
        self.timeout = 60
        self.startSymbol = nil
        self.endSymbol = nil
        self.mockOutput = "Mock completion output"
    }

    public func makeOutput(string: String) -> String {
        return mockOutput
    }

    public var preferredModel: (any AIModel)? {
        nil
    }
}

/// Mock implementation of AIStreamCompletion for testing purposes
public struct MockAIStreamCompletion: AIStreamCompletion {
    public typealias Input = MockInput
    public typealias Output = String
    public typealias Cache = String

    public static let kind: String = "mock-stream-completion"

    public let input: MockInput
    public let timeout: TimeInterval
    public let startSymbol: String?
    public let endSymbol: String?

    // Mock configuration
    public let mockOutput: String
    public let mockChunks: [String]

    public init(
        input: MockInput = MockInput(),
        timeout: TimeInterval = 60,
        startSymbol: String? = nil,
        endSymbol: String? = nil,
        mockOutput: String = "Mock stream completion output",
        mockChunks: [String] = ["Mock", " chunk", " output"]
    ) {
        self.input = input
        self.timeout = timeout
        self.startSymbol = startSymbol
        self.endSymbol = endSymbol
        self.mockOutput = mockOutput
        self.mockChunks = mockChunks
    }

    public init(input: MockInput) {
        self.input = input
        self.timeout = 60
        self.startSymbol = nil
        self.endSymbol = nil
        self.mockOutput = "Mock stream completion output"
        self.mockChunks = ["Mock", " chunk", " output"]
    }

    public func makeOutput(string: String) -> String {
        return mockOutput
    }

    public func makeOutput(chunk: String, cache: inout String) -> (output: String?, shouldStop: Bool) {
        cache += chunk
        return (chunk, chunk.contains("STOP"))
    }

    public func initialCache() -> String {
        return ""
    }

    public func initialOutput() -> String {
        return ""
    }

    public func reduce(partialOutput: inout String, chunk: String) {
        partialOutput += chunk
    }

    public var preferredModel: (any AIModel)? {
        nil
    }
}

/// Mock input for testing completions
public struct MockInput: AITaskInput {
    public let text: String
    public let parameter: String

    public init(text: String = "Test input", parameter: String = "test-param") {
        self.text = text
        self.parameter = parameter
    }

    public var normalized: AICompletionNormalizedInput {
        return [
            "text": text,
            "parameter": parameter,
        ]
    }
}
