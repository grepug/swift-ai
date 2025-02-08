import EventSource
import Foundation
import SwiftAI

public struct URLSessionClient {
    let accessToken: String
    let makeURL: (_ key: String) -> URL

    public init(accessToken: String, makeURL: @escaping (_ key: String) -> URL) {
        self.accessToken = accessToken
        self.makeURL = makeURL
    }

    func makeURLRequest<T: AITask>(task: T) -> URLRequest {
        let url = makeURL(task.key)
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try! JSONEncoder().encode(task)

        return request
    }

    public func stream<T: AIStreamTask>(aiTask: T) -> AsyncThrowingStream<T.Output, Error> {
        let request = makeURLRequest(task: aiTask)
        let (newStream, continuation) = AsyncThrowingStream<T.Output, Error>.makeStream()
        let stream = EventSourceClient(request: request).stream

        Task {
            do {
                var chunks: [T.StreamChunk] = []

                let decoder = JSONDecoder()

                for try await chunk in stream {
                    let data = chunk.data(using: .utf8) ?? Data()
                    let response = try decoder.decode(AIServerStreamResponseContent<T>.self, from: data)
                    chunks.append(response.chunk)

                    let output = aiTask.assembleOutput(chunks: chunks)

                    continuation.yield(output)

                    if response.finished {
                        break
                    }
                }

                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        return newStream
    }

    public func request<T: AITask>(aiTask: T) async throws -> T.Output {
        let request = makeURLRequest(task: aiTask)
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        return try decoder.decode(AIServerResponseContent<T>.self, from: data).output
    }
}
