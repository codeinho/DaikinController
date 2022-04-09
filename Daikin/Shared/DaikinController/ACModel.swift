//
//  AC.swift
//  Daikin (iOS)
//
//  Created by Lothar Heinrich on 04.12.21.
//

import Foundation

struct ErrorMessage: Identifiable {
    var id: String { message }
    let message: String
}

final public class ACModel: ObservableObject, Identifiable {
    
    let acIP: String
    
    
    // init with the IP of the AC device
    public init(acIP: String, acName: String = "-") {
        self.acIP = acIP
        self.name = acName
    }
    
    
    
    // BasicInfo
    @Published var name = "-"
    
    // ControlInfo
    @Published var power = false
    @Published var mode = Mode(rawValue: 0)!
//    { didSet { print("mode was changed \(name) \(mode)")} }
    
    @Published var targetTemperature: Temperature = .unset
    @Published var fanRate = FanRate.unset
    @Published var fanDirection = FanDirection.stop
    @Published var specialModePowerful = false
    @Published var specialModeStreamer = false
    @Published var specialModeEcono = false
    
    @Published var outsideTemperature: Temperature = .unset
    @Published var insideTemperature: Temperature = .unset
    
    @Published var huminity: Float = 0.0; // Int?
    
    //
    @Published var basicInfo = Endpoint<BasicInfo>()
    @Published var controlInfo = Endpoint<ControlInfo>()
    @Published var sensorInfo = Endpoint<SensorInfo>()

    var temperatureRange: (Int, Int) {
        get {
            switch mode {
            case .auto0, .auto1, .auto7:
                return (18, 31)
            case .cooling:
                return (18, 33)
            case .heating:
                return (10, 31)
            case .dry, .fan:
                return (0, 0)
            }
        }
    }
    
    // UI
    @Published var userTemperature: Float = 0.0
    @Published var userStreamer = false
    var userFanrate: FanRate {
        get {
            if specialModePowerful || fanRate == .unset {
                return .unset
            }
            return fanRate
        }
    }
    
    @Published var errorMessage: ErrorMessage?
    
    var inputDisabled: Bool {
        get {
            return (controlInfo.state != .ready)
        }
    }
    
    var isPowerfulAllowed: Bool {
        get {
            if !power {
                return false
            }
            if specialModeEcono {
                return false
            }
            return true
        }
    }
   

    var isTargetTemperatureAllowed: Bool {
        get {
            switch mode {
            case .auto0, .auto1, .auto7, .cooling, .heating:
                return true
            default:
                return false
            }
        }
    }
    
    
    var nameForMode: String {
        get {
            if (specialModePowerful) {
                return "Powerful Cooling"
            }

            let mode = controlInfo.endpointData.mode

            return mode.description
        }
    }
    
    private func update(from: ControlInfo) {
        DispatchQueue.main.async {
            self.power = from.pow
            self.mode = from.mode
            self.fanRate = from.f_rate
            self.fanDirection = from.f_dir
            self.targetTemperature = from.stemp
            self.specialModeEcono = from.adv.contains("12")
            self.specialModeStreamer = from.adv.contains("13")
            self.specialModePowerful = (from.adv == "2" || from.adv == "2/13") // do not change to contains("2") since "12".contains("2"), which ist econ
            self.updateUserVariables()
        }
    }
    private func update(from: BasicInfo) {
        DispatchQueue.main.async {
            self.name = from.nameReadable
            UserSettings.shared.acNameCache[self.acIP] = self.name
        }
    }
    private func update(from: SensorInfo) {
        DispatchQueue.main.async {
            self.outsideTemperature = from.otemp
            self.insideTemperature = from.htemp
            self.huminity = from.hhum
        }
    }
    // mode=0,1,7 => mode=auto => 18<=t<=31 (lt. App nur 18-30)
    // mode = 3 = cold => 18<=t<=33 (lt. app nur bis 32)
    // mode = 4 = hot => 10<=t<=31 (lt. app 10-30)
    private func updateUserVariables() {
        userTemperature = targetTemperature.floatVal ?? 0.0
        userStreamer = specialModeStreamer
    }
    
    
    func test() {
        fetchControlInfo()
        print( self.controlInfo.endpointData.mode.rawValue)
//        print( self.controlInfo.endpointData.minimalDict(togglePower: false, forMode: "h") )
    }
    
    public func fetchData(force: Bool = false) {
        print("fetchData \(acIP)")
        errorMessage = nil
        fetchControlInfo()
        
        if basicInfo.endpointData.name == "" { //} basicInfo.state != .ready && !force {
            fetchBasicInfo()
        }
        
        if sensorInfo.state != .ready && !force {
            fetchSensorInfo()
        }
    }
    
    public func fetchBasicInfo() {
        Task.init {
            do {
                DispatchQueue.main.async {
                    self.basicInfo.state = .loading
                }
                let tmp = try await basicInfo.fetch(acIP: acIP)
                DispatchQueue.main.async {
                    self.basicInfo.endpointData = tmp
                    self.update(from: tmp)
                    self.basicInfo.state = .ready
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.basicInfo.state = .error(message: "Error: Could not read BasicInfo")
                }
                handleFetchError(error: error)
            }
        }
    }
        
    public func fetchControlInfo() {
        Task.init {
            do {
                DispatchQueue.main.async {
                    self.controlInfo.state = .loading
                }
                let tmp: ControlInfo = try await controlInfo.fetch(acIP: acIP)
                DispatchQueue.main.async {
                    self.controlInfo.endpointData = tmp
                    self.update(from: tmp)
                    self.controlInfo.state = .ready
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.controlInfo.state = .error(message: "Error: Could not read ControlInfo")
                }
                handleFetchError(error: error)
            }
        }
    }
    
    public func fetchSensorInfo() {
        Task.init {
            do {
                DispatchQueue.main.async {
                    self.sensorInfo.state = .loading
                }
                let tmp = try await sensorInfo.fetch(acIP: acIP)
                DispatchQueue.main.async {
                    self.sensorInfo.endpointData = tmp
                    self.update(from: tmp)
                    self.sensorInfo.state = .ready
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.sensorInfo.state = .error(message: "Error: Could not read ControlInfo")
                }
                handleFetchError(error: error)
            }
        }
    }
    
    private func checkReady() -> Bool {
        //if (basicInfo.state == .ready && controlInfo.state == .ready) {
        if (controlInfo.state == .ready) {
            return true
        }
        
        return false
    }
    
    private func handleFetchError(error: Error) {
        // Todo
        print("handleFetchError: \(error)")
        DispatchQueue.main.async {
            self.errorMessage = ErrorMessage(message: "Could not reach device")
        }
    }
    
//    public func sendUpdateAC(params: [String: String]) {
//
//        Task.init {
//            await sendUpdateAndWait(params: params)
//        }
//    }
    
    func togglePower() {
        Task.init {
            let minimalDictToggledPower = controlInfo.endpointData.minimalDict(togglePower: true)
            await sendUpdateAndWait(params: minimalDictToggledPower)
        }
    }
    func setFanRate(to: FanRate) {
        Task.init {
            if (specialModePowerful) {
                // if powerful is on, we need to turn it off first
                let specialModelEndpoint = Endpoint<SpecialMode>()
                let setPowerfulDict = specialModelEndpoint.endpointData.parmDictFor(powerfulOnOff: false)
                await sendUpdateSpecialAndWait(params: setPowerfulDict)
                if (controlInfo.state != .ready) {
                    print("cancel setFanRate(\(to) since not ready after turning powerful off")
                    return
                }
            }
            if (fanRate != to) {
                var minimalDict = controlInfo.endpointData.minimalDict()
                minimalDict["f_rate"] = to.toAC
                await sendUpdateAndWait(params: minimalDict)
            }
        }
    }
    
    func setFanDirection(to: FanDirection) {
        Task.init {
            var minimalDict = controlInfo.endpointData.minimalDict()
            minimalDict["f_dir"] = to.toAC
            await sendUpdateAndWait(params: minimalDict)
        }
    }
    
    func setMode(to: Mode) {
        Task.init {
            let minimalDict = controlInfo.endpointData.minimalDict(forNewMode: to)
            await sendUpdateAndWait(params: minimalDict)
        }
    }
    
    func setTargetTemperature(to: Temperature) {
        Task.init {
            var minimalDict = controlInfo.endpointData.minimalDict()
            minimalDict["stemp"] = to.toAC
            await sendUpdateAndWait(params: minimalDict)
        }
    }

    func setStreamer(to: Bool) {
        let specialModelEndpoint = Endpoint<SpecialMode>()
        let setStreamerDict = specialModelEndpoint.endpointData.parmDictFor(streamerOnOff: to)

        sendUpdateSpecial(params: setStreamerDict)
    }
    func setPowerful(to: Bool) {
        
        let specialModelEndpoint = Endpoint<SpecialMode>()
        let setPowerfulDict = specialModelEndpoint.endpointData.parmDictFor(powerfulOnOff: to)

        sendUpdateSpecial(params: setPowerfulDict)
    }
    
//    public func sendUpdateAndWait<T: EndpointProtocol>() -> T {
//
//    }
    
    public func sendUpdateAndWait(params: [String: String]) async {
        if (!checkReady()) {
            print("WARNING: tried to send updade to AC when not ready")
            return
        }
     
        do {
            DispatchQueue.main.sync {
                self.controlInfo.state = .loading
            }
            let _ = try await ControlInfo.doSet(acIP: acIP, params: params)
            let tmp: ControlInfo = try await controlInfo.fetch(acIP: acIP)
            DispatchQueue.main.sync {
                self.controlInfo.endpointData = tmp
                self.update(from: tmp)
                self.controlInfo.state = .ready
            }
            
        } catch {
            DispatchQueue.main.sync {
                self.controlInfo.state = .error(message: "Error: Could not set ControlInfo")
            }
            handleFetchError(error: error)
        }
    }
    public func sendUpdateSpecialAndWait(params: [String: String]) async {
        if (!checkReady()) {
            print("WARNING: tried to send updade to AC (special) when not ready")
            return
        }
     
        do {
            DispatchQueue.main.sync {
                self.controlInfo.state = .loading
            }
            let _ = try await SpecialMode.doSet(acIP: acIP, params: params)
            let tmp: ControlInfo = try await controlInfo.fetch(acIP: acIP)
            DispatchQueue.main.sync {
                self.controlInfo.endpointData = tmp
                self.update(from: tmp)
                self.controlInfo.state = .ready
            }
            
        } catch {
            DispatchQueue.main.sync {
                self.controlInfo.state = .error(message: "Error: Could not set ControlInfo")
            }
            handleFetchError(error: error)
        }
    }
    public func sendUpdateSpecial(params: [String: String]) {
        Task.init {
            await sendUpdateSpecialAndWait(params: params)
        }
    }
}


