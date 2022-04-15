//
//  UserSettings.swift
//  Daikin
//
//  Created by Lothar Heinrich on 29.12.21.
//

import Foundation

import SwiftUI

enum StorageKeys: String {
    case colorScheme
    case acIPs
    case httpPrefix // http://
    case fallbackPrefixURL
    case timeoutIntervalForRequest
    case acNameCache
    case colorSchemeSetting
}

public let SETTINGS_DEMO_MODE = false // for screenshots etc.

fileprivate let notSetStr = "Not Set"
fileprivate let darkStr   = "dark"
fileprivate let lightStr  = "light"


/// UserSettings
///
class UserSettings: ObservableObject {
    static let appGroup = "group.de.snugdev.daikinwidget"
    
    private static let instance = UserSettings()
    private let userDefaults = UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
    
    static var shared: UserSettings {
        return instance
    }
    ///
    /// ip addresses of the aircons
    ///
    @Published var acIPs: [String] {
        didSet {
            userDefaults.set(acIPs, forKey: StorageKeys.acIPs.rawValue)
        }
    }
    ///
    /// names of the aircons - key=ip, value=name
    ///
    @Published var acNameCache: [String: String] {
        didSet {
            userDefaults.set(acNameCache, forKey: StorageKeys.acNameCache.rawValue)
        }
    }
    
    
    ///
    /// color scheme - light, dark or system
    ///
    @Published var colorSchemeSetting: String
    {
        didSet {
            userDefaults.set(colorSchemeSetting, forKey: StorageKeys.colorSchemeSetting.rawValue)
            colorScheme = ColorScheme.colorScheme(fromSettingsValue: colorSchemeSetting)
        }
    }
    
    @Published var colorScheme: ColorScheme?

    
    
    var acList: [Aircon] {
        get {
            return acIPs.map { Aircon(name: "\($0)", ip: $0) }
        }
    }
    
    static func getAcListForWidget() -> [Aircon]? {
        if SETTINGS_DEMO_MODE {
            return [Aircon(name: "Living Room", ip: "DEMO0"), Aircon(name: "Sleeping Room", ip: "DEMO1"), Aircon(name: "Kitchen", ip: "DEMO2")]
        }
        
        guard let settings = UserDefaults(suiteName: appGroup) else {
            print("Warning: Could not read settings from main app")
            return nil
        }
        
        let acIPs = settings.stringArray(forKey: StorageKeys.acIPs.rawValue) ?? []
        let acNameCache = settings.dictionary(forKey: StorageKeys.acNameCache.rawValue) as? [String:String] ?? [:]
        return acIPs.map {
            let ip = $0
            let name = acNameCache[ip] ?? "\(ip)"
            return Aircon(name: name, ip: ip)
        }
    }
    
    @Published var httpPrefix: String {
        didSet {
            userDefaults.set(httpPrefix, forKey: StorageKeys.httpPrefix.rawValue)
        }
    }
    @Published var fallbackPrefixURL: String {
        didSet {
            userDefaults.set(fallbackPrefixURL, forKey: StorageKeys.fallbackPrefixURL.rawValue)
        }
    }
   
    @Published var timeoutIntervalForRequest: TimeInterval {
        didSet {
            userDefaults.set(timeoutIntervalForRequest, forKey: StorageKeys.timeoutIntervalForRequest.rawValue)
        }
    }
    
    private init() {
        if (userDefaults == UserDefaults.standard) {
            print("Warning: could not craate settings for group, widgets might not work like expected")
        }
        
        self.acIPs = userDefaults.stringArray(forKey: StorageKeys.acIPs.rawValue) ?? []
        self.httpPrefix = userDefaults.string(forKey: StorageKeys.httpPrefix.rawValue) ?? "http"
        self.fallbackPrefixURL = userDefaults.string(forKey: StorageKeys.fallbackPrefixURL.rawValue) ?? ""
        
        let timeoutIntervalForRequest = userDefaults.double(forKey: StorageKeys.timeoutIntervalForRequest.rawValue)
        if timeoutIntervalForRequest == 0 {
            self.timeoutIntervalForRequest = 3.0
        } else {
            self.timeoutIntervalForRequest = timeoutIntervalForRequest
        }
        self.acNameCache = userDefaults.dictionary(forKey: StorageKeys.acNameCache.rawValue) as? [String:String] ?? [:]
        
        self.colorSchemeSetting = userDefaults.string(forKey: StorageKeys.colorSchemeSetting.rawValue) ?? notSetStr
        self.colorScheme = ColorScheme.colorScheme(fromSettingsValue: colorSchemeSetting) ?? nil
    }
}
    
    



extension ColorScheme {
    
    static func settingsValue(fromColorScheme: ColorScheme?) -> String {
        if let fromColorScheme = fromColorScheme {
            switch fromColorScheme {
            case .light:
                return lightStr
            case .dark:
                return darkStr
            default:
                return notSetStr
            }
        }
        return notSetStr
    }
    
    static func colorScheme(fromSettingsValue: String) -> ColorScheme? {
        switch fromSettingsValue {
            case darkStr: return .dark
            case lightStr: return .light
            default: return .none
        }
    }
}



struct Aircon: Identifiable {
    var id: String {
        get {
            return ip
        }
    }
    let name: String
    let ip: String
}

   
// "http://raspberrypi.9kxrmhooxp6bc7wd.myfritz.net:3001/daikinapi.php"
// "http://diskstation.9kxrmhooxp6bc7wd.myfritz.net:3001/daikinapi.php"

// http://diskstation.9kxrmhooxp6bc7wd.myfritz.net:3001/daikinapi.php?uri=%2Fcommon%2Fbasic_info&ip=192.168.188.59
