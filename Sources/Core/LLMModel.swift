import Foundation

public protocol LLMModel: Sendable {
    var name: String { get }
    var baseURL: URL { get }
    var apiKey: String { get }
}
