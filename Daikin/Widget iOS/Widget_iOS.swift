//
//  Widget_iOS.swift
//  Widget iOS
//
//  Created by Lothar Heinrich on 30.01.22.
//

import WidgetKit
import SwiftUI

func getAircons() -> [Aircon] {
    guard let aircons = UserSettings.getAcListForWidget() else {
        print("Warning: Could not read settings from main app")
        return []
    }
    return aircons
}

func makeEntry(tag: String = "") -> SimpleEntry {
    let aircons = getAircons()
    return SimpleEntry(date: Date(),
                       aircons: aircons,
                       info: "tag=\(tag) \(aircons.first?.name ?? "-")")
}
struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> SimpleEntry {
        let entry = makeEntry(tag: "placeholder")
        return entry
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = makeEntry(tag: "snapshot")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = makeEntry(tag: "timeline")
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
    
    
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let aircons: [Aircon]
    let info: String
}

struct Widget_iOSEntryView : View {
    @Environment(\.widgetFamily) var family
    
    var entry: Provider.Entry
    
    var body: some View {
        if family == .systemSmall {
            VStack {
                Link(destination: urlFromAcIP(ip: "")) {
                    Image("daikin-logo-rect")
                        .resizable()
                        .frame(width: 115, height:24, alignment: .center)
                                    }
                ForEach(airconsFirstN) {
                    Divider()
                    ACLinkView(ip: $0.ip, name: $0.name)
                }
            }
            .padding()
            .widgetURL(deepLinkToFirst)
        } else {
            VStack(spacing: 0) {
                Link(destination: urlFromAcIP(ip: "")) {
                                        Image("daikin-logo-rect")
                                             .resizable()
                                             .frame(width: 143, height:30, alignment: .center)
                                             .padding(.top, 6)
                                             .padding(.bottom, 5)
                                    }
                ForEach(airconsFirstN) {
                    Divider()
                    ACLinkView(ip: $0.ip, name: $0.name)
                }
                
            }
            .padding(.bottom, 2)
            
            
        }
    }
    
    var deepLinkToFirst: URL {
        get {
            if let firstAC = aircons.first {
                return urlFromAcIP(ip: firstAC.ip)
            }
            return URL(string: "daikin-app://aircon")!
        }
        
    }
    var acMaxCount: Int {
        get {
            switch family {
            case .systemSmall:
                return 1
            case .systemMedium:
                return 3
            case .systemLarge:
                return 5
            case .systemExtraLarge:
                return 7
            default:
                // never happens
                return 3
            }
        }
    }
    var aircons: [Aircon] {
        get {
//            return (1...2).map { Aircon(name: "t\($0)", ip: "id\($0)") }
            return entry.aircons
        }
    }
    var airconsFirstN: [Aircon] {
        get {
            Array(aircons.prefix(acMaxCount))
        }
    }
}

fileprivate func urlFromAcIP(ip: String) -> URL {
    URL(string: "daikin-app://aircon/\(ip)") ?? URL(string: "daikin-app://aircon")!
}

struct ACLinkView: View {
    
    let ip: String
    let name: String
    var body: some View {
        Link(destination: urlFromAcIP(ip: ip)) {
            ZStack {
                Color.clear
                Text(name)
                    .foregroundColor(Color(red: 58.0 / 255.0, green: 71.0 / 255.0, blue: 78.0 / 255.0))
//                    .fontWeight(.bold)
                    .font(.title3)
            }
            
        }
    }
}

@main
struct Widget_iOS: Widget {
    let kind: String = "Widget_iOS"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            Widget_iOSEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .configurationDisplayName("Daikin Widget")
        .description("Fast select aircon device.")
    }
}

struct Widget_iOS_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Widget_iOSEntryView(entry: SimpleEntry(date: Date(), aircons: [Aircon(name: "Testaircon", ip: "192.168.178.123")], info: "info prev"))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            Widget_iOSEntryView(entry: SimpleEntry(date: Date(), aircons:
                (1...3).map { Aircon(name: "Testaircon\($0)", ip: "id\($0)") }
                , info: "info prev"))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
