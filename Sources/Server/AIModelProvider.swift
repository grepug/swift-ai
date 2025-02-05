import Foundation
import SwiftAI

actor AIModelProvider: Sendable {
    let models: [any AIModel]
    var index: Int = 0

    init(models: [any AIModel]) {
        self.models = models
    }

    func getModel() -> any AIModel {
        models[index]
    }

    func moveToNextModel() {
        index = (index + 1) % models.count
    }
}
