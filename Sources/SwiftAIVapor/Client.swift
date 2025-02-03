//
//  Client.swift
//
//
//  Created by Kai Shao on 2024/7/16.
//

import AsyncHTTPClient
import ConcurrencyUtils
import Foundation
import Vapor

typealias CURequest = ConcurrencyUtils.ClientRequest

struct Client: ClientKind, Sendable {
    let client: AsyncHTTPClient.HTTPClient
    let logger: Logger

    init(client: AsyncHTTPClient.HTTPClient, logger: Logger) {
        self.client = client
        self.logger = logger
    }

    func data(for request: ConcurrencyUtils.ClientRequest) async throws -> Data {
        let request = request.httpClientRequest
        let response = try await client.execute(request, timeout: .seconds(60), logger: logger)
        var bytes = try await response.body.collect(upTo: 1024 * 1024)

        return bytes.readData(length: bytes.readableBytes)!
    }

    func stream(for request: ConcurrencyUtils.ClientRequest) -> AsyncThrowingStream<String, Error> {
        let request = request.httpClientRequest

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await client.execute(request, timeout: .seconds(60), logger: logger)
                    let body = response.body

                    try await withTimeoutThrowingHandler(timeout: .seconds(60)) {
                        for try await buffer in body {
                            let string = String(buffer: buffer)

                            if string.contains("[DONE]") {
                                continuation.finish()
                                return
                            }

                            continuation.yield(string)
                        }
                    }

                    continuation.finish()
                } catch ConcurrencyError.timeout {
                    continuation.finish(throwing: ConcurrencyError.timeout)
                } catch {
                    if let clientError = error as? HTTPClientError {
                        switch clientError {
                        case .cancelled:
                            continuation.finish()
                        default:
                            continuation.finish(throwing: error)
                        }
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }

    func shutdown() async throws {
        try await client.shutdown()
    }
}

extension ConcurrencyUtils.ClientRequest {
    var httpClientRequest: HTTPClientRequest {
        var request = HTTPClientRequest(url: url.absoluteString)

        switch method {
        case .get:
            request.method = .GET
        case .post:
            request.method = .POST
        case .patch:
            request.method = .PATCH
        case .delete:
            request.method = .DELETE
        case .put:
            request.method = .PUT
        }

        if let data = body {
            request.body = .bytes(.init(data: data))
        }

        for (k, v) in headers {
            request.headers.add(name: k, value: v)
        }

        return request
    }
}

extension Request {
    func makeClient() -> Client {
        return .init(client: .init(eventLoopGroupProvider: .shared(application.eventLoopGroup.any())), logger: logger)
    }
}
