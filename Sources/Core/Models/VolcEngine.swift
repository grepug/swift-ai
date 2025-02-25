import Foundation

public struct VolcEngine: AIModel {
    public let name: String
    public let baseURL: URL
    public let apiKey: String

    public enum Name {
        case deepseek_3
        case custom(String)

        var rawValue: String {
            switch self {
            case .deepseek_3: "deepseek-v3-241226"
            case .custom(let name): name
            }
        }
    }

    public init(apiKey: String, name: Name? = nil, baseURL: URL? = nil) {
        self.apiKey = apiKey
        self.name = name?.rawValue ?? Name.deepseek_3.rawValue
        self.baseURL = baseURL ?? URL(string: "https://ark.cn-beijing.volces.com/api/v3")!
    }
}
