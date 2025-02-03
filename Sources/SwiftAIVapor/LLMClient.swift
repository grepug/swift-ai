import ConcurrencyUtils
import Dependencies
import SwiftAI
import Vapor

public struct LLMClient: LLMHTTPClient {
    public let prompt: String
    public let model: any SwiftAI.LLMModel
    public let stream: Bool

    var client: Client!

    @Dependency(\.request) var req

    public init(prompt: String, model: any LLMModel, stream: Bool) {
        self.prompt = prompt
        self.model = model
        self.stream = stream
        self.client = req.makeClient()
    }

    public func request() async throws -> AsyncThrowingStream<String, any Error> {
        let request = ClientRequest(
            urlString: requestInfo.endpoint.absoluteString,
            method: .post,
            headers: [
                .authorization(bearer: model.apiKey),
                .contentTypeJSON,
            ],
            body: requestInfo.body
        )

        let (newStream, continuation) = AsyncThrowingStream<String, any Error>.makeStream()

        if stream {
            let stream = client.stream(for: request)

            Task {
                do {
                    for try await item in stream {
                        let item = item.replacingOccurrences(of: "data:", with: "")
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
                let response = try await client.data(for: request)
                let strings = decodeResponse(data: response)
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

    public func shutdown() async throws {
        try await client.shutdown()
    }
}

extension DependencyValues {
    var request: Request {
        get { self[RequestKey.self] }
        set { self[RequestKey.self] = newValue }
    }

    private enum RequestKey: DependencyKey {
        static var liveValue: Request {
            fatalError("Value of type \(Value.self) is not registered in this context")
        }
    }
}
