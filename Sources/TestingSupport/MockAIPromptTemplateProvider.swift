import Foundation
import SwiftAI
import SwiftAIServer

/// Mock implementation of AIPromptTemplateProvider for testing purposes
public final class MockAIPromptTemplateProvider: AIPromptTemplateProvider, @unchecked Sendable {
    public var templates: [String: String] = [:]
    public var shouldThrowError: Bool = false
    public var errorToThrow: AIPromptTemplateProviderError?

    // Track method calls for verification
    public var promptTemplateCallCount = 0
    public var lastRequestedKey: String?

    public init() {}

    public func promptTemplate(forKey key: String) async throws(AIPromptTemplateProviderError) -> String? {
        promptTemplateCallCount += 1
        lastRequestedKey = key

        if shouldThrowError {
            throw errorToThrow ?? .promptTemplateNotFound(key: key)
        }

        return templates[key]
    }

    // Convenience methods for testing
    public func setTemplate(_ template: String, forKey key: String) {
        templates[key] = template
    }

    public func reset() {
        templates.removeAll()
        shouldThrowError = false
        errorToThrow = nil
        promptTemplateCallCount = 0
        lastRequestedKey = nil
    }
}
