public protocol LLMPromptInput: Codable, Sendable {
    var inputDict: [String: String] { get }
}

extension LLMPromptInput {
    public var inputDict: [String: String] {
        let mirror = Mirror(reflecting: self)
        var dict: [String: String] = [:]

        for child in mirror.children {
            if let key = child.label {
                dict[key] = "\(child.value)"
            }
        }

        return dict
    }
}
