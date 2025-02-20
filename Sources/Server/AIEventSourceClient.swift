#if !os(Linux)
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

        public func request() async throws(AIHTTPClientError) -> AsyncThrowingStream<String, any Error> {
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
                        }
                        
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: AIHTTPClientError(error: error))
                    }
                }
            } else {
                let data: Data
                let response: HTTPURLResponse

                do {
                    let result = try await URLSession.shared.data(for: urlRequest)

                    data = result.0
                    response = result.1 as! HTTPURLResponse

                    if String(response.statusCode).first != "2" {
                        continuation.finish(
                            throwing: AIHTTPClientError(
                                statusCode: response.statusCode,
                                data: data
                            )
                        )
                    } else {
                        let strings = decodeResponse(data: data)

                        if let string = strings.first {
                            continuation.yield(string)
                        }

                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: AIHTTPClientError(error: error))
                }
            }

            return newStream
        }
    }
#endif
