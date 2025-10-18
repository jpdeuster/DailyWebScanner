import Foundation

struct SerpOrganicResult: Decodable {
    let title: String?
    let link: String?
    let snippet: String?
}

struct SerpSearchResponse: Decodable {
    let organic_results: [SerpOrganicResult]?
}

struct SerpAPIClient {
    enum SerpError: Error, LocalizedError {
        case missingAPIKey
        case badURL
        case http(Int)
        case decoding
        case empty
        case network(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "SerpAPI API-Key fehlt."
            case .badURL: return "Ungültige SerpAPI URL."
            case .http(let code): return "SerpAPI HTTP-Fehler: \(code)"
            case .decoding: return "SerpAPI Antwort konnte nicht gelesen werden."
            case .empty: return "Keine Ergebnisse von SerpAPI."
            case .network(let message): return message
            }
        }
    }

    var apiKeyProvider: () -> String?
    private let session: URLSession

    init(apiKeyProvider: @escaping () -> String?, session: URLSession? = nil) {
        self.apiKeyProvider = apiKeyProvider

        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 20
            config.timeoutIntervalForResource = 60
            config.waitsForConnectivity = false
            self.session = URLSession(configuration: config)
        }
    }

    func fetchTopResults(query: String, count: Int = 20, hl: String = "de", gl: String = "de") async throws -> [SerpOrganicResult] {
        guard let key = apiKeyProvider(), !key.isEmpty else { throw SerpError.missingAPIKey }

        guard var components = URLComponents(string: "https://serpapi.com/search.json") else {
            throw SerpError.badURL
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "engine", value: "google"),
            URLQueryItem(name: "api_key", value: key),
            URLQueryItem(name: "num", value: String(count)),
            URLQueryItem(name: "hl", value: hl),
            URLQueryItem(name: "gl", value: gl)
        ]

        guard let url = components.url else { throw SerpError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Mask API key in logs for security
        if #available(macOS 12.0, *) {
            request.setValue("DailyWebScanner/1.0", forHTTPHeaderField: "User-Agent")
        }

        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else { throw SerpError.http(status) }

            let decoded = try JSONDecoder().decode(SerpSearchResponse.self, from: data)
            let results = decoded.organic_results ?? []
            guard !results.isEmpty else { throw SerpError.empty }
            return results
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError {
            // Benutzerfreundliche Meldungen
            switch urlError.code {
            case .notConnectedToInternet:
                throw SerpError.network("Keine Internetverbindung. Bitte prüfen Sie Ihre Netzwerkverbindung.")
            case .cannotFindHost, .dnsLookupFailed:
                throw SerpError.network("Der Servername konnte nicht aufgelöst werden. Bitte prüfen Sie Ihre Internetverbindung oder die URL.")
            case .timedOut:
                throw SerpError.network("Zeitüberschreitung bei der Verbindung zu SerpAPI. Bitte versuchen Sie es erneut.")
            case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateHasUnknownRoot:
                throw SerpError.network("Sichere Verbindung fehlgeschlagen. Bitte prüfen Sie Ihre Systemuhr und Netzwerkeinstellungen.")
            default:
                throw SerpError.network("Netzwerkfehler: \(urlError.localizedDescription)")
            }
        } catch {
            throw SerpError.network("Unerwarteter Fehler: \(error.localizedDescription)")
        }
    }
}
