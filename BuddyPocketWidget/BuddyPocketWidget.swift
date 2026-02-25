import WidgetKit
import SwiftUI

// ══════════════════════════════════════════════════════════════════
// BUDDY POCKET WIDGET — Small / Medium / Large
// ══════════════════════════════════════════════════════════════════

struct BuddyWidgetData {
    var name: String = "Buddy"
    var hunger: Double = 1.0
    var happiness: Double = 1.0
    var energy: Double = 1.0
    var hygiene: Double = 1.0
    var level: Int = 1
    var streak: Int = 0
    var bodyType: String = "blob"
    var bodyColor: String = "violet"
    var mood: String = "😊"
    
    static func load() -> BuddyWidgetData {
        guard let defaults = UserDefaults(suiteName: "group.com.rezaimia.buddypocket"),
              let data = defaults.data(forKey: "widget_buddy"),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return BuddyWidgetData()
        }
        var d = BuddyWidgetData()
        d.name      = json["name"] as? String ?? "Buddy"
        d.hunger    = json["hunger"] as? Double ?? 1.0
        d.happiness = json["happiness"] as? Double ?? 1.0
        d.energy    = json["energy"] as? Double ?? 1.0
        d.hygiene   = json["hygiene"] as? Double ?? 1.0
        d.level     = json["level"] as? Int ?? 1
        d.streak    = json["streak"] as? Int ?? 0
        d.bodyType  = json["bodyType"] as? String ?? "blob"
        d.bodyColor = json["bodyColor"] as? String ?? "violet"
        d.mood      = json["mood"] as? String ?? "😊"
        return d
    }
}

// MARK: — Timeline

struct BuddyTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BuddyEntry {
        BuddyEntry(date: Date(), data: BuddyWidgetData())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (BuddyEntry) -> Void) {
        completion(BuddyEntry(date: Date(), data: BuddyWidgetData.load()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<BuddyEntry>) -> Void) {
        let entry = BuddyEntry(date: Date(), data: BuddyWidgetData.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }
}

struct BuddyEntry: TimelineEntry {
    let date: Date
    let data: BuddyWidgetData
}

// MARK: — Widget Views

struct SmallBuddyWidget: View {
    let data: BuddyWidgetData
    
    var body: some View {
        VStack(spacing: 4) {
            Text(data.mood).font(.system(size: 40))
            Text(data.name)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.purple)
            Text("Nv.\(data.level)")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color(red: 1, green: 0.9, blue: 0.93),
                                    Color(red: 0.91, green: 0.84, blue: 1)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}

struct MediumBuddyWidget: View {
    let data: BuddyWidgetData
    
    var body: some View {
        HStack(spacing: 16) {
            // Buddy
            VStack(spacing: 4) {
                Text(data.mood).font(.system(size: 44))
                Text(data.name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple)
            }
            .frame(width: 80)
            
            // Stats
            VStack(spacing: 6) {
                widgetStatBar("🍖", data.hunger, .orange)
                widgetStatBar("😊", data.happiness, .pink)
                widgetStatBar("⚡", data.energy, .yellow)
                widgetStatBar("🛁", data.hygiene, .blue)
            }
            
            // Feed button (intent action)
            Link(destination: URL(string: "buddypocket://feed")!) {
                VStack(spacing: 4) {
                    Text("🍖").font(.system(size: 22))
                    Text("Nourrir")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                }
                .frame(width: 48, height: 48)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color(red: 1, green: 0.9, blue: 0.93),
                                    Color(red: 0.91, green: 0.84, blue: 1),
                                    Color(red: 0.82, green: 0.96, blue: 1)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}

struct LargeBuddyWidget: View {
    let data: BuddyWidgetData
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("🐾").font(.system(size: 14))
                Text("Buddy Pocket").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.purple)
                Spacer()
                if data.streak > 0 {
                    HStack(spacing: 2) {
                        Text("🔥")
                        Text("\(data.streak)").font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(.orange)
                    }
                }
            }
            
            // Buddy
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(data.mood).font(.system(size: 50))
                    Text(data.name).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(.purple)
                    Text("Nv.\(data.level)").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                }
                
                VStack(spacing: 5) {
                    widgetStatBar("🍖", data.hunger, .orange)
                    widgetStatBar("😊", data.happiness, .pink)
                    widgetStatBar("⚡", data.energy, .yellow)
                    widgetStatBar("🛁", data.hygiene, .blue)
                }
            }
            
            // 4 Action buttons
            HStack(spacing: 8) {
                widgetActionButton("🍖", "Nourrir", "feed")
                widgetActionButton("🤗", "Caresser", "pet")
                widgetActionButton("💤", "Dormir", "sleep")
                widgetActionButton("🛁", "Bain", "bath")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color(red: 1, green: 0.9, blue: 0.93),
                                    Color(red: 0.91, green: 0.84, blue: 1),
                                    Color(red: 0.82, green: 0.96, blue: 1)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
    
    private func widgetActionButton(_ emoji: String, _ label: String, _ action: String) -> some View {
        Link(destination: URL(string: "buddypocket://\(action)")!) {
            VStack(spacing: 2) {
                Text(emoji).font(.system(size: 20))
                Text(label).font(.system(size: 8, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: — Shared stat bar

private func widgetStatBar(_ icon: String, _ value: Double, _ color: Color) -> some View {
    HStack(spacing: 4) {
        Text(icon).font(.system(size: 10))
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.15)).frame(height: 5)
                Capsule().fill(color).frame(width: max(2, geo.size.width * value), height: 5)
            }
        }.frame(height: 5)
        Text("\(Int(value * 100))%")
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .frame(width: 24, alignment: .trailing)
    }
}

// MARK: — Widget Configuration

@main
struct BuddyPocketWidget: Widget {
    let kind = "BuddyPocketWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BuddyTimelineProvider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Buddy Pocket")
        .description("Garde un œil sur ton Buddy !")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BuddyEntry
    
    var body: some View {
        switch family {
        case .systemSmall:  SmallBuddyWidget(data: entry.data)
        case .systemMedium: MediumBuddyWidget(data: entry.data)
        case .systemLarge:  LargeBuddyWidget(data: entry.data)
        default:            SmallBuddyWidget(data: entry.data)
        }
    }
}
