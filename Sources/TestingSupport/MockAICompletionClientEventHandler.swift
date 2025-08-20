import Foundation
import SwiftAI
import SwiftAIServer

/// Mock implementation of AICompletionClientEventHandler for testing purposes
public final class MockAICompletionClientEventHandler: AICompletionClientEventHandler, @unchecked Sendable {
    public typealias Cache = [String: Any]

    // Track method calls and data for verification
    public var makeCacheCallCount = 0
    public var setParamsCallCount = 0
    public var onChunkReceivedCallCount = 0
    public var onStopCallCount = 0

    public var lastParams: String?
    public var lastChunk: AIHTTPResponseChunk?
    public var lastChunkKey: String?
    public var lastStopReason: AICompletionClientEventStopReason?
    public var lastStopKey: String?
    public var capturedCaches: [Cache] = []

    // Configuration
    public var customCacheData: [String: Any] = [:]

    public init() {}

    public func makeCache() -> Cache {
        makeCacheCallCount += 1
        var cache = Cache()
        cache.merge(customCacheData) { _, new in new }
        return cache
    }

    public func setParams(_ params: String, cache: inout Cache) {
        setParamsCallCount += 1
        lastParams = params
        cache["params"] = params
        capturedCaches.append(cache)
    }

    public func onChunkReceived(chunk: AIHTTPResponseChunk, forKey key: String, cache: inout Cache) {
        onChunkReceivedCallCount += 1
        lastChunk = chunk
        lastChunkKey = key

        // Track chunks in cache
        var chunks = cache["chunks"] as? [AIHTTPResponseChunk] ?? []
        chunks.append(chunk)
        cache["chunks"] = chunks
        cache["lastKey"] = key

        capturedCaches.append(cache)
    }

    public func onStop(reason: AICompletionClientEventStopReason, forKey key: String, cache: inout Cache) {
        onStopCallCount += 1
        lastStopReason = reason
        lastStopKey = key

        cache["stopReason"] = reason
        cache["stopKey"] = key

        capturedCaches.append(cache)
    }

    // Convenience methods for testing
    public func reset() {
        makeCacheCallCount = 0
        setParamsCallCount = 0
        onChunkReceivedCallCount = 0
        onStopCallCount = 0

        lastParams = nil
        lastChunk = nil
        lastChunkKey = nil
        lastStopReason = nil
        lastStopKey = nil
        capturedCaches.removeAll()
        customCacheData.removeAll()
    }

    public func setCustomCacheData(_ data: [String: Any]) {
        customCacheData = data
    }
}
