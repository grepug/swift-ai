// should be conformed by a concrect type on the server
public protocol AILLMCompletion: AITask {
    func promptTemplate() async throws -> String

    func makeOutput(string: String) -> Output
    func makeOutput(chunk: String, accumulatedString: inout String) -> (output: Output?, shouldStop: Bool)
}

extension AILLMCompletion {
    public func makePromptString() async throws -> String {
        var prompt = try await promptTemplate()

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

public enum AILLMCompletionError: Error {
    case invalidPromptParams
}
