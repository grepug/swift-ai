import Foundation

public struct DeepSeek: LLMModel {
    public let name: String
    public let baseURL: URL
    public let apiKey: String

    public init(apiKey: String, name: String = "DeepSeek", baseURL: URL? = nil) {
        self.apiKey = apiKey
        self.name = name
        self.baseURL = baseURL ?? URL(string: "https://api.deepseek.com/v1")!
    }
}

public struct DeepSeekSF: LLMModel {
    public let name: String
    public let baseURL: URL
    public let apiKey: String

    public init(apiKey: String, name: String = "deepseek-ai/DeepSeek-V3", baseURL: URL? = nil) {
        self.apiKey = apiKey
        self.name = name
        self.baseURL = baseURL ?? URL(string: "https://api.siliconflow.cn/v1")!
    }
}
