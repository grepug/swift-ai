import Foundation
import SwiftAI
import SwiftAIServer

/// Main entry point for SwiftAI Testing Support
///
/// This module provides mock implementations for all protocols in the SwiftAI ecosystem,
/// making it easy to write unit tests and integration tests.
///
/// Key Features:
/// - Mock implementations for all Server protocols (AIPromptTemplateProvider, AIModelProviderProtocol, etc.)
/// - Mock implementations for Core protocols (AIModel, AILLMCompletion, etc.)
/// - Mock implementations for Workflow protocols (AIWorkflow, AIStreamWorkflow)
/// - Testing utilities for common test scenarios
/// - Assertion helpers for async operations
///
/// Usage:
/// ```swift
/// import SwiftAITestingSupport
///
/// let mockClient = TestingUtilities.createMockCompletionClient(
///     templates: ["test": "Hello {{name}}!"],
///     models: ["test": MockAIModel(name: "test-model")]
/// )
/// ```
public enum SwiftAITestingSupport {
    /// Version of the testing support module
    public static let version = "1.0.0"

    /// Quick setup for common test scenarios
    public static func quickSetup() -> (
        client: AICompletionClient<MockAIHTTPClient, MockAICompletionClientEventHandler>,
        templateProvider: MockAIPromptTemplateProvider,
        modelProvider: MockAIModelProvider,
        eventHandler: MockAICompletionClientEventHandler
    ) {
        let templateProvider = MockAIPromptTemplateProvider()
        let modelProvider = MockAIModelProvider()
        let eventHandler = MockAICompletionClientEventHandler()

        // Set up some default values
        templateProvider.setTemplate("Test template: {{input}}", forKey: "test")
        modelProvider.setDefaultModel(MockAIModel(name: "default-test-model"))

        let client = TestingUtilities.createMockCompletionClient()

        return (client, templateProvider, modelProvider, eventHandler)
    }
}
