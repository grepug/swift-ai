import Foundation
import SwiftAI

/// Mock implementation of AIModel for testing purposes
public struct MockAIModel: AIModel {
    public let name: String
    public let baseURL: URL
    public let apiKey: String
    public let thinkingDisabled: Bool?

    public init(
        name: String = "mock-model",
        baseURL: URL = URL(string: "https://api.mock.com")!,
        apiKey: String = "mock-api-key",
        thinkingDisabled: Bool? = nil
    ) {
        self.name = name
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.thinkingDisabled = thinkingDisabled
    }
}

/// Builder for creating mock models with different configurations
public struct MockAIModelBuilder {
    private var name: String = "mock-model"
    private var baseURL: URL = URL(string: "https://api.mock.com")!
    private var apiKey: String = "mock-api-key"
    private var thinkingDisabled: Bool? = nil

    public init() {}

    public func withName(_ name: String) -> MockAIModelBuilder {
        var builder = self
        builder.name = name
        return builder
    }

    public func withBaseURL(_ baseURL: URL) -> MockAIModelBuilder {
        var builder = self
        builder.baseURL = baseURL
        return builder
    }

    public func withAPIKey(_ apiKey: String) -> MockAIModelBuilder {
        var builder = self
        builder.apiKey = apiKey
        return builder
    }

    public func withThinkingDisabled(_ disabled: Bool?) -> MockAIModelBuilder {
        var builder = self
        builder.thinkingDisabled = disabled
        return builder
    }

    public func build() -> MockAIModel {
        MockAIModel(
            name: name,
            baseURL: baseURL,
            apiKey: apiKey,
            thinkingDisabled: thinkingDisabled
        )
    }
}

// Convenience extension for easy model creation
extension MockAIModel {
    public static func builder() -> MockAIModelBuilder {
        MockAIModelBuilder()
    }
}
