//
//  ConsumptionView.swift
//  Daikin
//
//  Created by Lothar Heinrich on 15.04.22.
//

import SwiftUI

struct ConsumptionView: View {
    @EnvironmentObject var acModels: AcModelWrapper
    
    @StateObject var consumptionModel = ConsumptionModel()
    
    //@State var period = ConsumptionPeriod.year
    
    var body: some View {
        VStack {
            HStack {
                Picker("", selection: $consumptionModel.period) {
                    ForEach (ConsumptionPeriod.allCases, id: \.self) { period in
                        HStack {
                            Spacer() // bump text right
                            Text("\(period.text)")
                                .tag(period)
                                .font(.footnote)
                        }
                    }
                }
                .onChange(of: consumptionModel.period, perform: { period in
                    Task {
                        await readConsumption()
                    }
                })
                Picker("", selection: $consumptionModel.representation) {
                    ForEach (ConsumptionRepresentation.allCases, id: \.self) { representation in
                        HStack {
                            Spacer() // bump text right
                            Text("\(representation.text)")
                                .tag(representation)
                                .font(.footnote)
                        }
                    }
                }
                
                Picker("", selection: $consumptionModel.showIP) {
                    ForEach (consumptionModel.ipSelection, id: \.self) { acIP in
                        HStack {
                            Spacer() // bump text right
                            Text(acName(withIP:acIP))
                                .tag(acIP)
                                .font(.footnote)
                        }
                    }
                }
            }
            List(consumptionModel.consumption, id: \.id) { c in
                HStack {
                    Text("\(c.timespan)").monospacedDigit()
                    Spacer()
                    VStack {
                        Text("\(c.currValueKWh)").bold().monospacedDigit()
                        Text("\(c.prevValueKWh)").font(.footnote).monospacedDigit()
                            
                    }
                }
            }
        }
        .task {
            await readConsumption()
        }
    }
    
    func readConsumption() async {
        do {
            try await consumptionModel.fetch()
        } catch {
            print("error")
        }
        
    }
    
    func acName(withIP: String) -> String {
        if withIP == "ALL" {return "all"}
        return UserSettings.shared.acNameCache[withIP] ?? "-"
    }
}

struct ConsumptionView_Previews: PreviewProvider {
    static var previews: some View {
        ConsumptionView()
    }
}
