import Foundation
import SwiftAI

public protocol AIHTTPClient: Sendable {
    var prompt: String { get }
    var model: any AIModel { get }
    var stream: Bool { get }

    init(prompt: String, model: any AIModel, stream: Bool)

    func request() async throws -> AsyncThrowingStream<String, Error>
}

extension AIHTTPClient {
    public var requestInfo: AIHTTPClientRequestInfo {
        .init(model: model, prompt: prompt, stream: stream)
    }

    public func decodeResponse(data: Data) -> [String] {
        let decoder = JSONDecoder()
        let string = String(data: data, encoding: .utf8)!

        if stream {
            let lines = string.split(separator: "\n")

            return lines.map { line in
                if let result = try? decoder.decode(AIHTTPChunkedResponse.self, from: Data(line.utf8)),
                    !result.choices.isEmpty
                {
                    return result.choices[0].delta.content ?? ""
                }

                return String(line)
            }
        } else {
            if let result = try? decoder.decode(AIHTTPResponse.self, from: data), !result.choices.isEmpty {
                return [result.choices[0].message.content]
            }
        }

        return [string]
    }

    public func decodeResponse(string: String) -> [String] {
        guard let data = string.data(using: .utf8) else {
            return [string]
        }

        return decodeResponse(data: data)
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

    public var body: Data {
        let json: [String: Any] = [
            "model": model.name,
            "messages": [
                [
                    "role": "user",
                    "content": prompt,
                ]
            ],
            // "max_tokens": 60,
            // "temperature": 0.5,
            // "top_p": 1.0,
            // "frequency_penalty": 0.0,
            // "presence_penalty": 0.0,
            // "stop": ["\n"],
            "stream": stream,
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)

        return data
    }
}

public struct AIHTTPResponse: Decodable {
    public struct Choice: Decodable {
        public struct Message: Decodable {
            let role: String
            let content: String
        }

        let index: Int
        let message: Message
        let finish_reason: String
    }

    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
    let system_fingerprint: String

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
            let hate: FilterResult
            let self_harm: FilterResult
            let sexual: FilterResult
            let violence: FilterResult

            public struct FilterResult: Decodable {
                let filtered: Bool
            }
        }

        let index: Int
        let delta: Delta
        let finish_reason: String?
        let content_filter_results: ContentFilterResults
    }

    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let system_fingerprint: String

    public struct Usage: Decodable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }

    let usage: Usage
}
