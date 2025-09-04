import Foundation
import SwiftAI
import SwiftAIServer

/// Mock implementation of AICompletionClientEventHandler for testing purposes
public final class MockAICompletionClientEventHandler: AICompletionClientEventHandler, @unchecked Sendable {

    // Track method calls and data for verification
    public var setParamsCallCount = 0
    public var onChunkReceivedCallCount = 0
    public var onStopCallCount = 0

    public var lastParams: String?
    public var lastChunk: AIHTTPResponseChunk?
    public var lastChunkKey: String?
    public var lastStopReason: AICompletionClientEventStopReason?
    public var lastStopKey: String?

    // Internal cache implementation (since the protocol no longer manages cache)
    public var internalCache: [String: Any] = [:]
    public var capturedEvents: [(event: String, data: [String: Any])] = []

    public init() {}

    public func setParams(_ params: String) {
        setParamsCallCount += 1
        lastParams = params

        // Store in internal cache
        internalCache["params"] = params

        // Capture event for verification
        capturedEvents.append((event: "setParams", data: ["params": params]))
    }

    public func onChunkReceived(chunk: AIHTTPResponseChunk, forKey key: String) {
        onChunkReceivedCallCount += 1
        lastChunk = chunk
        lastChunkKey = key

        // Track chunks in internal cache
        var chunks = internalCache["chunks"] as? [AIHTTPResponseChunk] ?? []
        chunks.append(chunk)
        internalCache["chunks"] = chunks
        internalCache["lastKey"] = key

        // Capture event for verification
        capturedEvents.append(
            (
                event: "onChunkReceived",
                data: [
                    "key": key,
                    "content": chunk.content,
                    "promptTokens": chunk.promptTokens,
                    "completionTokens": chunk.completionTokens,
                ]
            ))
    }

    public func onStop(reason: AICompletionClientEventStopReason, forKey key: String) {
        onStopCallCount += 1
        lastStopReason = reason
        lastStopKey = key

        // Store in internal cache
        internalCache["stopReason"] = reason
        internalCache["stopKey"] = key

        // Capture event for verification
        capturedEvents.append(
            (
                event: "onStop",
                data: [
                    "key": key,
                    "reason": "\(reason)",
                ]
            ))
    }

    // Convenience methods for testing
    public func reset() {
        setParamsCallCount = 0
        onChunkReceivedCallCount = 0
        onStopCallCount = 0

        lastParams = nil
        lastChunk = nil
        lastChunkKey = nil
        lastStopReason = nil
        lastStopKey = nil

        internalCache.removeAll()
        capturedEvents.removeAll()
    }

    // Helper methods for test verification
    public func getChunks() -> [AIHTTPResponseChunk] {
        return internalCache["chunks"] as? [AIHTTPResponseChunk] ?? []
    }

    public func getParams() -> String? {
        return internalCache["params"] as? String
    }

    public func getStopReason() -> AICompletionClientEventStopReason? {
        return internalCache["stopReason"] as? AICompletionClientEventStopReason
    }

    public func getEventsOfType(_ eventType: String) -> [(event: String, data: [String: Any])] {
        return capturedEvents.filter { $0.event == eventType }
    }

    public func getAllEvents() -> [(event: String, data: [String: Any])] {
        return capturedEvents
    }
}
