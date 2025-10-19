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
    
    struct AccountInfo: Decodable {
        let credits_remaining: Int?
        let credits_limit: Int?
        let plan: String?
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

    func fetchTopResults(query: String, count: Int = 20, hl: String = "de", gl: String = "de", 
                        location: String? = nil, safe: String? = nil, tbm: String? = nil, 
                        tbs: String? = nil, as_qdr: String? = nil) async throws -> [SerpOrganicResult] {
        
        // If requesting more than 10 results, try multiple pages
        if count > 10 {
            DebugLogger.shared.logWebViewAction("Using multi-page fetch for \(count) results")
            return try await fetchMultiplePages(query: query, totalCount: count, hl: hl, gl: gl, 
                                              location: location, safe: safe, tbm: tbm, tbs: tbs, as_qdr: as_qdr)
        }
        guard let key = apiKeyProvider(), !key.isEmpty else { throw SerpError.missingAPIKey }

        guard var components = URLComponents(string: "https://serpapi.com/search.json") else {
            throw SerpError.badURL
        }
        
        var queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "engine", value: "google"),
            URLQueryItem(name: "api_key", value: key),
            URLQueryItem(name: "num", value: String(count)),
            URLQueryItem(name: "start", value: "1"), // Fix for Google's Knowledge Graph issue
            URLQueryItem(name: "hl", value: hl),
            URLQueryItem(name: "gl", value: gl)
        ]
        
        // Add optional parameters if provided
        if let location = location, !location.isEmpty {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
        if let safe = safe, !safe.isEmpty {
            queryItems.append(URLQueryItem(name: "safe", value: safe))
        }
        if let tbm = tbm, !tbm.isEmpty {
            queryItems.append(URLQueryItem(name: "tbm", value: tbm))
        }
        if let tbs = tbs, !tbs.isEmpty {
            queryItems.append(URLQueryItem(name: "tbs", value: tbs))
        }
        if let as_qdr = as_qdr, !as_qdr.isEmpty {
            queryItems.append(URLQueryItem(name: "as_qdr", value: as_qdr))
        }
        
        components.queryItems = queryItems

        guard let url = components.url else { throw SerpError.badURL }
        
        // Debug: Log complete API payload
        DebugLogger.shared.logAPIPayload(url: url.absoluteString, parameters: queryItems)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if #available(macOS 12.0, *) {
            request.setValue("DailyWebScanner/1.0", forHTTPHeaderField: "User-Agent")
        }

        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if !(200..<300).contains(status) {
                DebugLogger.shared.logHTTPStatus(url: url, status: status)
                throw SerpError.http(status)
            }

            let decoded = try JSONDecoder().decode(SerpSearchResponse.self, from: data)
            let results = decoded.organic_results ?? []
            guard !results.isEmpty else { throw SerpError.empty }
            return results
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError {
            // Extract rich diagnostics
            let ns = urlError as NSError
            let path = ns.userInfo["_NSURLErrorNWPathKey"] as? String
            let report = ns.userInfo["_NSURLErrorNWResolutionReportKey"] as? String
            DebugLogger.shared.logNetworkURLError(url: url, code: urlError.code, underlying: ns, path: path, resolutionReport: report)

            // DNS specialization
            if urlError.code == .cannotFindHost || urlError.code == .dnsLookupFailed {
                let cfDomain = ns.userInfo["_kCFStreamErrorDomainKey"] as? Int
                let cfCode = ns.userInfo["_kCFStreamErrorCodeKey"] as? Int
                DebugLogger.shared.logDNSFailure(host: url.host ?? "-", cfDomain: cfDomain, cfCode: cfCode, details: report ?? path)
                DebugLogger.shared.logSandboxNetworkIssue()
            }

            switch urlError.code {
            case .notConnectedToInternet:
                throw SerpError.network("No internet connection. Please check your network connection.")
            case .cannotFindHost, .dnsLookupFailed:
                throw SerpError.network("SerpAPI server could not be reached. Please check your internet connection.")
            case .timedOut:
                throw SerpError.network("Connection timeout to SerpAPI. Please try again.")
            case .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateHasUnknownRoot:
                throw SerpError.network("Secure connection failed. Please check your system clock and network settings.")
            default:
                throw SerpError.network("Network error: \(urlError.localizedDescription)")
            }
        } catch {
            DebugLogger.shared.logNetworkError(url: url.absoluteString, error: error)
            throw SerpError.network("Unerwarteter Fehler: \(error.localizedDescription)")
        }
    }
    
    func getAccountInfo() async throws -> AccountInfo {
        guard let key = apiKeyProvider(), !key.isEmpty else { throw SerpError.missingAPIKey }

        guard var components = URLComponents(string: "https://serpapi.com/account.json") else {
            throw SerpError.badURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: key)
        ]

        guard let url = components.url else { throw SerpError.badURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("DailyWebScanner/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if !(200..<300).contains(status) {
                DebugLogger.shared.logHTTPStatus(url: url, status: status)
                throw SerpError.http(status)
            }

            let accountInfo = try JSONDecoder().decode(AccountInfo.self, from: data)
            return accountInfo
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError {
            let ns = urlError as NSError
            let path = ns.userInfo["_NSURLErrorNWPathKey"] as? String
            let report = ns.userInfo["_NSURLErrorNWResolutionReportKey"] as? String
            DebugLogger.shared.logNetworkURLError(url: url, code: urlError.code, underlying: ns, path: path, resolutionReport: report)

            if urlError.code == .cannotFindHost || urlError.code == .dnsLookupFailed {
                let cfDomain = ns.userInfo["_kCFStreamErrorDomainKey"] as? Int
                let cfCode = ns.userInfo["_kCFStreamErrorCodeKey"] as? Int
                DebugLogger.shared.logDNSFailure(host: url.host ?? "-", cfDomain: cfDomain, cfCode: cfCode, details: report ?? path)
                DebugLogger.shared.logSandboxNetworkIssue()
            }

            switch urlError.code {
            case .notConnectedToInternet:
                throw SerpError.network("No internet connection. Please check your network connection.")
            case .cannotFindHost, .dnsLookupFailed:
                throw SerpError.network("SerpAPI server could not be reached. Please check your internet connection.")
            case .timedOut:
                throw SerpError.network("Connection timeout to SerpAPI. Please try again.")
            default:
                throw SerpError.network("Network error: \(urlError.localizedDescription)")
            }
        } catch {
            DebugLogger.shared.logNetworkError(url: url.absoluteString, error: error)
            throw SerpError.network("Unexpected error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Multiple Pages Support
    
    private func fetchMultiplePages(query: String, totalCount: Int, hl: String, gl: String,
                                  location: String?, safe: String?, tbm: String?, tbs: String?, as_qdr: String?) async throws -> [SerpOrganicResult] {
        var allResults: [SerpOrganicResult] = []
        let pageSize = 10 // Google's default page size
        let totalPages = (totalCount + pageSize - 1) / pageSize // Ceiling division
        
        DebugLogger.shared.logWebViewAction("Multi-page fetch: totalCount=\(totalCount), pageSize=\(pageSize), totalPages=\(totalPages)")
        
        for page in 0..<totalPages {
            DebugLogger.shared.logWebViewAction("Starting page \(page + 1) of \(totalPages)")
            let start = page * pageSize
            let pageCount = min(pageSize, totalCount - allResults.count)
            
            if pageCount <= 0 { break }
            
            do {
                DebugLogger.shared.logWebViewAction("Fetching page \(page + 1): start=\(start), count=\(pageCount)")
                let pageResults = try await fetchSinglePage(
                    query: query, 
                    count: pageCount, 
                    start: start,
                    hl: hl, 
                    gl: gl, 
                    location: location, 
                    safe: safe, 
                    tbm: tbm, 
                    tbs: tbs, 
                    as_qdr: as_qdr
                )
                
                DebugLogger.shared.logWebViewAction("Page \(page + 1) returned \(pageResults.count) results")
                allResults.append(contentsOf: pageResults)
                
                // If we got fewer results than requested, we've reached the end
                if pageResults.count < pageCount {
                    DebugLogger.shared.logWebViewAction("Reached end of results at page \(page + 1) - got \(pageResults.count) instead of \(pageCount)")
                    break
                }
                
                // If we got exactly 0 results, definitely stop
                if pageResults.count == 0 {
                    DebugLogger.shared.logWebViewAction("No results on page \(page + 1), stopping")
                    break
                }
                
            } catch {
                // If a page fails, continue with what we have
                DebugLogger.shared.logWebViewAction("Failed to fetch page \(page + 1): \(error)")
                break
            }
        }
        
        return Array(allResults.prefix(totalCount))
    }
    
    private func fetchSinglePage(query: String, count: Int, start: Int, hl: String, gl: String,
                               location: String?, safe: String?, tbm: String?, tbs: String?, as_qdr: String?) async throws -> [SerpOrganicResult] {
        guard let key = apiKeyProvider(), !key.isEmpty else { throw SerpError.missingAPIKey }

        guard var components = URLComponents(string: "https://serpapi.com/search.json") else {
            throw SerpError.badURL
        }
        
        var queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "engine", value: "google"),
            URLQueryItem(name: "api_key", value: key),
            URLQueryItem(name: "num", value: String(count)),
            URLQueryItem(name: "start", value: String(start)),
            URLQueryItem(name: "hl", value: hl),
            URLQueryItem(name: "gl", value: gl)
        ]
        
        // Add optional parameters if provided
        if let location = location, !location.isEmpty {
            queryItems.append(URLQueryItem(name: "location", value: location))
        }
        if let safe = safe, !safe.isEmpty {
            queryItems.append(URLQueryItem(name: "safe", value: safe))
        }
        if let tbm = tbm, !tbm.isEmpty {
            queryItems.append(URLQueryItem(name: "tbm", value: tbm))
        }
        if let tbs = tbs, !tbs.isEmpty {
            queryItems.append(URLQueryItem(name: "tbs", value: tbs))
        }
        if let as_qdr = as_qdr, !as_qdr.isEmpty {
            queryItems.append(URLQueryItem(name: "as_qdr", value: as_qdr))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw SerpError.badURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SerpError.badURL
        }
        
        guard httpResponse.statusCode == 200 else {
            throw SerpError.http(httpResponse.statusCode)
        }
        
        let serpResponse = try JSONDecoder().decode(SerpSearchResponse.self, from: data)
        return serpResponse.organic_results ?? []
    }
}
