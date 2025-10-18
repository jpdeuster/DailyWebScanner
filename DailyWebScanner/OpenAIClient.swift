import Foundation

struct OpenAIClient {
    enum OpenAIError: Error, LocalizedError {
        case missingAPIKey
        case http(Int)
        case decoding
        case empty
        case network(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "OpenAI API-Key fehlt."
            case .http(let code):
                return "OpenAI HTTP-Fehler: \(code)"
            case .decoding:
                return "OpenAI Antwort konnte nicht gelesen werden."
            case .empty:
                return "Leere Antwort von OpenAI."
            case .network(let message):
                return message
            }
        }
    }

    var apiKeyProvider: () -> String?
    var model: String = "gpt-4o-mini"

    // Eigene URLSession mit Timeouts, damit Requests nicht hängen bleiben
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

    struct ChatRequest: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }
        let model: String
        let messages: [Message]
        let temperature: Double
        let max_tokens: Int
    }

    struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let role: String
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }

    func summarize(snippet: String, title: String?, link: String?) async throws -> String {
        guard let key = apiKeyProvider(), !key.isEmpty else { throw OpenAIError.missingAPIKey }

        let systemPrompt = "Du bist ein Assistent, der Web-Snippets prägnant auf Deutsch zusammenfasst."
        let userPrompt = """
        Titel: \(title ?? "-")
        Link: \(link ?? "-")
        Text: \(snippet)

        Aufgabe: Erstelle eine kurze, gut lesbare Zusammenfassung (1–3 Sätze).
        """

        let body = ChatRequest(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            temperature: 0.3,
            max_tokens: 200
        )

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw OpenAIError.decoding
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else { throw OpenAIError.http(status) }

            let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
            guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
                throw OpenAIError.empty
            }
            return content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                throw OpenAIError.network("No internet connection. Please check your network connection.")
            case .cannotFindHost, .dnsLookupFailed:
                throw OpenAIError.network("OpenAI server could not be reached. Please check your internet connection.")
            case .timedOut:
                throw OpenAIError.network("Connection timeout to OpenAI. Please try again.")
            case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateHasUnknownRoot:
                throw OpenAIError.network("Secure connection failed. Please check your system clock and network settings.")
            default:
                throw OpenAIError.network("Network error: \(urlError.localizedDescription)")
            }
        } catch {
            throw OpenAIError.network("Unexpected error: \(error.localizedDescription)")
        }
    }
}
