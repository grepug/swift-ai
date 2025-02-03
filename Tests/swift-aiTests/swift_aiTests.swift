import EventSource
import Foundation
import Testing

@testable import SwiftAI

@Test func example() async throws {
    let runner = LLMRunner(
        models: [
            DeepSeekSF(apiKey: "sk-bfwsvwnbgyuetpjfycrmeavfvrmspihhkgrwpcofhtbqldje")
        ],
        promptProvider: MyPromptProvider(),
        client: Client.self
    )

    // let string = try await runner.generateText(key: "", params: ["text": "Hello, World!"])
    let stream = await runner.streamText(key: "", params: ["text": "Hello, World!"])

    var string = ""

    for try await item in stream {
        string += item
        print("Received: \(string)")

    }

    #expect(string.count > 0)
}

struct Client: LLMHTTPClient {
    let prompt: String
    let model: any LLMModel
    let stream: Bool

    init(prompt: String, model: any SwiftAI.LLMModel, stream: Bool) {
        self.prompt = prompt
        self.model = model
        self.stream = stream
    }

    var urlRequest: URLRequest {
        var request = URLRequest(url: requestInfo.endpoint)
        request.httpMethod = "POST"
        request.httpBody = requestInfo.body
        request.allHTTPHeaderFields = requestInfo.headers

        return request
    }

    func request() async throws -> AsyncThrowingStream<String, any Error> {
        let (newStream, continuation) = AsyncThrowingStream<String, any Error>.makeStream()

        if stream {
            let stream = EventSourceClient(request: urlRequest).stream

            Task {
                do {
                    for try await item in stream {
                        let strings = decodeResponse(string: item)

                        for string in strings {
                            continuation.yield(string)
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
                let strings = decodeResponse(data: data)

                for string in strings {
                    continuation.yield(string)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        return newStream
    }
}

struct MyPromptProvider: LLMPromptProvider {
    func validate(key: String, params: [String: String]) -> Bool {
        true
    }

    typealias Key = String
    typealias Params = [String: String]

    func prompt(key: String, params: [String: String]) async throws -> String {
        """
        请将以下英文翻译成简体中文
        英文：\(params["text"]!)
        """
    }
}
