import Foundation

/// Haalt de afleveringen op uit de GitHub-repo en bewaart de laatste versie lokaal,
/// zodat de app ook zonder verbinding de meest recente aflevering kan afspelen.
@MainActor
final class EpisodeStore: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    /// De map waarin de dagelijkse taak de afleveringen publiceert.
    static let baseURL = URL(string: "https://raw.githubusercontent.com/gozert1969/BartsRepo/main/podcast/")!

    @Published private(set) var episodes: [EpisodeSummary] = []
    @Published private(set) var phase: Phase = .idle

    private let session: URLSession
    private let cacheDirectory: URL

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 20
        session = URLSession(configuration: configuration)

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("podcast", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        if let cached = readCache(EpisodeIndex.self, path: "index.json") {
            episodes = Self.sorted(cached.episodes)
            phase = .loaded
        }
    }

    func refresh() async {
        if episodes.isEmpty { phase = .loading }
        do {
            let index = try await fetch(EpisodeIndex.self, path: "index.json")
            episodes = Self.sorted(index.episodes)
            phase = .loaded
        } catch {
            if episodes.isEmpty {
                phase = .failed("De afleveringen konden niet worden opgehaald. Controleer uw verbinding en probeer het opnieuw.")
            }
        }
    }

    func episode(for summary: EpisodeSummary) async throws -> Episode {
        do {
            return try await fetch(Episode.self, path: summary.file)
        } catch {
            if let cached = readCache(Episode.self, path: summary.file) { return cached }
            throw error
        }
    }

    // MARK: - Netwerk en cache

    private static func sorted(_ list: [EpisodeSummary]) -> [EpisodeSummary] {
        list.sorted { $0.date > $1.date }
    }

    private func fetch<T: Decodable>(_ type: T.Type, path: String) async throws -> T {
        guard let url = URL(string: path, relativeTo: Self.baseURL) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let value = try JSONDecoder().decode(T.self, from: data)
        try? data.write(to: cacheURL(for: path), options: .atomic)
        return value
    }

    private func readCache<T: Decodable>(_ type: T.Type, path: String) -> T? {
        guard let data = try? Data(contentsOf: cacheURL(for: path)) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func cacheURL(for path: String) -> URL {
        cacheDirectory.appendingPathComponent(path.replacingOccurrences(of: "/", with: "_"))
    }
}
