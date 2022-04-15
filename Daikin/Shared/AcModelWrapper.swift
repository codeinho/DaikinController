//
//  AcModelWrapper.swift
//  Daikin
//
//  Created by Lothar Heinrich on 26.01.22.
//

import Foundation
import Combine


// from https://stackoverflow.com/questions/69033796/swiftui-create-class-with-array-property-witch-conform-to-observableobject
class AcModelWrapper: ObservableObject {
    @Published var acModels: [ACModel]
    let settings = UserSettings.shared
    
//    init(acModels: [ACModel]) {
//        self.acModels = acModels
//        subscribeToChanges()
//    }
    
    init(demoMode: Bool = false) {
        // get ip addresses from settings and create array of models
        if demoMode {
            self.acModels = [ACModel(acIP: "DEMO0"), ACModel(acIP: "DEMO1"), ACModel(acIP: "DEMO2")]
        } else {
            self.acModels = settings.acList.map{ ACModel(acIP: $0.ip, acName: $0.name) }
        }
        subscribeToChanges()
    }
    
    private var anyCancellables = Set<AnyCancellable>()
    
    func subscribeToChanges() {
        acModels
            .publisher
            .flatMap { m in m.objectWillChange }
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &anyCancellables)
    }
    
    func reloadAll() {
        print("AcModelWrapper.reloadAll()")
        self.acModels.removeAll()
        self.acModels.append(contentsOf: settings.acList.map{ ACModel(acIP: $0.ip, acName: $0.name) })
        for acModel in acModels {
            acModel.fetchData()
        }
        subscribeToChanges()
    }
}
