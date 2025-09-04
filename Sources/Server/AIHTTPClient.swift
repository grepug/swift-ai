import Foundation
import SwiftAI

public protocol AIHTTPClient: Sendable {
    var prompt: String { get }
    var timeout: TimeInterval { get }
    var model: any AIModel { get }
    var stream: Bool { get }

    init(prompt: String, model: any AIModel, stream: Bool, timeout: TimeInterval)

    func request() async throws(AIHTTPClientError) -> AsyncThrowingStream<AIHTTPResponseChunk, any Error>
}

public struct AIHTTPResponseChunk: Codable, Sendable {
    public enum FinishReason: Codable, Sendable, Equatable {
        case stop
        case other(String)

        init(string: String) {
            if string == "stop" {
                self = .stop
            } else {
                self = .other(string)
            }
        }
    }

    public let content: String
    public var reasoningContent: String?
    public let promptTokens: Int
    public let completionTokens: Int
    public let finishReason: FinishReason?

    public init(
        content: String,
        reasoningContent: String? = nil,
        promptTokens: Int,
        completionTokens: Int,
        finishReason: FinishReason? = nil
    ) {
        self.content = content
        self.reasoningContent = reasoningContent
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.finishReason = finishReason
    }
}

extension AIHTTPClient {
    public var requestInfo: AIHTTPClientRequestInfo {
        .init(model: model, prompt: prompt, stream: stream)
    }

    public func decodeResponse(data: Data) throws -> [AIHTTPResponseChunk] {
        let decoder = JSONDecoder()
        let string = String(data: data, encoding: .utf8)!

        if stream {
            let lines = string.split(separator: "\n")

            return try lines.compactMap { line -> AIHTTPResponseChunk? in
                do {
                    let result = try decoder.decode(AIHTTPChunkedResponse.self, from: Data(line.utf8))

                    if !result.choices.isEmpty {
                        let firstChoice = result.choices[0]
                        let usage = result.usage
                        let content = firstChoice.delta.content ?? ""

                        return AIHTTPResponseChunk(
                            content: content,
                            reasoningContent: firstChoice.delta.reasoning_content,
                            promptTokens: usage?.prompt_tokens ?? 0,
                            completionTokens: usage?.completion_tokens ?? 0,
                            finishReason: firstChoice.finish_reason.map { .init(string: $0) },
                        )
                    }

                    if let message = result.message {
                        assertionFailure("Unexpected message in chunked response")
                        throw AIHTTPClientError(message: message)
                    }

                    assertionFailure("Unexpected response format")

                    return nil
                } catch {
                    if let error = error as? AIHTTPClientError {
                        throw error
                    }

                    throw AIHTTPClientError(message: String(line))
                }
            }
        } else {
            if let result = try? decoder.decode(AIHTTPResponse.self, from: data), !result.choices.isEmpty {
                return [
                    AIHTTPResponseChunk(
                        content: result.choices[0].message.content,
                        reasoningContent: nil,
                        promptTokens: result.usage?.prompt_tokens ?? 0,
                        completionTokens: result.usage?.completion_tokens ?? 0,
                        finishReason: result.choices[0].finish_reason.map { .init(string: $0) },
                    )
                ]
            }
        }

        assertionFailure("Failed to decode AIHTTPResponse or AIHTTPChunkedResponse")

        return []
    }

    public func decodeResponse(string: String) throws -> [AIHTTPResponseChunk] {
        guard let data = string.data(using: .utf8) else {
            return []
        }

        return try decodeResponse(data: data)
    }
}

public struct AIHTTPClientRequestInfo {
    let model: any AIModel
    let prompt: String
    let stream: Bool

    public var endpoint: URL {
        model.baseURL
            .appendingPathComponent("chat")
            .appendingPathComponent("completions")
    }

    public var headers: [String: String] {
        [
            "Authorization": "Bearer \(model.apiKey)",
            "Content-Type": "application/json",
        ]
    }

    struct Body: Encodable {
        let model: String
        let messages: [[String: String]]
        let stream: Bool
        var thinking: [String: String]? = nil

        // let max_tokens: Int = 60
        // let temperature: Double = 0.5
        // let top_p: Double = 1.0
        // let frequency_penalty: Double = 0.0
        // let presence_penalty: Double = 0.0
        // let stop: [String] = ["\n"]
    }

    public var body: Data {
        let body = Body(
            model: model.name,
            messages: [["role": "user", "content": prompt]],
            stream: stream,
            thinking: model.thinkingDisabled == true ? ["type": "disabled"] : nil,
        )

        let data = try! JSONEncoder().encode(body)

        return data
    }
}

public struct AIHTTPResponse: Decodable {
    public struct Choice: Decodable {
        public struct Message: Decodable {
            let role: String
            let content: String
        }

        let index: Int?
        let message: Message
        let finish_reason: String?
    }

    let id: String?
    let object: String?
    let created: Int?
    let model: String
    let choices: [Choice]
    let usage: Usage?
    let system_fingerprint: String?
    let message: String?

    public struct Usage: Decodable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }
}

public struct AIHTTPChunkedResponse: Decodable {
    public struct Choice: Decodable {
        public struct Delta: Decodable {
            let content: String?
            let reasoning_content: String?
        }

        public struct ContentFilterResults: Decodable {
            let hate: FilterResult?
            let self_harm: FilterResult?
            let sexual: FilterResult?
            let violence: FilterResult?

            public struct FilterResult: Decodable {
                let filtered: Bool?
            }
        }

        let index: Int?
        let delta: Delta
        let finish_reason: String?
        let content_filter_results: ContentFilterResults?
    }

    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]
    let system_fingerprint: String?
    let message: String?

    public struct Usage: Decodable {
        let prompt_tokens: Int?
        let completion_tokens: Int?
        let total_tokens: Int?
    }

    let usage: Usage?
}
