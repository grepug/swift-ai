import Foundation

actor LLMModelProvider: Sendable {
    let models: [any LLMModel]
    var index: Int = 0

    init(models: [any LLMModel]) {
        self.models = models
    }

    func getModel() -> any LLMModel {
        models[index]
    }

    func moveToNextModel() {
        index = (index + 1) % models.count
    }
}
