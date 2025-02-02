import Foundation

public protocol LLMHTTPClient: Sendable {
    var prompt: String { get set }
    var model: any LLMModel { get set }
    var stream: Bool { get set }

    init(prompt: String, model: any LLMModel, stream: Bool)

    func request() async throws -> AsyncThrowingStream<String, Error>
}

extension LLMHTTPClient {
    public func requestInfo() -> LLMHTTPClientRequestInfo {
        .init(model: model, prompt: prompt, stream: stream)
    }
}

public struct LLMHTTPClientRequestInfo {
    let model: any LLMModel
    let prompt: String
    let stream: Bool

    public var endpoint: URL {
        model.baseURL
            .appendingPathComponent("chat")
            .appendingPathComponent("completions")
    }

    public var headers: [String: String] {
        ["Authorization": "Bearer \(model.apiKey)"]
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
            "prompt": prompt,
            "max_tokens": 60,
            "temperature": 0.5,
            "top_p": 1.0,
            "frequency_penalty": 0.0,
            "presence_penalty": 0.0,
            "stop": ["\n"],
            "stream": stream,
        ]

        return try! JSONSerialization.data(withJSONObject: json)
    }
}
