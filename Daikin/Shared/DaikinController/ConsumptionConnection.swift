//
//  ConsumptionConnection.swift
//  Daikin
//
//  Created by Lothar Heinrich on 15.04.22.
//

import Foundation

struct Consumption {
    /// curValCount:
    /// - year => 12
    /// - day => 12
    /// - week => days till monday; mo=>1, tu=>2, ..., su=>7
    var currValCount: Int
    var prevHeat: [Int]
    var prevCool: [Int]
    var currHeat: [Int]
    var currCool: [Int]
    
    static func sum(of: [Consumption]) -> Consumption? {
        if of.count == 0 { return nil }
        var sum = of[0]
        
        for i in (1..<of.count) {
            sum.prevHeat = zip(sum.prevHeat, of[i].prevHeat).map(+)
            sum.prevCool = zip(sum.prevCool, of[i].prevCool).map(+)
            sum.currHeat = zip(sum.currHeat, of[i].currHeat).map(+)
            sum.currCool = zip(sum.currCool, of[i].currCool).map(+)
        }
        
        return sum
    }
}


protocol ConsumptionReader {
    func read(acIP: String) async throws -> Consumption
}

struct ConsumptionWeek: EndpointDataProtocol, ConsumptionReader {
    
    var acData = [String:String]()
    static var endpoint_GET: String {
        get {
            return "/aircon/get_week_power_ex"
        }
    }
    static var endpoint_SET: String {
        get {
            return ""
        }
    }
    
    public init() {}
    
    var s_dayw: Int = 0
    var week_heat: [Int] = []
    var week_cool: [Int] = []
    
    
    public mutating func setRequiredAttribs() throws {
        s_dayw = try intValue(key: "s_dayw")
        week_heat = try intArray(key: "week_heat")
        week_cool = try intArray(key: "week_cool")
    }
    
    
    public static var responseTestString = "ret=OK,s_dayw=5,week_heat=0/0/0/0/0/0/0/0/0/0/0/0/0/0,week_cool=0/2/1/1/1/1/1/2/1/1/1/1/2/1"

    func read(acIP: String) async throws -> Consumption {
        let result = try await Self.fetch(acIP: acIP)

        let daysInCurrWeek = result.s_dayw == 0 ? 7 : result.s_dayw
        
        return Consumption( currValCount: daysInCurrWeek,
                            prevHeat: Array(result.week_heat[daysInCurrWeek..<daysInCurrWeek + 7]).reversed(),
                            prevCool: Array(result.week_cool[daysInCurrWeek..<daysInCurrWeek + 7]).reversed(),
                            currHeat: Array(result.week_heat.prefix(daysInCurrWeek).reversed()) + Array(repeating: 0, count: 7 - daysInCurrWeek),
                            currCool: Array(result.week_cool.prefix(daysInCurrWeek).reversed()) + Array(repeating: 0, count: 7 - daysInCurrWeek))
    }
}

struct ConsumptionDay: EndpointDataProtocol, ConsumptionReader {
    
    var acData = [String:String]()
    static var endpoint_GET: String {
        get {
            return "/aircon/get_day_power_ex"
        }
    }
    static var endpoint_SET: String {
        get {
            return ""
        }
    }
    
    public init() {}
    
    var prev_1day_heat: [Int] = []
    var prev_1day_cool: [Int] = []
    var curr_day_heat: [Int] = []
    var curr_day_cool: [Int] = []

    
    public mutating func setRequiredAttribs() throws {
        prev_1day_heat = try intArray(key: "prev_1day_heat")
        prev_1day_cool = try intArray(key: "prev_1day_cool")
        curr_day_heat = try intArray(key: "curr_day_heat")
        curr_day_cool = try intArray(key: "curr_day_cool")
    }
    
    
    public static var responseTestString = "ret=OK,curr_day_heat=0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0,prev_1day_heat=0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0,curr_day_cool=0/0/0/0/0/0/0/0/0/0/0/0/0/1/0/0/0/0/0/0/0/0/0/0,prev_1day_cool=0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/0/1/0/0/0/0/0/0"

    func read(acIP: String) async throws -> Consumption {
        let result = try await Self.fetch(acIP: acIP)

        return Consumption(currValCount: 12,
                           prevHeat: condensed2Hours(result.prev_1day_heat),
                           prevCool: condensed2Hours(result.prev_1day_cool),
                           currHeat: condensed2Hours(result.curr_day_heat),
                           currCool: condensed2Hours(result.curr_day_cool))
    }
    private func condensed2Hours(_ hours: [Int]) -> [Int] {
        var retVal = Array(repeating: 0, count: 12)
        for i in (0..<12) {
            retVal[i] = hours[i * 2] + hours[i * 2 + 1]
        }
        return retVal
    }
}

struct ConsumptionYear: EndpointDataProtocol, ConsumptionReader {
    
    var acData = [String:String]()
    static var endpoint_GET: String {
        get {
            return "/aircon/get_year_power_ex"
        }
    }
    static var endpoint_SET: String {
        get {
            return ""
        }
    }
    
    public init() {}
    
    var prev_year_heat: [Int] = []
    var prev_year_cool: [Int] = []
    var curr_year_heat: [Int] = []
    var curr_year_cool: [Int] = []

    
    public mutating func setRequiredAttribs() throws {
        prev_year_heat = try intArray(key: "prev_year_heat")
        prev_year_cool = try intArray(key: "prev_year_cool")
        curr_year_heat = try intArray(key: "curr_year_heat")
        curr_year_cool = try intArray(key: "curr_year_cool")
    }
    
    
    public static var responseTestString = "ret=OK,curr_year_heat=37/45/44/0/0/0/0/0/0/0/0/0,prev_year_heat=37/32/0/0/0/0/0/0/0/0/27/31,curr_year_cool=1/0/5/19/0/0/0/0/0/0/0/0,prev_year_cool=0/1/38/36/55/551/198/126/75/27/8/8"

    func read(acIP: String) async throws -> Consumption {
        let result = try await Self.fetch(acIP: acIP)

        return Consumption(currValCount: 12,
                           prevHeat: result.prev_year_heat,
                           prevCool: result.prev_year_cool,
                           currHeat: result.curr_year_heat,
                           currCool: result.curr_year_cool)
    }
}

func consumptionReader(forPeriod: ConsumptionPeriod) -> ConsumptionReader {
    switch forPeriod {
    case .day:
        return ConsumptionDay()
    case .week:
        return ConsumptionWeek()
    case .year:
        return ConsumptionYear()
    }
}
