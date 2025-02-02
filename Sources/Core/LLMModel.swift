import Foundation

public protocol LLMModel: Sendable {
    // associatedtype Response: Decodable = LLMHTTPResponse

    var name: String { get }
    var baseURL: URL { get }
    var apiKey: String { get }
}
