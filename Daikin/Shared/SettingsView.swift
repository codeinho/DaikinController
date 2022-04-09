//
//  Settings.swift
//  Daikin
//
//  Created by Lothar Heinrich on 29.12.21.
//

import SwiftUI
import WidgetKit

fileprivate let notSetStr = "Not Set"
fileprivate let darkStr = "dark"
fileprivate let lightStr = "light"



struct SettingsView: View {
#if os(macOS)
    private var isEditing: Bool = false
#else
    @Environment(\.editMode) var editMode
    private var isEditing: Bool { editMode?.wrappedValue.isEditing ?? false }
#endif

    @ObservedObject var settings = UserSettings.shared
    @EnvironmentObject var acModels: AcModelWrapper
    
    @State var acIP: String = ""
    @State var fallbackPrefixURL: String = UserSettings.shared.fallbackPrefixURL
    
    @State var loading = false // simplified state sufficient here
    
    @State private var errorMessage: ErrorMessage?
    
            
    var body: some View {
        VStack {
            Form {
                Section(
                    header: Text("Daikin Devices"),
                    footer: Text("Enter the IP Adress of the Daikin device")
                ) {
                    HStack {
                        TextField("IP", text: $acIP)
                        Button("add") {
                            addAc(fromIp: acIP)
                            
                        }
                    }
                }

                Section(
                    header: acListHeader()
                ) {
                    List {
                        ForEach(settings.acIPs, id: \.self) { ip in
                            Text("\(ip)") // : \(ac.name)")
                        }
                        .onMove { indexSet, offset in
                            settings.acIPs.move(fromOffsets: indexSet, toOffset: offset)
                            onSettingsUpdated()
                        }
                        .onDelete { indexSet in
                            settings.acIPs.remove(atOffsets: indexSet)
                            onSettingsUpdated()
                        }
                    }
                    .emptyState(settings.acIPs.isEmpty) {
                      Text("Enter IP address of your aircon and hit add")
                    }
                }
                
                Section (
                    header: Text("Fallback prefix URL (e.g. for access via myfritz)")
                    
                    
                ) {
                    TextField("", text: $fallbackPrefixURL)
                        .onChange(of: fallbackPrefixURL, perform: {fallbackPrefixURL in
                            UserSettings.shared.fallbackPrefixURL = fallbackPrefixURL
                        })
                }
                
                Section(header: Text("User Interface")) {
                        Picker("Color Scheme", selection: $settings.colorSchemeSetting) {
                           Text("Light").tag(lightStr)
                           Text("Dark").tag(darkStr)
                           Text("System").tag(notSetStr)
                        }
                }
            }
        }
        .padding()
        .disabled(loading)
        .onDisappear(perform: {onDisappear()})
        .alert(item: $errorMessage) { errorMessage in
            Alert(title: Text("Error"), message: Text(errorMessage.message), dismissButton: .cancel())
        }
    }
    
    func onDisappear() {
        #if os(macOS)
        #else
            editMode?.wrappedValue = .inactive
        #endif
        WidgetCenter.shared.reloadTimelines(ofKind: "Widget_iOS")


    }
    
    ///
    /// this func is getting called when settings related to the aircons were changed.
    ///
    private func onSettingsUpdated() {
        WidgetCenter.shared.reloadTimelines(ofKind: "Widget_iOS")
        acModels.reloadAll()
    }
    
    func addAc(fromIp: String) {
        if (fromIp == "") {
            return
        }
        if settings.acIPs.contains(fromIp) {
            return
        }
        Task.init {
            defer {
                DispatchQueue.main.async {
                    loading = false
                }
            }
            do {
                DispatchQueue.main.async {
                    loading = true
                }
                let bi = Endpoint<BasicInfo>()
                let biData = try await bi.fetch(acIP: fromIp)
                
                DispatchQueue.main.async {
//                    acList.append(AC(name: biData.nameReadable, ip: acIP))
                    settings.acIPs.append(acIP)
                    settings.acNameCache[acIP] = biData.nameReadable
                    onSettingsUpdated()
                    acIP = ""
                }

                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = ErrorMessage(message: "could not reach ip=\(fromIp)")
                }
            }
        }
    }
    
    func acListHeader() -> some View {
        #if os(macOS)
            Text("Available Aircons")
        #else
        Button(action: { withAnimation { editMode?.wrappedValue = isEditing ? .inactive : .active }},
               label: { Text(isEditing ? "Done" : "Change order or remove devices")
          })
        .buttonStyle(PlainButtonStyle()) // swiftui bug. without this, button is disabled when in editmode
        .foregroundColor(.blue)
            .visibility(settings.acIPs.isEmpty ? .gone : .visible)
        #endif
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
