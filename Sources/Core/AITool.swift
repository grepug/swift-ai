// only defined on the server
public protocol AITool: AITask {
    func makeOutput(input: Input) async throws -> Output
}
