//
//  DaikinConnection.swift
//  Daikin
//
//  Created by Lothar Heinrich on 23.12.21.
//

import Foundation
import SwiftUI

//class ConnectionSettings: ObservableObject {
//    var prefix: String
//    var timeoutIntervalForRequest: TimeInterval
//    init(prefix: String, timeoutIntervalForRequest: TimeInterval) {
//        self.prefix = prefix
//        self.timeoutIntervalForRequest = timeoutIntervalForRequest
//    }
//}


//struct ConnectionSettings {
//    var settings = UserSettings.shared
//    var prefix: String {
//        get { settings.prefix }
//    }
//    var timeoutIntervalForRequest: TimeInterval {
//        get { settings.timeoutIntervalForRequest }
//    }
//}
//
//var connectionSettings = ConnectionSettings()

enum DaikinConnectionError: Error {
    case status(message: String)
    case invalidUrl(message: String)
    case invalidResponse(message: String)
    case keyMissing(key: String, message: String = "")
    case invalidType(type: String, message: String = "")
}

public enum FetchState: Equatable {
    case beforeLoading
    case loading
    case error(message: String = "Error!")
    case ready
}

public protocol EndpointDataProtocol: Codable {
    
    static var endpoint_GET: String { get }
    static var endpoint_SET: String { get }
    
    static var responseTestString: String { get }
    
    var acData: [String: String] {get set}
    init()
    mutating func setRequiredAttribs() throws
}

public protocol EndpointProtocol {
    associatedtype T: EndpointDataProtocol
    var state: FetchState { get set }
    var endpointData: T { get set }
    func fetch(acIP: String) async throws -> T
}

public struct Endpoint<T> : EndpointProtocol where T: EndpointDataProtocol {
    public var state = FetchState.beforeLoading
    public var endpointData = T()
    
    public func fetch(acIP: String) async throws -> T {
        let fetchResult = try await T.fetch(acIP: acIP)
        return fetchResult
    }
}

fileprivate extension EndpointDataProtocol {
    static var httpPrefix: String {
        get {
            return UserSettings.shared.httpPrefix
        }
    }
    static func fallbackPrefixURL(acIP: String) -> String {
        if isInOurWifi(acIP: acIP) {
            return ""
        } else {
            return UserSettings.shared.fallbackPrefixURL
        }
    }
    static var timeoutIntervalForRequest: TimeInterval {
        get {
            return UserSettings.shared.timeoutIntervalForRequest
        }
    }
}
public extension EndpointDataProtocol {

    init(from responseString: String) throws {
        guard responseString.count > 0 else {
            throw DaikinConnectionError.invalidResponse(message: "responseString may not be empty")
        }
        let dict = responseStringToDict(responseString: responseString)

        self = Self()
        acData = dict
        try setRequiredAttribs()
    }
    fileprivate func getValue(key: String) -> String? {
        return acData[key]
    }
    fileprivate func stringValue(key: String) throws -> String {
        if let value = acData[key] {
            return value
        }
        throw DaikinConnectionError.keyMissing(key: key, message: "key missing or invalid format: \(key)")
    }
    fileprivate func intValue(key: String) throws -> Int {
        if let value = acData[key], let intVal = Int(value) {
            return intVal
        }
        throw DaikinConnectionError.keyMissing(key: key, message: "key missing or invalid format: \(key)")
    }
    fileprivate func doubleValue(key: String) throws -> Double {
        if let value = acData[key], let dblVal = Double(value) {
            return dblVal
        }
        throw DaikinConnectionError.keyMissing(key: key, message: "key missing or invalid format: \(key)")
    }
    fileprivate func floatValue(key: String) throws -> Float {
        if let value = acData[key], let floatVal = Float(value) {
            return floatVal
        }
        throw DaikinConnectionError.keyMissing(key: key, message: "key missing or invalid format: \(key)")
    }
    
    
    static func fetch(acIP: String, params: [String: String] = [:]) async throws -> Self {
        if (acIP == "TEST") {
            return try Self(from: Self.responseTestString)
        }
        
        let url = try buildUrl(acIP: acIP, params: params, endpoint: Self.endpoint_GET)
        
        return try await fetch(url: url, params: params)
    }
    
    fileprivate static func fetch(url: URL, params: [String: String] = [:]) async throws -> Self {
        
        let responseString = try await doGet(url: url, params: params)
        
        return try Self(from: responseString)
    }
    
    fileprivate static func doGet(url: URL, params: [String: String] = [:]) async throws -> String {
        
        let request = URLRequest(url: url)
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
        let session = URLSession(configuration: configuration)
        
        let (data, _) = try await session.data(for: request)
        
        let responseString = String(decoding: data, as: UTF8.self)
        
        guard responseString.hasPrefix("ret=OK") else {
            throw DaikinConnectionError.status(message: "invalid call to ac, response=\(responseString)")
        }
        return responseString
    }
    private static func buildUrl(acIP: String, params: [String: String], endpoint: String) throws -> URL {
        var localComponents = URLComponents()
        
        localComponents.scheme = httpPrefix
        localComponents.host = acIP
        localComponents.path = endpoint
        if !params.isEmpty {
            localComponents.queryItems = params.map{key,value in URLQueryItem(name: key, value: value)}
        }
        
        guard let localUrl = localComponents.url else {
            throw DaikinConnectionError.status(message: "couldn't build local URL")
        }
        

        let urlString: String
        let fallbackPrefix = fallbackPrefixURL(acIP: acIP)
        if fallbackPrefix.count > 0 { // check if fallback is set via settings AND not in same network
            guard let localUrlAsParameter = localUrl.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
                throw DaikinConnectionError.invalidUrl(message: "couldn't make parameter from local URL")
            }
            urlString = "\(fallbackPrefix)\(localUrlAsParameter)"
        } else {
            urlString = "\(localUrl.absoluteString)"
        }
        guard let url = URL(string: urlString) else {
            throw DaikinConnectionError.status(message: "couldn't build URL")
        }
        
        return url
    }
    /// updates the aircon
    static func doSet(acIP: String, params: [String: String], endpoint: String = endpoint_SET) async throws -> String {
        
        let url = try buildUrl(acIP: acIP, params: params, endpoint: endpoint)
        
        let request = URLRequest(url: url)
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
        let session = URLSession(configuration: configuration)
        
        let (data, _) = try await session.data(for: request)
        let responseString = String(decoding: data, as: UTF8.self)

        guard responseString.hasPrefix("ret=OK") else {
            throw DaikinConnectionError.status(message: "invalid call to ac, response=\(responseString)")
        }
        return responseString
    }

}


fileprivate func responseStringToDict(responseString: String) -> [String: String] {
    let responseArray = responseString.split(separator: ",") // ["ret=OK", "type=aircon", "reg=eu", ...]
   
    var responseDict = [String: String]()
    
    for keyValStr in responseArray {
        let keyVal = keyValStr.split(separator: "=") // "ret=OK" -> ["ret", "OK"]
         
        responseDict["" + keyVal[0]] =
            keyVal.count > 1 ? "" + keyVal[1] : "" // handles cases like "pw="
         
    }
    
    return responseDict
}

public struct BasicInfo: EndpointDataProtocol {
    
    public var acData = [String:String]()
    public static var endpoint_GET: String {
        get {
            return "/common/basic_info"
        }
    }
    public static var endpoint_SET: String {
        get {
            return "" // TODO
        }
    }
    
    public init() {}
    
    var nameReadable: String {
        return name.removingPercentEncoding ?? "-"
    }
        
    var type: String = ""
    // var reg: String = ""
    //var dst: Bool = false
    var ver: String = ""
    var pow: Bool = false
    // var location: Int = 0
    var name: String = ""
//    var icon: Int = 0
//    var method: String = ""
//    var port: Int = 0
//    var id: String = ""
//    var pw: String = ""
//    var lpw_flag: Int = 0
//    var pv: Double = 0.0
//    var cpv: Int = 0
//    var cpv_minor: Int = 0
//    var led: Int = 0
//    var en_setzone: Int = 0
//    var mac: String = ""
//    var adp_mode: String = ""
//    var err: Int = 0
//    var en_hol: Int = 0
//    var en_grp: Int = 0
//    var grp_name: String = ""
//    var adp_kind: Int = 0
    mutating public func setRequiredAttribs() {
        type = acData["type"]!
        ver = acData["ver"]!
        pow = acData["pow"] == "1"
        name = acData["name"]!
    }
    
    public static var responseTestString = "ret=OK,type=aircon,reg=eu,dst=1,ver=1_14_48,rev=84B684C,pow=0,err=0,location=0,name=%57%6f%68%6e%7a%69%6d%6d%65%72,icon=0,method=polling,port=30050,id=1234-1234-1234-1234-1234,pw=,lpw_flag=0,adp_kind=3,pv=3.30,cpv=3,cpv_minor=20,led=1,en_setzone=1,mac=C0E434E5F2D3,adp_mode=run,en_hol=0,ssid1=Wifi,radio1=-39,ssid=DaikinAP123,grp_name=,en_grp=0"

}

public struct ControlInfo: EndpointDataProtocol {
    public static var responseTestString = "ret=OK,pow=0,mode=4,adv=,stemp=25.0,shum=0,dt1=25.0,dt2=M,dt3=21.5,dt4=25.0,dt5=25.0,dt7=25.0,dh1=0,dh2=0,dh3=0,dh4=0,dh5=0,dh7=0,dhh=50,b_mode=4,b_stemp=25.0,b_shum=0,alert=255,f_rate=B,f_dir=0,b_f_rate=B,b_f_dir=0,dfr1=B,dfr2=3,dfr3=3,dfr4=B,dfr5=B,dfr6=5,dfr7=B,dfrh=5,dfd1=0,dfd2=0,dfd3=0,dfd4=0,dfd5=0,dfd6=0,dfd7=0,dfdh=0,dmnd_run=0,en_demand=0"
    
    
    public mutating func setRequiredAttribs() throws {
        pow = acData["pow"] == "1"
        mode = try Mode(value: acData["mode"] ?? "")
        stemp = try Temperature(value: acData["stemp"] ?? "")
        shum = try stringValue(key: "adv")
        f_rate = try FanRate(value: acData["f_rate"] ?? "")
        f_dir = try FanDirection(value: acData["f_dir"] ?? "")
        adv = try stringValue(key: "adv")
    }
    
    public var acData = [String:String]()
    
    public static var endpoint_GET: String {
        get {
            return "/aircon/get_control_info"
        }
    }
    public static var endpoint_SET: String {
        get {
            return "/aircon/set_control_info"
        }
    }
    
    public init() {}

    var pow: Bool = false
    var mode: Mode = Mode(rawValue: 0)!
    var stemp = try! Temperature(value: "0.0")
    var shum: String = ""
    var f_rate = FanRate.unset
    var f_dir = FanDirection.stop
    var adv: String = "" // Advanced/Special Mode
    // 1, 2, 3, 4, 5, 7 = for which mode
    // dt = target temperature
//    var dt1: Float = 0.0
//    var dt2: Float = 0.0
//    var dt3: Float = 0.0
//    var dt4: Float = 0.0
//    var dt5: Float = 0.0
//    var dt7: Float = 0.0
    // dh = target huminity
//    var dh1: Float = 0.0
//    var dh2: Float = 0.0
//    var dh3: Float = 0.0
//    var dh4: Float = 0.0
//    var dh5: Float = 0.0
//    var dh7: Float = 0.0
//    var dhh: Float = 0.0
    // fr = fan rate
//    var dfr1: String = ""
//    var dfr2: String = ""
//    var dfr3: String = ""
//    var dfr4: String = ""
//    var dfr5: String = ""
//    var dfr6: String = ""
//    var dfr7: String = ""
//    var dfrh: String = ""
    // fan direction
//    var dfd1: Int = 0
//    var dfd2: Int = 0
//    var dfd3: Int = 0
//    var dfd4: Int = 0
//    var dfd5: Int = 0
//    var dfd6: Int = 0
//    var dfd7: Int = 0
//    var dfdh: Int = 0
    
//    var b_mode: Int = 0
//    var b_stemp: Float = 0.0
//    var b_shum: Float = 0.0
//    var b_f_rate: String = ""
//    var b_f_dir: Int = 0
//    var alert: Int = 0
//

    func minimalDict(togglePower: Bool = false, forNewMode: Mode? = nil) -> [String:String] {
        let filterAttribs = ["pow", "mode", "stemp", "shum", "f_rate", "f_dir" ]
        var rv = acData.filter { filterAttribs.contains($0.key) }
        
        if let forNewMode = forNewMode {
            let modeStr = forNewMode.toAC
            rv["mode"] = modeStr
            if forNewMode == .fan {
                rv["stemp"] = "0"
            } else {
                rv["stemp"] = acData["dt\(modeStr)"]
            }
            rv["f_rate"] = acData["dfr\(modeStr)"]
            rv["f_dir"] = acData["dfd\(modeStr)"]
        }
        rv["shum"] = "0" // TODO: are there other values?
        
        if togglePower {
            rv["pow"] = (rv["pow"]! == "0") ? "1" : "0"
        }
        
        return rv
    }
    
}

public struct SensorInfo: EndpointDataProtocol {
    public static var responseTestString = "ret=OK,htemp=23.0,hhum=45,otemp=8.0,err=0,cmpfreq=0"
    var htemp = try! Temperature(value: "0.0")
    var hhum: Float = 0.0
    var otemp = try! Temperature(value: "0.0")
//    var err: Int = 0
//    var cmpfreq: Int = 0
    
    public mutating func setRequiredAttribs() throws {
        htemp = try Temperature(value: acData["htemp"]!)
        hhum = try floatValue(key: "hhum")
        otemp = try Temperature(value: acData["otemp"]!)
    }
    
    public var acData = [String:String]()
    
    public static var endpoint_GET: String {
        get {
            return "/aircon/get_sensor_info"
        }
    }
    public static var endpoint_SET: String {
        get {
            return "" // Daikin cannot set the outside temp unfortunately ;-)
        }
    }
    
    public init() {}

}
public struct SpecialMode: EndpointDataProtocol {
    public static var responseTestString = "ret=OK,adv=13"

    
    public mutating func setRequiredAttribs() throws {
    }
    
    public var acData = [String:String]()
    
    public static var endpoint_GET: String {
        get {
            return ""
        }
    }
    public static var endpoint_SET: String {
        get {
            return "/aircon/set_special_mode"
        }
    }
    
    public init() {}

    
    public func parmDictFor(streamerOnOff: Bool) -> [String: String] {
        var dict = [String: String]()
        dict["spmode_kind"] = "0" // spmode_kind='0' is streamer
        dict["en_streamer"] = streamerOnOff ? "1" : "0"
                 
        return dict
    }
    public func parmDictFor(powerfulOnOff: Bool) -> [String: String] {
        var dict = [String: String]()
        dict["spmode_kind"] = "1" // spmode_kind='1' is powerful
        dict["set_spmode"] = powerfulOnOff ? "1" : "0"
                 
        return dict
    }
 }

    





