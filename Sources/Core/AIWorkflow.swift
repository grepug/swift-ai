// an AITask can be a workflow, it contains multiple tasks to run
public protocol AIWorkflow: AITask {
    func makeOutput() async throws -> Output
    func streamOutput() -> AsyncThrowingStream<Output, Error>
}
