import Foundation

public struct DeepSeek: AIModel {
    public let name: String
    public let baseURL: URL
    public let apiKey: String

    public init(apiKey: String, name: String = "DeepSeek", baseURL: URL? = nil) {
        self.apiKey = apiKey
        self.name = name
        self.baseURL = baseURL ?? URL(string: "https://api.deepseek.com/v1")!
    }
}

public struct SiliconFlow: AIModel {
    public let name: String
    public let baseURL: URL
    public let apiKey: String

    public enum Name {
        case deepSeek_2_5
        case deepSeek_3
        case meta
        case qwen
        case custom(String)

        var rawValue: String {
            switch self {
            case .deepSeek_2_5: "deepseek-ai/DeepSeek-V2.5"
            case .deepSeek_3: "deepseek-ai/DeepSeek-V3"
            case .meta: "meta-llama/Llama-3.3-70B-Instruct"
            case .qwen: "Qwen/Qwen2.5-14B-Instruct"
            case .custom(let name): name
            }
        }
    }

    public init(apiKey: String, name: Name? = nil, baseURL: URL? = nil) {
        self.apiKey = apiKey
        self.name = name?.rawValue ?? Name.deepSeek_2_5.rawValue
        self.baseURL = baseURL ?? URL(string: "https://api.siliconflow.cn/v1")!
    }
}
