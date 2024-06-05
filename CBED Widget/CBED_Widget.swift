//
//  CBED_Widget.swift
//  CBED Widget
//
//  Created by groo on 07/10/2023.
//

import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let level: String
}

struct Provider: TimelineProvider {
    let userDefault = UserDefaults(suiteName: "group.com.cbed.share")
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), level: getCurrentLevel())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), level: getCurrentLevel())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, level: getCurrentLevel())
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    func getCurrentLevel() -> String {
        guard let data = userDefault?.data(forKey: "currentLevel"),
              let valueString = String(data: data, encoding: .utf8) else {
            return "None"
        }
        return valueString
    }
}

struct CBED_WidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(spacing: 0) {
            switch family {
            case .systemSmall:
                smallFamily
            case .systemMedium:
                mediumFamily
            default:
                Text("Unsupported")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.white)
        
    }
    
    private var smallFamily: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 10)
            
            HStack(spacing: 0) {
                Image("logo")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .cornerRadius(10)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Current MBE Level")
                    .font(.system(size: 16))
                Text(entry.level)
                    .font(.system(size: 14))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
    }
    
    private var mediumFamily: some View {
        HStack(alignment: .top, spacing: 20) {
            HStack(spacing: 0) {
                Image("logo")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Current MBE Level")
                    .font(.system(size: 20))
                Text(entry.level)
                    .font(.system(size: 15))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
           
        }
    }
}

struct CBED_Widget: Widget {
    let kind: String = "CBED_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                CBED_WidgetEntryView(entry: entry)
                    .containerBackground(.widgetBackground, for: .widget)
                    .background(Color("WidgetBackground"))
            } else {
                CBED_WidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

//#Preview(as: .systemMedium) {
//    CBED_Widget()
//} timeline: {
//    SimpleEntry(date: .now, level: "Level 2 Contracts")
//}
//
//#Preview(as: .systemSmall) {
//    CBED_Widget()
//} timeline: {
//    SimpleEntry(date: .now, level: "Level 2 Contracts")
//}
