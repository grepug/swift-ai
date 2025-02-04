public typealias LLMPromptNormalizedInput = [String: String]

extension LLMPromptNormalizedInput: LLMPromptInput {
    public var normalized: LLMPromptNormalizedInput {
        self
    }
}

public protocol LLMPromptInput: Codable, Sendable {
    var normalized: LLMPromptNormalizedInput { get }
}

extension LLMPromptInput {
    public var normalized: LLMPromptNormalizedInput {
        let mirror = Mirror(reflecting: self)
        var dict: LLMPromptNormalizedInput = [:]

        for child in mirror.children {
            if let key = child.label {
                dict[key] = "\(child.value)"
            }
        }

        return dict
    }
}
