//
//  ACView.swift
//  Daikin (iOS)
//
//  Created by Lothar Heinrich on 04.12.21.
//

import SwiftUI

let headerHight: CGFloat = 35


struct ACView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject var acModel: ACModel
    
    init(acIP: String, acName: String = "-") {
        self.init(acModel: ACModel(acIP: acIP, acName: acName))
    }
    
    // in case we are coming from ACList, the data for the model is already fetched
    init(acModel: ACModel) {
        _acModel = StateObject(wrappedValue: acModel)
    }
    
    var lightGray: Color {
        get {
            systemGray6(colorScheme: colorScheme)
        }
    }
    
    
    var body: some View {
        ScrollView {
        
            VStack {
                    
                HStack {
                    Text("\(acModel.name)")
                        .font(.title)
                    Button(action: togglePower) {
                        Image(systemName: "power.circle.fill")
                            //.imageScale(.large)
                            .resizable()
                            .scaledToFit()
                            .frame(height:35)
                    }
                    .buttonStyle(PowerButtonStyle(isOn: acModel.power))
                }
                HStack {
                    Spacer()
                    Label(acModel.insideTemperature.celsius, systemImage: "thermometer")
                    Spacer()
                    Label("\(Int(acModel.huminity))%", systemImage: "humidity.fill")
                    Spacer()
                    HStack { // outside temp
                        Image(systemName: "house")
                            .padding(0).zIndex(1)
                        Image(systemName: "thermometer")
                            .padding(.horizontal, -10)
                        Text("\(acModel.outsideTemperature.celsius)")
                    }
                    Spacer()
                }
                
                
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "thermometer")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight:headerHight)
                            .foregroundColor(Color.gray)
                            
                        Image(systemName: "slider.horizontal.3")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight:headerHight * 0.75)
                            .foregroundColor(Color.gray)
                            
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(lightGray)
            
                    HStack {
                        Text("Automatic: ").foregroundColor(Color.gray)
                        buttonFor(mode: .auto1)
                    }
                    HStack { // Mode
                        buttonFor(mode: .cooling)
                            .padding(.leading)
                        Spacer()
                        buttonFor(mode: .heating)
                        Spacer()
                        buttonFor(mode: .fan)
                        Spacer()
                        buttonFor(mode: .dry)
                            .padding(.trailing)

                    }
                    .frame(maxWidth: 500)
                    .padding(.horizontal,10)
                    temperatureSetter(acModel: acModel)
                        .padding(.bottom, 4)
                        .frame(maxWidth: 200)
                        .disabled(acModel.inputDisabled || !acModel.isTargetTemperatureAllowed)
                        .visibility(acModel.isTargetTemperatureAllowed ? .visible : .invisible)
                    
                }
                .border(Color.gray, width: 2)
                .padding(.horizontal, 3)
                .disabled(acModel.inputDisabled)
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "fanblades")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight:headerHight)
                            .foregroundColor(Color.gray)
                            
                        Image(systemName: "chart.bar")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight:headerHight)
                            .foregroundColor(Color.gray)
                            
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(lightGray)
                    
                    HStack {
                        Text("Automatic: ").foregroundColor(Color.gray)
                        buttonFor(fanRate: .auto)
                    }
                    HStack { // Fan Rate
                        Group {
                            buttonFor(fanRate: .silent)
                            Spacer()
                            buttonFor(fanRate: .level1)
                            Spacer()
                            buttonFor(fanRate: .level2)
                            Spacer()
                        }
                        buttonFor(fanRate: .level3)
                        Spacer()
                        buttonFor(fanRate: .level4)
                        Spacer()
                        buttonFor(fanRate: .level5)
                        Spacer()
                        Button(action: { acModel.setPowerful(to: true) }) {
                            Image(systemName: "tornado")
                                .resizable()
                                .scaledToFit()
                                .frame(height:35)
                        }
                        .buttonStyle(SelectableButtonStyle(isSelected: acModel.specialModePowerful))
                        .disabled(!acModel.isPowerfulAllowed)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                .disabled(acModel.inputDisabled)
                .border(Color.gray, width: 2)
                .padding(.horizontal, 3)
                
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "fanblades")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight:headerHight)
                            .foregroundColor(Color.gray)
                            
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight:headerHight)
                            .foregroundColor(Color.gray)
                            
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(lightGray)
                    
                    HStack {
                        buttonFor(fanDirection: .stop)
                        Spacer()
                        buttonFor(fanDirection: .both)
                        Spacer()
                        buttonFor(fanDirection: .horizontal)
                        Spacer()
                        buttonFor(fanDirection: .vertical)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                }
                .disabled(acModel.inputDisabled)
                .border(Color.gray, width: 2)
                .padding(.horizontal, 3)
               
                
                
                
                VStack {
                    Image(systemName: "facemask")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight:headerHight)
                        .padding(10)
                        .foregroundColor(Color.gray)
                        .background(lightGray)
                    HStack {
                        Toggle(isOn: $acModel.userStreamer) {
    //                      Image(systemName: "allergens")
                          Text("Streamer Mode")
                        }
                        .foregroundColor(Color.gray)
                        .onChange(of: acModel.userStreamer, perform: {streamerState in
                            acModel.setStreamer(to: streamerState)
                        })
                        
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 15)
                }
                .disabled(acModel.inputDisabled)
                .border(Color.gray, width: 2)
                .padding(.horizontal, 3)
                .buttonStyle(NormalButtonStyle())
                
                // Text("\(String(describing: acModel.controlInfo.state))")
            }
           

        }
        .alert(item: $acModel.errorMessage) { errorMessage in
            Alert(title: Text("Error"), message: Text(errorMessage.message), primaryButton: .default(Text("retry"), action: {readAC()}), secondaryButton: .cancel())
        }
        .onAppear {
            print("ACView.onAppear")
            if acModel.controlInfo.state != .ready && acModel.controlInfo.state != .loading {
                readAC()
            }
        }
    }

    func buttonFor(mode: Mode) -> some View {
        Button(action: { updateMode(to: mode) }) {
            Image(systemName: mode.iconName)
//                                .imageScale(.large)
                .resizable()
                .scaledToFit()
                .frame(width: 35, height:35)
        }
        .buttonStyle(SelectableButtonStyle(isSelected: acModel.mode == mode))
    }
    
    func buttonFor(fanRate: FanRate) -> some View {
        Button(action: { updateFanRate(to: fanRate) }) {
            Image(systemName: fanRate.iconName)
    //                                .imageScale(.large)
                .resizable()
                .scaledToFit()
                .frame(width: 35, height:35)
        }
        //        .buttonStyle(SelectableButtonStyle(isSelected: acModel.fanRate == fanRate))
        .buttonStyle(SelectableButtonStyle(isSelected: acModel.userFanrate == fanRate))
        
    }
    func buttonFor(fanDirection: FanDirection) -> some View {
        Button(action: { updateFanDirection(to: fanDirection) }) {
            Image(systemName: fanDirection.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 35, height:35)
        }
        .buttonStyle(SelectableButtonStyle(isSelected: acModel.fanDirection == fanDirection))
    }
    
    func readAC() {
        acModel.fetchControlInfo()
    }
    func togglePower() {
        if acModel.inputDisabled {return}
        acModel.togglePower()
    }
    func test() {
        acModel.test()
    }
    func updateFanRate(to: FanRate) {
        acModel.setFanRate(to: to)
    }
    func updateFanDirection(to: FanDirection) {
        acModel.setFanDirection(to: to)
    }
    
    func updateMode(to: Mode) {
        acModel.setMode(to: to)
    }
    func updateTemp(acModel: ACModel, diff: Float) {
        if let floatTemp = acModel.targetTemperature.floatVal {
            let to = floatTemp + diff
            let toTemp = Temperature(from: to)
            acModel.setTargetTemperature(to: toTemp)
        }
    }
    
    func temperatureSetter(acModel: ACModel) -> some View {
        
        HStack {
            Button(action: {updateTemp(acModel: acModel, diff: -1.0)}) {
                Image(systemName: "minus") //"chevron.down.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width:15, height: 15)
            }
//            .buttonStyle(NormalButtonStyle())
            .buttonStyle(.bordered)
            
            Picker("", selection: $acModel.userTemperature) {
                ForEach (temperatureRange, id: \.self) { temp in
                    HStack {
                        Spacer() // bump text right
                        Text("\(temp.celsius)")
                            .tag(temp)
                            .font(.footnote)
                    }
                }
            }
            .onChange(of: acModel.userTemperature, perform: { ut in
                let userTemp = Temperature(from: ut)
                guard userTemp != acModel.targetTemperature else {
                    return
                }
                acModel.setTargetTemperature(to: userTemp)
            })
            Button(action: {updateTemp(acModel: acModel, diff: 1.0)}) {
                Image(systemName: "plus")//"chevron.up.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height:15)
            }
//            .buttonStyle(NormalButtonStyle())
            .buttonStyle(.bordered)

            
        }
        .background(colorForMode.opacity(0.1))
        .background(lightGray)
        .overlay(RoundedRectangle(cornerRadius: 5)
                    .stroke(colorForMode, lineWidth: 1))
    }
    var colorForMode: Color {
        
        if acModel.mode == .cooling {
            return .coldBlue
        }
        
        if acModel.mode == .heating {
            return .warmRed
        }
        
        switch acModel.mode {
        case .auto0, .auto1, .auto7:
            if acModel.insideTemperature == .unset || acModel.targetTemperature == .unset {
                return .clear
            }
            if acModel.insideTemperature < acModel.targetTemperature {
                return Color.warmRed
            } else {
                return Color.coldBlue
            }
        default:
            return .clear
        }
        
    }
    var temperatureRange: [Float] {
        get {
            let (from, to) = acModel.temperatureRange
            return tempRange(from: from, to: to)
        }
    }
}

/*
 [3, 4, 5] -> [3.0, 3.5, 4.0, 4.5, 5.0, 5.5]
 */
func tempRange(from: Int, to: Int) -> [Float] {
    let intArr = (0...(to - from) * 2)  // [3, 4, 5] -> [0, 1, 2, 3, 4, 5, 6]
    let floatArr = intArr.map { Float($0) / 2.0 + Float(from)} // ... -> [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0] + from
    return floatArr
}



struct ACView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ACView(acIP: "TEST")
                .preferredColorScheme(.light)
            ACView(acIP: "TEST")
                .preferredColorScheme(.dark)
        }
    }
}


struct NormalButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            
            .foregroundColor(!isEnabled ? .gray : configuration.isPressed ? .cyan : .blue)
            
            .font(Font.body.bold())
            .padding(5)
//            .padding(.horizontal, 20)
//            .background(isEnabled ? Color.blue : Color.gray)
            .cornerRadius(5)
    }
}

struct PowerButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    let isOn: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .cyan : isOn ? .green : .gray)
            //.cornerRadius(10)
    }
}


struct SelectableButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.isEnabled) var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(!isEnabled ? .gray : isSelected ? .orange : configuration.isPressed ? .cyan : .blue)
            //.foregroundColor(isSelected ? .primary : Color.primary.colorInvert() as? Color)
            // .background(Color.primary.colorInvert())
            .font(Font.body.bold())
            //.background(isEnabled ? Color.blue : Color.gray)
            //.cornerRadius(5)
    }
}

extension Mode {
    var iconName: String {
        get {
            switch (self) {
            case .dry:
                return "humidity.fill"
            case .cooling:
                return "snowflake"  // "thermometer.snowflake"
            case .heating:
                return "flame" // "thermometer.sun" // "sun.max"
            case .fan:
                return "wind" // "fanblades"
            case .auto0, .auto1, .auto7:
                return "a.circle"
            }
        }
    }
}


extension FanRate {
    var iconName: String {
        get {
            switch (self) {
            case .auto:
                return "a.circle"
            case .silent:
                return "leaf"
            case .level1:
                return "1.circle"
            case .level2:
                return "2.circle"
            case .level3:
                return "3.circle"
            case .level4:
                return "4.circle"
            case .level5:
                return "5.circle"
            default:
                return "exclamationmark.circle.fill"
            }
        }
    }
}

extension FanDirection {
    var iconName: String {
        get {
            switch (self) {
            case .stop:
                return "xmark.circle"
            case .vertical:
                return "arrow.left.and.right"
            case .horizontal:
                return "arrow.up.and.down"
            case .both:
                return "arrow.up.and.down.and.arrow.left.and.right"
            }

        }
    }
}




