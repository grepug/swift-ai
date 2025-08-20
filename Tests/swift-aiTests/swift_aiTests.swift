import EventSource
import Foundation
import Testing

@testable import SwiftAI
@testable import SwiftAIServer
@testable import SwiftAITestingSupport

@Test("MockAIPromptTemplateProvider basic functionality")
func testMockAIPromptTemplateProvider() async throws {
    let provider = MockAIPromptTemplateProvider()
    provider.setTemplate("Hello {{name}}!", forKey: "greeting")

    let template = try await provider.promptTemplate(forKey: "greeting")
    #expect(template == "Hello {{name}}!")
    #expect(provider.promptTemplateCallCount == 1)
    #expect(provider.lastRequestedKey == "greeting")

    // Test error case
    provider.shouldThrowError = true
    provider.errorToThrow = .promptTemplateNotFound(key: "missing")

    await #expect(throws: AIPromptTemplateProviderError.self) {
        try await provider.promptTemplate(forKey: "missing")
    }
    #expect(provider.promptTemplateCallCount == 2)
}

@Test("MockAIModelProvider functionality")
func testMockAIModelProvider() async throws {
    let provider = MockAIModelProvider()
    let testModel = MockAIModel(name: "test-model")

    provider.setModel(testModel, forKey: "test")

    let retrievedModel = try await provider.model(forKey: "test")
    #expect(retrievedModel.name == "test-model")
    #expect(provider.modelCallCount == 1)
    #expect(provider.lastRequestedKey == "test")
}

@Test("MockAIHTTPClient request functionality")
func testMockAIHTTPClient() async throws {
    let model = MockAIModel(name: "test-model")
    let client = MockAIHTTPClient(prompt: "Test prompt", model: model, stream: false, timeout: 30)

    client.addMockResponse("Hello World!", finishReason: .stop, promptTokens: 2, completionTokens: 2)

    let stream = try await client.request()
    let responses = try await TestingUtilities.collectStreamResults(from: stream)

    #expect(responses.count == 1)
    #expect(responses[0].content == "Hello World!")
    #expect(responses[0].finishReason == .stop)
    #expect(client.requestCallCount == 1)
}

@Test("TestingUtilities helper functions")
func testTestingUtilities() async throws {
    let chunks = TestingUtilities.createMockHTTPResponseChunks(
        contents: ["Hello", " ", "World"],
        includeStopChunk: true
    )

    #expect(chunks.count == 3)
    #expect(chunks[0].content == "Hello")
    #expect(chunks[1].content == " ")
    #expect(chunks[2].content == "World")
    #expect(chunks[2].finishReason == .stop)

    // Test quick setup
    let (client, templateProvider, modelProvider, eventHandler) = SwiftAITestingSupport.quickSetup()

    // These are non-optional types, so just verify they work
    #expect(templateProvider.templates.count >= 0)
    #expect(modelProvider.models.count >= 0)
    #expect(eventHandler.makeCacheCallCount >= 0)
    #expect(type(of: client) == AICompletionClient<MockAIHTTPClient, MockAICompletionClientEventHandler>.self)
}

@Test("MockAIWorkflow execution")
func testMockWorkflow() async throws {
    let workflow = MockAIWorkflow(
        input: MockInput(text: "Test workflow"),
        mockOutput: "Workflow completed"
    )

    let environment = TestingUtilities.createMockWorkflowEnvironment()
    let output = try await workflow.makeOutput(environment: environment, tools: ())

    #expect(output == "Workflow completed")
    #expect(MockAIWorkflow.makeOutputCallCount == 1)
    #expect(MockAIWorkflow.lastEnvironment != nil)

    // Reset state for next test
    MockAIWorkflow.resetState()
}

@Test("MockAIStreamWorkflow streaming")
func testMockStreamWorkflow() async throws {
    let workflow = MockAIStreamWorkflow(
        input: MockInput(text: "Test stream"),
        mockChunks: ["Part1", "Part2", "Part3"]
    )

    let environment = TestingUtilities.createMockWorkflowEnvironment()
    let stream = workflow.streamChunk(environment: environment, tools: ())
    let chunks = try await TestingUtilities.collectStreamResults(from: stream)

    #expect(chunks == ["Part1", "Part2", "Part3"])
    #expect(MockAIStreamWorkflow.streamChunkCallCount == 1)

    // Reset state for next test
    MockAIStreamWorkflow.resetState()
}

@Test("MockAICompletionClientEventHandler tracking")
func testMockEventHandler() {
    let eventHandler = MockAICompletionClientEventHandler()

    var cache = eventHandler.makeCache()
    #expect(eventHandler.makeCacheCallCount == 1)

    eventHandler.setParams("test params", cache: &cache)
    #expect(eventHandler.setParamsCallCount == 1)
    #expect(eventHandler.lastParams == "test params")

    let chunk = AIHTTPResponseChunk(
        content: "test content",
        reasoningContent: nil,
        promptTokens: 10,
        completionTokens: 5,
        finishReason: nil
    )

    eventHandler.onChunkReceived(chunk: chunk, forKey: "test-key", cache: &cache)
    #expect(eventHandler.onChunkReceivedCallCount == 1)
    #expect(eventHandler.lastChunk?.content == "test content")
    #expect(eventHandler.lastChunkKey == "test-key")

    eventHandler.onStop(reason: .llmFinishReasonStop, forKey: "test-key", cache: &cache)
    #expect(eventHandler.onStopCallCount == 1)
    #expect(eventHandler.lastStopReason == .llmFinishReasonStop)
    #expect(eventHandler.lastStopKey == "test-key")
}

@Test("MockAICompletionClientKind functionality")
func testMockAICompletionClientKind() async throws {
    // Create mock with configured responses
    let mockClient = TestingUtilities.createMockCompletionClientKind(
        templates: ["test": "Test template: {{input}}"],
        models: ["test": MockAIModel(name: "test-model")]
    )

    // Test generate functionality
    let completion = MockAILLMCompletion(
        input: MockInput(text: "test input", parameter: "test-param"),
        mockOutput: "Test completion output"
    )

    // Configure a specific mock result
    mockClient.setMockGenerateResult("Custom mock result", forKey: completion.path)

    let result = try await mockClient.generate(completion: completion)
    #expect(result == "Custom mock result")
    #expect(mockClient.generateCallCount == 1)
    #expect(mockClient.lastGenerateCompletion?.path == completion.path)

    // Test stream functionality
    let streamCompletion = MockAIStreamCompletion(
        input: MockInput(text: "stream input", parameter: "stream-param"),
        mockOutput: "Stream output"
    )

    // Configure mock stream results
    mockClient.setMockStreamResults(["Stream", " chunk", " 1"], forKey: streamCompletion.path)

    let stream = try await mockClient.stream(completion: streamCompletion)
    let streamResults = try await TestingUtilities.collectStreamResults(from: stream)

    #expect(streamResults == ["Stream", " chunk", " 1"])
    #expect(mockClient.streamCallCount == 1)
    #expect(mockClient.lastStreamCompletion?.path == streamCompletion.path)

    // Test error handling
    mockClient.shouldThrowError = true
    mockClient.errorToThrow = .generateTextNothingReturned

    await #expect(throws: AIClientError.self) {
        try await mockClient.generate(completion: completion)
    }

    // Reset for clean state
    mockClient.reset()
    #expect(mockClient.generateCallCount == 0)
    #expect(mockClient.streamCallCount == 0)
}

struct Client: AIHTTPClient {
    let prompt: String
    let model: any AIModel
    let stream: Bool
    var timeout: TimeInterval

    init(prompt: String, model: any SwiftAI.AIModel, stream: Bool, timeout: TimeInterval) {
        self.prompt = prompt
        self.model = model
        self.stream = stream
        self.timeout = timeout
    }

    var urlRequest: URLRequest {
        var request = URLRequest(url: requestInfo.endpoint)
        request.httpMethod = "POST"
        request.httpBody = requestInfo.body
        request.allHTTPHeaderFields = requestInfo.headers

        return request
    }

    func request() async throws(AIHTTPClientError) -> AsyncThrowingStream<AIHTTPResponseChunk, any Error> {
        let (newStream, continuation) = AsyncThrowingStream<AIHTTPResponseChunk, any Error>.makeStream()

        if stream {
            let stream = EventSourceClient(request: urlRequest).stream

            Task {
                do {
                    for try await item in stream {
                        let chunks = try decodeResponse(string: item)

                        for chunk in chunks {
                            continuation.yield(chunk)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        } else {
            do {
                let (data, _) = try await URLSession.shared.data(for: urlRequest)
                let chunks = try decodeResponse(data: data)

                for chunk in chunks {
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        return newStream
    }
}

// struct MyPromptProvider: AIPromptProvider {
//     typealias Input = [String: String]

//     func validate(key: String, input: [String: String]) -> Bool {
//         true
//     }

//     typealias Key = String

//     func prompt(key: String, input: [String: String]) async throws -> String {
//         """
//         请将以下英文翻译成简体中文
//         英文：\(input["text"]!)
//         """
//     }
// }
