//
//  ContentView.swift
//  Shared
//
//  Created by Lothar Heinrich on 04.12.21.
//

import SwiftUI

fileprivate let NAV_SETTINGS = "SETTINGS"
fileprivate let NAV_FIRST_AC = "FIRST_AC"


struct ContentView: View {
    
    @StateObject var acModels = AcModelWrapper(demoMode: SETTINGS_DEMO_MODE)
    @StateObject var settings = UserSettings.shared
    // goto settings to enter IPs on first start
    @State private var navigationTag: String? = (UserSettings.shared.acIPs.count == 0) ? NAV_SETTINGS : NAV_FIRST_AC
    
#if os(macOS)
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    NavigationLink(destination:
                                    SettingsView()
                                    .environmentObject(acModels)
                                   , tag: NAV_SETTINGS, selection: $navigationTag) {
                            Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.gray)
                    }
//                FIXME: the following doesn't work on macOS
//                    NavigationLink(destination:
//                                    ConsumptionView()
//                                    .environmentObject(acModels)
//                                    , tag: NAV_SETTINGS, selection: $navigationTag) {
//                            Image(systemName: "chart.line.uptrend.xyaxis")
//                            .foregroundColor(.gray)
//                    }
                    Spacer()
                }
                .padding()

                ACList(selectedAirconIP: acModels.acModels.first?.acIP)
                    .environmentObject(acModels)
            }
        }
        .preferredColorScheme(settings.colorScheme)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
#else
    @State private var editMode = EditMode.inactive // iOS only
    var body: some View {
        NavigationView {
            ACList()
                .navigationBarTitleDisplayMode(.inline) // iOS only
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink(destination:
                            SettingsView()
                                .environment(\.editMode, $editMode)
                                .environmentObject(acModels)
                            ) {
                                Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.gray)
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink(destination:
                            ConsumptionView()
                            .environmentObject(acModels)
                            , tag: NAV_SETTINGS, selection: $navigationTag) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .environmentObject(acModels)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(settings.colorScheme)
        .edgesIgnoringSafeArea(.top)
    }
#endif
}



//struct ItemsToolbar: ToolbarContent {
//    let add: () -> Void
//    let sort: () -> Void
//    let filter: () -> Void
//
//    var body: some ToolbarContent {
//        ToolbarItem(placement: .primaryAction) {
//            Button("Add", action: add)
//        }
//
//        ToolbarItemGroup(placement: .bottomBar) {
//            Button("Sort", action: sort)
//            Button("Filter", action: filter)
//        }
//    }
//}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


