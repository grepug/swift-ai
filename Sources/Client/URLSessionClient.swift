#if !os(Linux)
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
            request.httpBody = try! JSONEncoder().encode(AIClientRequestContent(task: task))

            return request
        }

        public func stream<T: AIStreamTask>(aiTask: T) -> AsyncThrowingStream<T.Output, Error> {
            let request = makeURLRequest(task: aiTask)

            return AsyncThrowingStream<T.Output, Error>.makeCancellable { continuation in
                let esClient = EventSourceClient(request: request)
                let stream = esClient.stream

                do {
                    var partialOutput = aiTask.initialOutput()
                    let decoder = JSONDecoder()

                    for try await chunk in stream {
                        try Task.checkCancellation()

                        let data = chunk.data(using: .utf8) ?? Data()
                        let response = try decoder.decode(AIServerStreamResponseContent<T.StreamChunk>.self, from: data)

                        aiTask.reduce(partialOutput: &partialOutput, chunk: response.chunk)

                        continuation.yield(partialOutput)

                        if response.finished {
                            break
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }

        public func request<T: AITask>(aiTask: T) async throws -> T.Output {
            let request = makeURLRequest(task: aiTask)
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            return try decoder.decode(AIServerResponseContent<T.Output>.self, from: data).output
        }
    }
#endif
