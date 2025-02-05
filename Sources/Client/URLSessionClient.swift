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

    func makeURLRequest(key: String) -> URLRequest {
        let url = makeURL(key)
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    public func stream<T: AITask>(aiTask: T) -> AsyncThrowingStream<T.Output, Error> {
        let request = makeURLRequest(key: aiTask.key)
        let (newStream, continuation) = AsyncThrowingStream<T.Output, Error>.makeStream()
        let stream = EventSourceClient(request: request).stream

        Task {
            do {
                let decoder = JSONDecoder()
                for try await chunk in stream {
                    let data = chunk.data(using: .utf8) ?? Data()
                    let output = try decoder.decode(T.Output.self, from: data)
                    continuation.yield(output)
                }

                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        return newStream
    }

    public func request<T: AITask>(aiTask: T) async throws -> T.Output {
        let request = makeURLRequest(key: aiTask.key)
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        return try decoder.decode(T.Output.self, from: data)
    }
}
