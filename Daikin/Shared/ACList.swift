//
//  ACList.swift
//  Daikin
//
//  Created by Lothar Heinrich on 26.12.21.
//

import SwiftUI
import WidgetKit

//#if os(macOS)
//let linkMinWidth = 50.0
//#else
//let linkMinWidth = 0.0
//#endif


struct ACList: View {
    @Environment(\.colorScheme) var colorScheme
    
//    @EnvironmentObject var settings: UserSettings
        
//    @StateObject var acModels = AcModelWrapper()
    @EnvironmentObject var acModels: AcModelWrapper
    
    // @State var errorMessage: String?
    @State private var selectedAC: String?
    
    init() {
//        settings = UserSettings()
//        AcModelWrapper(acModels: settings.acList.map{ ACModel(acIP: $0.ip, acName: $0.name) })
//        _acModels = StateObject(wrappedValue: AcModelWrapper(acModels: settings.acList.map{ ACModel(acIP: $0.ip, acName: $0.name) }))
       
    }
    init(selectedAirconIP: String?) {
        if let selectedAirconIP = selectedAirconIP {
            _selectedAC = State(initialValue: selectedAirconIP)
        }
    }
    var lightGray: Color {
        get {
            systemGray6(colorScheme: colorScheme)
        }
    }
    var body: some View {
        VStack {
            makeHeader()
            .frame(height:20)
            .foregroundColor(Color(.gray))
            
            List {
                ForEach(acModels.acModels) { acModel in
                    NavigationLink(destination: ACView(acModel: acModel), tag: acModel.acIP, selection: $selectedAC) {
                        HStack { //}(spacing: 2) {
                            VStack(alignment: .leading) {
                                Text(acModel.name)
                                    .font(.title2).bold()
                                    .addErrorBadge(acModel.controlInfo.state == FetchState.error())
                                HStack {
                                    makeRoomTemp(acModel: acModel).padding(.trailing)
                                    makeMode(acModel: acModel)
                                }
                            
                            }
                            .foregroundColor(Color(.gray))
                            Spacer()//.frame(minWidth: 0, idealWidth: 0, maxWidth: 0).padding(.leading,5) // push buttons to right
//                            if acModel.controlInfo.state == .ready {
//                                makeButton(acModel: acModel)
//                            } else {
//                                makeProgressView(acModel: acModel)
//                            }
                            switch acModel.controlInfo.state {
                           case .beforeLoading, .loading:
                               makeProgressView(acModel: acModel)
                           case .ready:
                               makeButton(acModel: acModel)
                           case .error:
                               Image(systemName: "exclamationmark.triangle")
                           }
                        }
                    }
//                    .frame(minWidth: linkMinWidth)
                }
                VStack {
                    Text(firstErrorMessage ?? "-")
                    Text("Pull down to retry.")
                }
                .visibility(firstErrorMessage == nil ? ViewVisibility.gone : .visible)
                .foregroundColor(Color(.red))

            }
            .refreshable {
                readACs() // TODO: should be an awaited operation
            }
            
            
        }
        .onAppear{
            readACs()
            WidgetCenter.shared.reloadTimelines(ofKind: "Widget_iOS")
        }
        .onOpenURL { url in
            print("Received deep link: \(url)")
            if let selectAirconIP = url.airconIP {
                selectedAC = selectAirconIP
            }
        }
    }

    func makeHeader() -> some View {
        HStack {
            Spacer()
            Image(systemName: "house")
                .resizable()
                .scaledToFit()
                .padding(0).zIndex(1)
            Image(systemName: "thermometer")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, -8)
            Text("\(acModels.acModels.first?.outsideTemperature.description ?? "--") ℃").font(.title3)
            Spacer()
        }
    }
    
    func makeButton(acModel: ACModel) -> some View {
            
        Button(action: { togglePower(acModel: acModel) } ) {
                Image(systemName: "power.circle.fill")
                    .resizable()
                    .scaledToFit()
        }
        .buttonStyle(PowerButtonStyle(isOn: acModel.power))
        .frame(height:40)
        .padding(.horizontal, 10)
    }
    func makeProgressView(acModel: ACModel) -> some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .black))
            .frame(height:40)
            .padding(.horizontal, 10)
    }
    
    func makeRoomTemp(acModel: ACModel) -> some View {
        Text("\(acModel.insideTemperature.description) ℃")
    }
    func makeMode(acModel: ACModel) -> some View {
        HStack {
            if acModel.controlInfo.state == .ready {
                Group {
                    Image(systemName: acModel.mode.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(height:20)
                    if acModel.mode.isTemperatureMode {
                        Image(systemName: "arrow.right")
                        .resizable()
                        .scaledToFit()
                        .frame(height:10)
                        .zIndex(-1)
                        .padding(.leading, -5)
                        Text(acModel.targetTemperature.celsius)
                    }
                }
                .foregroundColor(colorForMode(acModel: acModel))
            } else {
                Image(systemName: "hourglass")
                .resizable()
                .scaledToFit()
                .frame(height:20)
            }
        }
    }
    func colorForMode(acModel: ACModel) -> Color {
        
        if acModel.mode == .cooling {
            return .coldBlue
        }
        
        if acModel.mode == .heating {
            return .warmRed
        }
        return .gray
    }
    var firstErrorMessage: String? {
        get {
            for acModel in acModels.acModels {
                switch (acModel.controlInfo.state) {
                case .error(let message):
                    return message
                default:
                    break
                }
            }
            return nil
        }
    }
    
    func readACs() {
        print("ACList.readACs")
        for acModel in acModels.acModels {
            acModel.fetchData()
        }
    }
    func togglePower(acModel: ACModel) {
        if acModel.inputDisabled {return}
        acModel.togglePower()
    }
}


struct ACList_Previews: PreviewProvider {
    static var previews: some View {
        ACList()
    }
}


private extension URL {
    
    var isDeeplink: Bool {
        return scheme == "daikin-app" // matches daikin-app://<rest-of-the-url>
    }
    
    var airconIP: String? {
        guard isDeeplink else { return nil }
        guard host == "aircon", pathComponents.count > 1 else { return nil }
    
        // daikin-widget://aircon/192.168.178.33 -> 192.168.178.33
        return pathComponents[1]
    }
}
