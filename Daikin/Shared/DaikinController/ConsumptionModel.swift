//
//  ConsumptionModel.swift
//  Daikin
//
//  Created by Lothar Heinrich on 15.04.22.
//

import Foundation

enum ConsumptionPeriod: Int, CaseIterable, Identifiable {
    case day
    case week
    case year
    
    var id: Int { self.rawValue }
    
    var text: String {
        get {
            switch self {
            case .day: return "Day"
            case .week: return "Week"
            case .year: return "Year"
            }
        }
    }
}

enum ConsumptionRepresentation: Int, CaseIterable, Identifiable {
    case heat
    case cool
    case sum
    
    var id: Int { self.rawValue }
    
    var text: String {
        get {
            switch self {
            case .heat: return "Heat"
            case .cool: return "Cool"
            case .sum: return "Sum"
            }
        }
    }
}

struct ConsumptionValue {
    let id = UUID()
    let timespan: String
    let prevValue: Double
    let currValue: Double?
    
    var prevValueKWh: String {
        get {
            format(kWh: self.prevValue)
        }
    }
    var currValueKWh: String {
        get {
            format(kWh: self.currValue)
        }
    }
}

fileprivate func format(kWh: Double?) -> String {
    if let kWh = kWh {
        return "\(String(format: "%.1f", kWh)) kWh"
    }
    return "-"
}

// the Model used by the view
final class ConsumptionModel: ObservableObject {
    
    @Published private(set) var allIPs: [String] = []
    @Published var showIP = "ALL" {      // default: show all
        didSet {
            Task {
                try await fetch()
            }
        }
    }
    var ipSelection: [String] {
        get {
           return ["ALL"] + allIPs
        }
    }
    @Published private(set) var currValCount = 0 // e.g. 7 on sundays, since we have 7 values from mo-su, 2 on tuesday (mo+tu)
    @Published private(set) var prevHeat: [Double] = []
    @Published private(set) var prevCool: [Double] = []
    @Published private(set) var currHeat: [Double] = []
    @Published private(set) var currCool: [Double] = []

    @Published var period = ConsumptionPeriod.day
    @Published var representation = ConsumptionRepresentation.sum {
        didSet {
          updateConsumptionArray()
        }
      }
    
    @Published private(set) var consumption: [ConsumptionValue] = []
    var sumPrevPeriod: String {
        get {
            return format(kWh: consumption.reduce(0, { $0 + $1.prevValue}))
        }
    }
    var sumCurrPeriod: String {
        get {
            return format(kWh: consumption.reduce(0, { $0 + ($1.currValue ?? 0) }))
        }
    }
    init() {
        for acIP in UserSettings.shared.acIPs {
            allIPs.append(acIP)
        }
    }

    @discardableResult
    func fetch() async throws -> Consumption {
        var results = [Consumption]()
        let showIPs = showIP == "ALL" ? allIPs : [showIP]
        try await withThrowingTaskGroup(of: Consumption.self) { group in
                for acIP in showIPs {
                    group.addTask {
                        let consumptionReader = consumptionReader(forPeriod: self.period)
                        let result = try await consumptionReader.read(acIP: acIP)
                        return result
                    }
                }
            for try await r in group {
                results.append(r)
            }
        }
        let resultSum = Consumption.sum(of: results)!
        DispatchQueue.main.async { [self] in
            updateFrom(consumption: resultSum)
        }
        
        return resultSum
    }
    
    private func updateFrom(consumption: Consumption) {
        self.currValCount = consumption.currValCount
        self.prevHeat = consumption.prevHeat.asKWhArray
        self.prevCool = consumption.prevCool.asKWhArray
        self.currHeat = consumption.currHeat.asKWhArray
        self.currCool = consumption.currCool.asKWhArray
        updateConsumptionArray()
    }
    
    private func updateConsumptionArray() {
        switch representation {
        case .heat:
            updateConsumptionArray(prev: prevHeat, curr: currHeat)
        case .cool:
            updateConsumptionArray(prev: prevCool, curr: currCool)
        case .sum:
            let prevSum = zip(prevCool, prevHeat).map( { $0 + $1 } )
            let currSum = zip(currCool, currHeat).map( { $0 + $1 } )
            updateConsumptionArray(prev: prevSum, curr: currSum)
        }
    }
    
    private func updateConsumptionArray(prev: [Double], curr: [Double]) {
        var idx = 0
        consumption = zip(prev, curr).map( {
            let timespan = timespan(fromIndex: idx)
            let currValue: Double? = idx < self.currValCount ? $1 : nil
            idx += 1
            return ConsumptionValue(timespan: timespan, prevValue: $0, currValue: currValue)
        } )
    }
                              
    private func timespan(fromIndex: Int) -> String {
        return timespanText[period]![fromIndex]
    }
    
    private var timespanText: [ConsumptionPeriod: [String]] = [
        .day: (0...11).map {"\(String(format: "%02d", $0 * 2) ):00 - \(String(format: "%02d", $0 * 2 + 2)):00"},
        .week: [1,2,3,4,5,6,0].map {DateFormatter().weekdaySymbols[$0]},
        .year: (0...11).map {DateFormatter().monthSymbols[$0] },
    ]
}

extension Array where Element == Int {
    var asKWhArray: [Double] {
        get {
            self.map( { Double($0) / 10 } )
        }
    }
}
