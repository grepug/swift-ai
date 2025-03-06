import Foundation
import SwiftAI

public enum AIClientError: LocalizedError {
    case generateTextNothingReturned
    case promptTemplateError(AIPromptTemplateProviderError)
    case makingPromptError(AILLMCompletionError)
    case requestError(Error)
    case streamError(Error)
    case promptTemplateNotFound(key: String)

    public var errorDescription: String? {
        switch self {
        case .generateTextNothingReturned:
            return "Generate text nothing returned"
        case .promptTemplateError(let error):
            return error.localizedDescription
        case .makingPromptError(let error):
            return error.localizedDescription
        case .requestError(let error):
            return error.localizedDescription
        case .streamError(let error):
            return error.localizedDescription
        case .promptTemplateNotFound(let key):
            return "Prompt template not found for key: \(key)"
        }
    }
}

public struct AIHTTPClientError: LocalizedError {
    public let message: String?
    public let statusCode: Int?
    public let data: Data?

    public var errorDescription: String? {
        """
        message: \(message ?? "")
        statusCode: \(statusCode ?? -1)
        data: \(String(data: data ?? Data(), encoding: .utf8) ?? "")
        """
    }

    public init(message: String? = nil, statusCode: Int? = nil, data: Data? = nil) {
        self.message = message
        self.statusCode = statusCode
        self.data = data
    }

    public init(error: Error) {
        self.message = error.localizedDescription
        self.statusCode = nil
        self.data = nil
    }
}

public enum AIPromptTemplateProviderError: LocalizedError {
    case promptTemplateNotFound(key: String)
    case other(LocalizedError)

    public var errorDescription: String? {
        switch self {
        case .promptTemplateNotFound(let key):
            return "Prompt template not found for key: \(key)"
        case .other(let error):
            return error.localizedDescription
        }
    }
}
