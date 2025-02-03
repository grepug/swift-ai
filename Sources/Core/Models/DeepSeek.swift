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

    public enum Version: String {
        case v2_5
        case v3

        var name: String {
            switch self {
            case .v2_5: "deepseek-ai/DeepSeek-V2.5"
            case .v3: "deepseek-ai/DeepSeek-V3"
            }
        }
    }

    public init(apiKey: String, version: Version? = .v2_5, baseURL: URL? = nil) {
        self.apiKey = apiKey
        self.name = (version ?? .v2_5).name
        self.baseURL = baseURL ?? URL(string: "https://api.siliconflow.cn/v1")!
    }
}
