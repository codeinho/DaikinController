//
//  DaikinTypes.swift
//  Daikin
//
//  Created by Lothar Heinrich on 01.01.22.
//

import Foundation

enum DaikinAttribError: Error {
    case invalidValue(value: String, message: String = "")
}

protocol DaikinAttrib: Codable, CustomStringConvertible, Equatable {
    init(value: String) throws
    var toAC: String {
        get
    }
}

enum Mode: Int, DaikinAttrib, CaseIterable, Identifiable {
    case auto0 = 0
    case auto1 = 1
    case dry = 2
    case cooling = 3
    case heating = 4
    case fan = 6
    case auto7 = 7
    
    init(value: String) throws {
        if let intVal = Int(value), let mode = Mode(rawValue: intVal) {
            self = mode
        } else {
            throw DaikinAttribError.invalidValue(value: value, message: "Cannot map to mode from \(value)")
        }
    }
    
    var id: Int { self.rawValue }
    
    var toAC: String {
        get {
            "\(rawValue)"
        }
    }
    
    var description: String {
        get {
            switch (self) {
            case .auto0, .auto1, .auto7:
                return "Auto"
            case .dry:
                return "Dry"
            case .cooling:
                return "Cooling"
            case .heating:
                return "Heating"
            case .fan:
                return "Fan"
            }
            
        }
    }
    static let allSelectable = [Mode.auto1, Mode.cooling, Mode.heating, Mode.fan, Mode.dry]
    
    var isTemperatureMode: Bool {
        get {
            switch (self) {
            case .auto0, .auto1, .auto7, .heating, .cooling:
                return true
            default:
                return false
            }
        }
    }
}


enum FanRate: Int, DaikinAttrib, CaseIterable, Identifiable {
    
    case unset = 0
    case auto
    case silent
    case level1
    case level2
    case level3
    case level4
    case level5
    
    var toAC: String {
        get {
            switch self {
            case .unset:
                return ""
            case .auto:
                return "A"
            case .silent:
                return "B"
            default:
                return "\(rawValue)"
            }
        }
    }
    var description: String {
        get {
            let val = toAC
            return val == "" ? "-" : val
        }
    }
    var id: String { self.toAC }
    private static let inputMapping = ["", "A", "B", "3", "4", "5", "6", "7"]
    init(value: String) throws {
        if let index = FanRate.inputMapping.firstIndex(of: value) {
            self = FanRate(rawValue: index)!
        } else {
            throw DaikinAttribError.invalidValue(value: value)
        }
    }
    static let allSelectable: [FanRate] = [.auto, .silent, .level1, .level2, .level3, .level4, .level5]
    
}

enum FanDirection: Int, DaikinAttrib, CaseIterable, Identifiable {
    
    case stop = 0
    case vertical = 1
    case horizontal = 2
    case both = 3
    
    var toAC: String {
        get {
            return String(rawValue)
        }
    }
    var description: String {
        get {
            return toAC
        }
    }
    var id: Int { rawValue }
    init(value: String) throws {
        if let intVal = Int(value), 0 <= intVal, intVal <= 3 {
            self.init(rawValue: intVal)!
        } else {
            throw DaikinAttribError.invalidValue(value: value)
        }
    }
}


extension Float: Identifiable {
    public var id: Float {
        return self
    }
    
    var celsius: String {
        get {
            return "\(self) ℃"
        }
    }
}

struct Temperature: DaikinAttrib, Comparable {
    let floatVal: Float?
    let alternativeValue: String?
    
    init(value: String) throws {
        // valid is a float or "M" (for mode fan)
        if let f = Float(value) {
            floatVal = f
            alternativeValue = nil
        } else {
            guard value == "M" || value == "--" else {
                throw DaikinAttribError.invalidValue(value: value, message: "invalid value for Temperatur: \(value)")
            }
            floatVal = nil
            alternativeValue = value
        }
    }
    init(from: Float) {
        floatVal = from
        alternativeValue = nil
    }
    
    var toAC: String {
        get {
            if let f = floatVal {
                return String(format: "%.1f", f)
            }
            if let alternativeValue = alternativeValue {
                return alternativeValue
            }
            return "" // can never happen
        }
    }
    var description: String {
        get {
            return toAC
        }
    }
    var celsius: String {
        if let floatVal = floatVal {
            return floatVal.celsius
        } else {
            return "- ℃"
        }
    }
    static let unset = try! Temperature(value: "--")
    
    static func < (lhs: Temperature, rhs: Temperature) -> Bool {
        if let lhsFloatVal = lhs.floatVal {
            guard let rhsFloatVal = rhs.floatVal else {
                return false // lhs is float, rhs not a float -> consider lhs greater
            }
            return lhsFloatVal < rhsFloatVal // both floats
        }
        
        return false
    }
}
