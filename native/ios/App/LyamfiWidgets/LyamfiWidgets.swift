import WidgetKit
import SwiftUI

private let gold = Color(red: 0.906, green: 0.773, blue: 0.420)
private let ink = Color(red: 0.031, green: 0.031, blue: 0.027)
private let paper = Color(red: 0.961, green: 0.949, blue: 0.918)
private let green = Color(red: 0.333, green: 0.839, blue: 0.620)
private let red = Color(red: 1.000, green: 0.478, blue: 0.522)

struct LyamfiQuote: Identifiable {
    let ticker: String
    let name: String
    let price: Double
    let change: Double
    var id: String { ticker }
    var code: String { ticker.split(separator: ":").last.map(String.init) ?? ticker }
    var formattedPrice: String { Self.format(price) }
    var formattedChange: String { String(format: "%+.2f %%", change) }
    var changeColor: Color { change >= 0 ? green : red }
    private static func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
}

enum LyamfiMarketAPI {
    static func indices(completion: @escaping ([LyamfiQuote]) -> Void) {
        symbols(["CSEMA:MASI", "CSEMA:MSI20", "CSEMA:MASI20"], completion: completion)
    }

    static func watchlist(completion: @escaping ([LyamfiQuote]) -> Void) {
        symbols(["CSEMA:ATW", "CSEMA:IAM", "CSEMA:BCP", "CSEMA:AKT"], completion: completion)
    }

    static func movers(completion: @escaping ([LyamfiQuote]) -> Void) {
        let body: [String: Any] = [
            "filter": [["left": "exchange", "operation": "equal", "right": "CSEMA"]],
            "columns": ["name", "description", "close", "change"],
            "range": [0, 120],
        ]
        scan(body) { quotes in
            let movers = quotes.filter { $0.price > 0 && !$0.ticker.uppercased().contains("MASI") }
                .sorted { abs($0.change) > abs($1.change) }
            completion(Array(movers.prefix(4)))
        }
    }

    private static func symbols(_ tickers: [String], completion: @escaping ([LyamfiQuote]) -> Void) {
        let body: [String: Any] = [
            "symbols": ["tickers": tickers],
            "columns": ["name", "description", "close", "change"],
        ]
        scan(body, completion: completion)
    }

    private static func scan(_ body: [String: Any], completion: @escaping ([LyamfiQuote]) -> Void) {
        guard let url = URL(string: "https://scanner.tradingview.com/morocco/scan"),
              let payload = try? JSONSerialization.data(withJSONObject: body) else {
            completion([])
            return
        }
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.httpMethod = "POST"
        request.httpBody = payload
        request.setValue("text/plain;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data,
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let rows = root["data"] as? [[String: Any]] else {
                completion([])
                return
            }
            let quotes = rows.compactMap { row -> LyamfiQuote? in
                guard let values = row["d"] as? [Any], values.count >= 4,
                      let ticker = values[0] as? String,
                      let name = values[1] as? String else { return nil }
                return LyamfiQuote(ticker: ticker, name: name,
                                   price: (values[2] as? NSNumber)?.doubleValue ?? 0,
                                   change: (values[3] as? NSNumber)?.doubleValue ?? 0)
            }
            completion(quotes)
        }.resume()
    }
}

struct MarketEntry: TimelineEntry {
    let date: Date
    let title: String
    let quotes: [LyamfiQuote]
    let route: String
    let failed: Bool
}

enum MarketFeed {
    case indices, movers, watchlist

    var title: String {
        switch self {
        case .indices: return "MASI · MASI 20"
        case .movers: return "TOP VARIATIONS"
        case .watchlist: return "SÉLECTION LYAMFI"
        }
    }
    var route: String {
        switch self {
        case .indices: return "dashboard"
        case .movers, .watchlist: return "bourse"
        }
    }
    var placeholder: [LyamfiQuote] {
        switch self {
        case .indices:
            return [LyamfiQuote(ticker: "MASI", name: "MASI", price: 0, change: 0),
                    LyamfiQuote(ticker: "MASI20", name: "MASI 20", price: 0, change: 0)]
        case .movers:
            return [LyamfiQuote(ticker: "ATW", name: "Attijariwafa Bank", price: 0, change: 0),
                    LyamfiQuote(ticker: "IAM", name: "Maroc Telecom", price: 0, change: 0)]
        case .watchlist:
            return [LyamfiQuote(ticker: "ATW", name: "Attijariwafa Bank", price: 0, change: 0),
                    LyamfiQuote(ticker: "IAM", name: "Maroc Telecom", price: 0, change: 0),
                    LyamfiQuote(ticker: "BCP", name: "BCP", price: 0, change: 0),
                    LyamfiQuote(ticker: "AKT", name: "Akdital", price: 0, change: 0)]
        }
    }

    func fetch(completion: @escaping ([LyamfiQuote]) -> Void) {
        switch self {
        case .indices: LyamfiMarketAPI.indices(completion: completion)
        case .movers: LyamfiMarketAPI.movers(completion: completion)
        case .watchlist: LyamfiMarketAPI.watchlist(completion: completion)
        }
    }
}

struct MarketProvider: TimelineProvider {
    let feed: MarketFeed

    func placeholder(in context: Context) -> MarketEntry {
        MarketEntry(date: Date(), title: feed.title, quotes: feed.placeholder, route: feed.route, failed: false)
    }
    func getSnapshot(in context: Context, completion: @escaping (MarketEntry) -> Void) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MarketEntry>) -> Void) {
        feed.fetch { quotes in
            let entry = MarketEntry(date: Date(), title: self.feed.title,
                                    quotes: quotes.isEmpty ? self.feed.placeholder : quotes,
                                    route: self.feed.route, failed: quotes.isEmpty)
            let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

struct MarketWidgetView: View {
    let entry: MarketEntry

    var body: some View {
        ZStack {
            ink
            VStack(alignment: .leading, spacing: 8) {
                Text("LYAMFI · \(entry.title)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(gold)
                    .lineLimit(1)
                if entry.quotes.count == 2 {
                    HStack(spacing: 16) {
                        ForEach(entry.quotes) { QuoteCell(quote: $0, prominent: true) }
                    }
                } else {
                    ForEach(entry.quotes.prefix(4)) { QuoteCell(quote: $0, prominent: false) }
                }
                Spacer(minLength: 0)
                Text(entry.failed ? "Cours indisponibles · toucher pour ouvrir" : "Cours TradingView · MAD / points")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(14)
        }
        .widgetURL(URL(string: "lyamfi://\(entry.route)"))
    }
}

struct QuoteCell: View {
    let quote: LyamfiQuote
    let prominent: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(quote.name)
                    .font(.system(size: prominent ? 14 : 11, weight: .semibold))
                    .foregroundColor(paper)
                    .lineLimit(1)
                if prominent {
                    Text(quote.price == 0 ? "—" : quote.formattedPrice)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(paper)
                }
            }
            if !prominent { Spacer(minLength: 4) }
            Text(quote.price == 0 ? "—" : (prominent ? quote.formattedChange : quote.formattedPrice + "  " + quote.formattedChange))
                .font(.system(size: prominent ? 12 : 10, weight: .semibold))
                .foregroundColor(prominent ? quote.changeColor : paper)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let kind: SimpleFeed
}

enum SimpleFeed {
    case session, education, shortcuts
}

struct SimpleProvider: TimelineProvider {
    let kind: SimpleFeed
    func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: Date(), kind: kind) }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .minute, value: kind == .session ? 15 : 720, to: Date()) ?? Date()
        completion(Timeline(entries: [SimpleEntry(date: Date(), kind: kind)], policy: .after(next)))
    }
}

struct SessionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SimpleEntry

    private var components: (weekday: Int, minutes: Int, time: String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Africa/Casablanca") ?? .current
        let weekday = calendar.component(.weekday, from: entry.date)
        let hour = calendar.component(.hour, from: entry.date)
        let minute = calendar.component(.minute, from: entry.date)
        return (weekday, hour * 60 + minute, String(format: "%02d:%02d", hour, minute))
    }
    private var open: Bool {
        let value = components
        return value.weekday != 1 && value.weekday != 7 && value.minutes >= 570 && value.minutes < 930
    }

    var body: some View {
        ZStack {
            ink
            if family == .accessoryCircular {
                VStack(spacing: 2) {
                    Circle().fill(open ? green : gold).frame(width: 8, height: 8)
                    Text(open ? "OUVERT" : "FERMÉ").font(.system(size: 10, weight: .bold)).foregroundColor(paper)
                    Text(components.time).font(.system(size: 9)).foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    Text("BOURSE DE CASABLANCA").font(.system(size: 10, weight: .bold)).foregroundColor(gold)
                    Text(open ? "Marché ouvert" : "Marché fermé")
                        .font(.system(size: 23, weight: .bold)).foregroundColor(open ? green : gold)
                    Text(open ? "Séance continue · jusqu’à 15:30" : "Séance · 09:30 – 15:30")
                        .font(.system(size: 12)).foregroundColor(paper)
                    Spacer(minLength: 0)
                    Text("\(components.time) · Casablanca").font(.system(size: 10)).foregroundColor(.gray)
                }
                .padding(15)
            }
        }
        .widgetURL(URL(string: "lyamfi://bourse"))
    }
}

struct EducationWidgetView: View {
    let entry: SimpleEntry
    private let tips = [
        "Diversifier ne consiste pas à tout acheter, mais à éviter qu’un seul risque décide de tout.",
        "Un cours qui baisse ne rend pas une action bon marché. Regardez d’abord les bénéfices.",
        "Le rendement du dividende monte quand le cours baisse : ce n’est pas toujours une bonne nouvelle.",
        "Investir régulièrement lisse le prix d’entrée, mais ne supprime pas le risque de marché.",
        "Le PER compare un prix à un bénéfice. Il ne se lit qu’avec la croissance et la qualité de ce bénéfice.",
        "Un ordre à cours limité maîtrise le prix, pas l’exécution.",
        "Votre horizon de placement est aussi important que le titre choisi.",
    ]
    var body: some View {
        ZStack(alignment: .leading) {
            ink
            VStack(alignment: .leading, spacing: 10) {
                Text("LYAMFI · LE RÉFLEXE DU JOUR").font(.system(size: 10, weight: .bold)).foregroundColor(gold)
                Text(tips[Calendar.current.ordinality(of: .day, in: .year, for: entry.date).map { $0 % tips.count } ?? 0])
                    .font(.system(size: 14, weight: .medium)).foregroundColor(paper).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Text("Ouvrir l’Académie →").font(.system(size: 11, weight: .semibold)).foregroundColor(gold)
            }
            .padding(15)
        }
        .widgetURL(URL(string: "lyamfi://academie"))
    }
}

struct ShortcutsWidgetView: View {
    var body: some View {
        ZStack {
            ink
            VStack(alignment: .leading, spacing: 12) {
                Text("LYAMFI · ACCÈS RAPIDE").font(.system(size: 10, weight: .bold)).foregroundColor(gold)
                HStack {
                    ShortcutLink(title: "Bourse", route: "bourse")
                    ShortcutLink(title: "Portefeuille", route: "portefeuille")
                }
                HStack {
                    ShortcutLink(title: "Académie", route: "academie")
                    ShortcutLink(title: "Actualités", route: "actualites")
                }
            }
            .padding(14)
        }
    }
}

struct ShortcutLink: View {
    let title: String
    let route: String
    var body: some View {
        Link(destination: URL(string: "lyamfi://\(route)")!) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(paper)
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(Color.white.opacity(0.06)).cornerRadius(10)
        }
    }
}

struct IndicesWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LyamfiIndices", provider: MarketProvider(feed: .indices)) { entry in
            MarketWidgetView(entry: entry)
        }
        .configurationDisplayName("MASI & MASI 20")
        .description("Les deux indices de la Bourse de Casablanca.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MoversWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LyamfiMovers", provider: MarketProvider(feed: .movers)) { entry in
            MarketWidgetView(entry: entry)
        }
        .configurationDisplayName("Top variations")
        .description("Les plus fortes variations du jour.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct WatchlistWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LyamfiWatchlist", provider: MarketProvider(feed: .watchlist)) { entry in
            MarketWidgetView(entry: entry)
        }
        .configurationDisplayName("Sélection Lyamfi")
        .description("Quatre valeurs marocaines suivies sur votre écran d’accueil.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct SessionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LyamfiSession", provider: SimpleProvider(kind: .session)) { entry in
            SessionWidgetView(entry: entry)
        }
        .configurationDisplayName("Séance de Casablanca")
        .description("Marché ouvert ou fermé, y compris sur l’écran verrouillé.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

struct EducationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LyamfiEducation", provider: SimpleProvider(kind: .education)) { entry in
            EducationWidgetView(entry: entry)
        }
        .configurationDisplayName("Réflexe du jour")
        .description("Un principe d’investissement chaque jour.")
        .supportedFamilies([.systemMedium])
    }
}

struct ShortcutsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LyamfiShortcuts", provider: SimpleProvider(kind: .shortcuts)) { _ in
            ShortcutsWidgetView()
        }
        .configurationDisplayName("Raccourcis Lyamfi")
        .description("Bourse, portefeuille, Académie et actualités.")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct LyamfiWidgetBundle: WidgetBundle {
    var body: some Widget {
        IndicesWidget()
        MoversWidget()
        WatchlistWidget()
        SessionWidget()
        EducationWidget()
        ShortcutsWidget()
    }
}
