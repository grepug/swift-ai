import EventSource
import Foundation
import Testing

@testable import SwiftAI
@testable import SwiftAIServer

// @Test func example() async throws {
//     let client = AICompletionClient(
//         models: [
//             SiliconFlow(apiKey: "sk-bfwsvwnbgyuetpjfycrmeavfvrmspihhkgrwpcofhtbqldje")
//         ],
//         client: Client.self
//     )

//     // let string = try await client.generateText(key: "", params: ["text": "Hello, World!"])
//     let completion = (
//         key: "",
//         input: ["text": "Hello, World!"],
//         staticTemplate:
//             """
//             请将以下英文翻译成简体中文
//             英文：{{text}}
//             """
//     )

//     let stream = await client.stream(completion: completion)
//     var string = ""

//     for try await item in stream {
//         string += item.text
//     }

//     #expect(string.count > 0)
// }

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

    func request() async throws(AIHTTPClientError) -> AsyncThrowingStream<String, any Error> {
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
