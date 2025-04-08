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

public typealias AITaskOutput = Codable & Sendable & Hashable

// the basic model for client to interact with the AI
public protocol AITask: Sendable, Codable {
    associatedtype Input: AITaskInput
    associatedtype Output: AITaskOutput

    static var kind: String { get }

    var key: String { get }
    var input: Input { get }

    init(input: Input)
}

public struct EmptyInput: AITaskInput {
    public init() {}
}

extension AITask {
    public var key: String {
        Self.kind
    }
}

public protocol AIStreamTask: AITask {
    associatedtype StreamChunk: AITaskOutput = Output

    func initialOutput() -> Output
    // accumulate the chunk and return the output on the client
    func reduce(partialOutput: inout Output, chunk: StreamChunk)
}
