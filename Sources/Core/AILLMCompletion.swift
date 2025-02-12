import Foundation

// should be conformed by a concrect type on the server
public protocol AILLMCompletion: AITask {
    func makeOutput(string: String) -> Output

    // this is used for stream completion which indicates the start and end of the output
    var startSymbol: String? { get }
    var endSymbol: String? { get }
}

public protocol AIStreamCompletion: AILLMCompletion, AIStreamTask {
    func makeOutput(chunk: String, accumulatedString: inout String) -> (output: Output?, shouldStop: Bool)
}

extension AILLMCompletion {
    public var startSymbol: String? {
        nil
    }

    public var endSymbol: String? {
        nil
    }

    public func makePromptString(template: String) async throws -> String {
        var prompt = template

        for (key, value) in input.normalized {
            prompt = prompt.replacingOccurrences(of: "{{\(key)}}", with: value)
        }

        print("prompt: \(prompt)")

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
