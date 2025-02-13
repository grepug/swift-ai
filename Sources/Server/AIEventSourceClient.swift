import EventSource
import Foundation
import SwiftAI

public struct AIEventSourceClient: AIHTTPClient {
    public var prompt: String
    public var model: any AIModel
    public var stream: Bool

    public init(prompt: String, model: any AIModel, stream: Bool) {
        self.prompt = prompt
        self.model = model
        self.stream = stream
    }

    public func request() async throws -> AsyncThrowingStream<String, any Error> {
        var urlRequest = URLRequest(url: requestInfo.endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestInfo.body
        urlRequest.setValue("Bearer \(model.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (newStream, continuation) = AsyncThrowingStream<String, any Error>.makeStream()

        if stream {
            let client = EventSourceClient(request: urlRequest)

            Task {
                do {
                    for try await item in client.stream {
                        let item = item.replacingOccurrences(of: "data:", with: "")
                        let strings = decodeResponse(string: item)

                        for string in strings {
                            continuation.yield(string)
                        }

                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        } else {
            do {
                let (data, _) = try await URLSession.shared.data(for: urlRequest)
                let strings = decodeResponse(data: data)
                if let string = strings.first {
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
