public typealias AICompletionNormalizedInput = [String: String]

extension AICompletionNormalizedInput: AITaskInput {
    public var normalized: AICompletionNormalizedInput {
        self
    }
}

public protocol AITaskInput: Codable, Sendable {
    var normalized: AICompletionNormalizedInput { get }
}

extension AITaskInput {
    public var normalized: AICompletionNormalizedInput {
        let mirror = Mirror(reflecting: self)
        var dict: AICompletionNormalizedInput = [:]

        for child in mirror.children {
            if let key = child.label {
                dict[key] = "\(child.value)"
            }
        }

        return dict
    }
}

public typealias AITaskOutput = Codable & Sendable

// the basic model for client to interact with the AI
public protocol AITask: Sendable, Codable {
    associatedtype Input: AITaskInput
    associatedtype Output: AITaskOutput

    // the key is to communicate with the server
    var key: String { get }
    var input: Input { get }
}
