import Foundation
import SwiftAI
import SwiftAIServer

/// Mock implementation of AIModelProviderProtocol for testing purposes
public final class MockAIModelProvider: AIModelProviderProtocol, @unchecked Sendable {
    public var models: [String: any AIModel] = [:]
    public var defaultModel: (any AIModel)?
    public var shouldThrowError: Bool = false
    public var errorToThrow: Error?

    // Track method calls for verification
    public var modelCallCount = 0
    public var lastRequestedKey: String?

    public init() {}

    public func model(forKey key: String) async throws -> any AIModel {
        modelCallCount += 1
        lastRequestedKey = key

        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model not found for key: \(key)"])
        }

        if let model = models[key] {
            return model
        }

        if let defaultModel = defaultModel {
            return defaultModel
        }

        throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Model not found for key: \(key)"])
    }

    // Convenience methods for testing
    public func setModel(_ model: any AIModel, forKey key: String) {
        models[key] = model
    }

    public func setDefaultModel(_ model: any AIModel) {
        defaultModel = model
    }

    public func reset() {
        models.removeAll()
        defaultModel = nil
        shouldThrowError = false
        errorToThrow = nil
        modelCallCount = 0
        lastRequestedKey = nil
    }
}
