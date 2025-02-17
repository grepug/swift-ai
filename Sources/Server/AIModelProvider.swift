import Foundation
import Logging
import SwiftAI

actor AIModelProvider: Sendable {
    let models: [any AIModel]
    var index: Int = 0

    init(models: [any AIModel]) {
        self.models = models
    }

    struct GetModelResult {
        let model: any AIModel
        let usingPreferred: Bool
    }

    func getModel(preferredModel model: (any AIModel)? = nil) -> GetModelResult {
        if let model {
            return GetModelResult(
                model: model,
                usingPreferred: model.name != models[index].name
            )
        }

        let model = models[index]
        return GetModelResult(model: model, usingPreferred: false)
    }

    func moveToNextModel() {
        index = (index + 1) % models.count
    }
}
