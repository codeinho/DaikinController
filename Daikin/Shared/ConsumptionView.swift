//
//  ConsumptionView.swift
//  Daikin
//
//  Created by Lothar Heinrich on 15.04.22.
//

import SwiftUI

struct ConsumptionView: View {
    @EnvironmentObject var acModels: AcModelWrapper
    
    @StateObject var model = ConsumptionModel()
    
    var body: some View {
        VStack {
            HStack {
            Picker("", selection: $model.period) {
                ForEach (ConsumptionPeriod.allCases, id: \.self) { period in
                    Text("\(period.text)")
                        .tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.leading)
            .onChange(of: model.period, perform: { period in
                Task {
                    await readConsumption()
                }
            })
            Picker("", selection: $model.representation) {
                ForEach (ConsumptionRepresentation.allCases, id: \.self) { representation in
                        //Text("\(representation.text)")
                    modeIcon(representation: representation).tag(representation)
                }.background(Color.red)
            }
            .pickerStyle(.segmented)
            .padding(.trailing)
            }
            List {
                Section(header: listHeader) {
                              ForEach(model.consumption, id: \.id) { c in
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
                .headerProminence(.increased)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: tableBarItemPlacement()) {
                Text("Device")
                Picker("", selection: $model.showIP) {
                    ForEach (model.ipSelection, id: \.self) { acIP in
                        Text(acName(withIP:acIP))
                                .tag(acIP)
                    }
                }
                    }
                }
        .task {
            await readConsumption()
        }
    }
    func tableBarItemPlacement() -> ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
    }
    var listHeader: some View {
        HStack {
            VStack {
                Text(prevText).font(.footnote).foregroundColor(.gray)
                Text(model.sumPrevPeriod).foregroundColor(.gray)
            }
            Spacer()
            VStack {
                Text(currText).font(.footnote)
                Text(model.sumCurrPeriod)
            }
        }
    }
    var prevText: String {
        switch model.period {
        case .day:
            return "yesterday"
        case .week:
            return "last week"
        case .year:
            return "last year"
        }
    }
    var currText: String {
        switch model.period {
        case .day:
            return "today"
        case .week:
            return "this week"
        case .year:
            return "this year"
        }
    }
    func modeIcon(representation: ConsumptionRepresentation) -> some View {
        let systemName: String
        switch representation {
        case .heat:
            systemName = "flame" // sun.max"
        case .cool:
            systemName = "snowflake"
        case .sum:
            systemName = "sum"
        }
        
        return Image(systemName: systemName)
                    .foregroundColor(.coldBlue)
                    .tag(representation)
    }
    func readConsumption() async {
        do {
            try await model.fetch()
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
