#if !os(Linux)
    import EventSource
    import Foundation
    import SwiftAI
    import ConcurrencyUtils

    public struct AIEventSourceClient: AIHTTPClient {
        public var prompt: String
        public var model: any AIModel
        public var stream: Bool
        public var timeout: TimeInterval

        public init(prompt: String, model: any AIModel, stream: Bool, timeout: TimeInterval) {
            self.prompt = prompt
            self.model = model
            self.stream = stream
            self.timeout = timeout
        }

        public func request() async throws(AIHTTPClientError) -> AsyncThrowingStream<AIHTTPResponseChunk, any Error> {
            var urlRequest = URLRequest(url: requestInfo.endpoint)
            urlRequest.httpMethod = "POST"
            urlRequest.httpBody = requestInfo.body
            urlRequest.setValue("Bearer \(model.apiKey)", forHTTPHeaderField: "Authorization")
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            if stream {
                let client = EventSourceClient(request: urlRequest)

                return .makeCancellable { continuation in
                    do {
                        for try await item in client.stream {
                            let item = item.replacingOccurrences(of: "data:", with: "")
                            let chunks = try decodeResponse(string: item)

                            for chunk in chunks {
                                continuation.yield(chunk)
                            }
                        }

                        continuation.finish()
                    } catch is CancellationError {
                        continuation.finish(throwing: CancellationError())
                    } catch {
                        continuation.finish(throwing: AIHTTPClientError(error: error))
                    }
                }
            } else {
                // Non-streaming case remains largely unchanged
                return .makeCancellable { continuation in
                    Task {
                        do {
                            let result = try await URLSession.shared.data(for: urlRequest)

                            let data = result.0
                            let response = result.1 as! HTTPURLResponse

                            if String(response.statusCode).first != "2" {
                                continuation.finish(
                                    throwing: AIHTTPClientError(
                                        statusCode: response.statusCode,
                                        data: data
                                    )
                                )
                            } else {
                                let chunks = try decodeResponse(data: data)

                                for chunk in chunks {
                                    continuation.yield(chunk)
                                }

                                continuation.finish()
                            }
                        } catch {
                            continuation.finish(throwing: AIHTTPClientError(error: error))
                        }
                    }
                }
            }
        }
    }
#endif
