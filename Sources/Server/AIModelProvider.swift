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
            if let preferredModel = models.first(where: { $0.name == model.name }) {
                return GetModelResult(
                    model: preferredModel,
                    usingPreferred: true
                )
            }
        }

        let model = models[index]
        return GetModelResult(model: model, usingPreferred: false)
    }

    func moveToNextModel() {
        index = (index + 1) % models.count
    }
}
