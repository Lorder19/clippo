import AppKit

/// Opt-in, once-a-day look at the latest GitHub release. Off by default: Clippo promises no network use
/// unless you ask for it. Sends one anonymous GET to api.github.com, no cookies, nothing about you.
final class Updater: ObservableObject {
    static let shared = Updater()
    static let repo = "Lorder19/clippo"

    @Published private(set) var available: (version: String, url: URL)?
    @Published private(set) var lastResult: String?

    var enabled: Bool {
        get { UserDefaults.standard.bool(forKey: "checkUpdates") }
        set {
            UserDefaults.standard.set(newValue, forKey: "checkUpdates")
            if newValue { check() }
        }
    }

    private var timer: Timer?
    private let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

    func start() {
        if enabled { checkIfDue() }
        let t = Timer(timeInterval: 3600, repeats: true) { [weak self] _ in
            if self?.enabled == true { self?.checkIfDue() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func checkIfDue() {
        let last = UserDefaults.standard.double(forKey: "lastUpdateCheck")
        if Date().timeIntervalSince1970 - last > 86_400 { check() }
    }

    func check() {
        guard let api = URL(string: "https://api.github.com/repos/\(Self.repo)/releases/latest") else { return }
        var req = URLRequest(url: api, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession(configuration: .ephemeral).dataTask(with: req) { [weak self] data, _, error in
            guard let self else { return }
            var found: (String, URL)?
            var result = L("Не удалось проверить")
            if error == nil, let data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tag = json["tag_name"] as? String,
               let page = (json["html_url"] as? String).flatMap(URL.init(string:)) {
                let version = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                if Self.isNewer(version, than: self.current) {
                    found = (version, page)
                    result = String(format: L("Доступна версия %@"), version)
                } else {
                    result = L("У вас последняя версия")
                }
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastUpdateCheck")
            }
            DispatchQueue.main.async {
                self.available = found.map { (version: $0.0, url: $0.1) }
                self.lastResult = result
            }
        }.resume()
    }

    static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = a.split(separator: ".").map { Int($0) ?? 0 }, pb = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0, y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
