import Foundation

// should be conformed by a concrect type on the server
public protocol AILLMCompletion: AITask {
    func makeOutput(string: String) -> Output

    var preferredModel: (any AIModel)? { get }

    // this is used for stream completion which indicates the start and end of the output
    var startSymbol: String? { get }
    var endSymbol: String? { get }
}

public protocol AIStreamCompletion: AILLMCompletion, AIStreamTask {
    associatedtype Cache = String

    func makeOutput(chunk: String, cache: inout Cache) -> (output: Output?, shouldStop: Bool)
    func initCache() -> Cache
}

extension AIStreamCompletion where Cache == String {
    public func initialOutput() -> String {
        ""
    }
}

extension AILLMCompletion {
    public var startSymbol: String? {
        nil
    }

    public var endSymbol: String? {
        nil
    }

    public var preferredModel: (any AIModel)? {
        nil
    }

    public func makePromptString(template: String) async throws(AILLMCompletionError) -> String {
        var prompt = template

        for (key, value) in input.normalized {
            prompt = prompt.replacingOccurrences(of: "{{\(key)}}", with: value)
        }

        // validate if there is no {{}}
        if prompt.contains("{{") {
            throw AILLMCompletionError.invalidPromptParams
        }

        return prompt
    }
}

public enum AILLMCompletionError: LocalizedError {
    case invalidPromptParams

    public var errorDescription: String? {
        switch self {
        case .invalidPromptParams:
            return "Invalid prompt parameters"
        }
    }
}
