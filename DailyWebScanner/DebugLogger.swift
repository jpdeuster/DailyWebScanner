import Foundation
import os.log

/// Centralized debug logging for DailyWebScanner
class DebugLogger {
    static let shared = DebugLogger()
    
    private let logger = Logger(subsystem: "de.deusterdevelopment.DailyWebScanner", category: "Debug")
    private let networkLogger = Logger(subsystem: "de.deusterdevelopment.DailyWebScanner", category: "Network")
    private let webKitLogger = Logger(subsystem: "de.deusterdevelopment.DailyWebScanner", category: "WebKit")
    private let searchLogger = Logger(subsystem: "de.deusterdevelopment.DailyWebScanner", category: "Search")
    private let securityLogger = Logger(subsystem: "de.deusterdevelopment.DailyWebScanner", category: "Security")
    
    private init() {}
    
    // MARK: - General Debug Logging
    
    func logAppStart() {
        logger.info("🚀 DailyWebScanner starting up")
        logSystemInfo()
    }
    
    func logAppShutdown() {
        logger.info("🛑 DailyWebScanner shutting down")
    }
    
    func logWindowCreation() {
        logger.info("🪟 Main window created and displayed")
    }
    
    func logUserInterfaceReady() {
        logger.info("🎨 User interface ready for interaction")
    }
    
    func logSearchFieldFocus() {
        logger.info("🔍 Search field focused by user")
    }
    
    func logSearchTextEntered(_ text: String) {
        logger.info("⌨️ User entered search text: '\(text)'")
    }
    
    func logSearchButtonPressed() {
        logger.info("🔘 Search button pressed by user")
    }
    
    func logSettingsOpened() {
        logger.info("⚙️ Settings window opened by user")
    }
    
    func logSettingsClosed() {
        logger.info("⚙️ Settings window closed by user")
    }
    
    private func logSystemInfo() {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        logger.info("📱 System: macOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")
        // Check if app is sandboxed by looking for entitlements
        let isSandboxed = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") != nil
        logger.info("🔧 Sandbox: \(isSandboxed ? "Enabled" : "Disabled")")
    }
    
    // MARK: - Network Debug Logging
    
    func logNetworkRequest(url: String, method: String = "GET") {
        networkLogger.info("🌐 Network Request: \(method) \(url)")
    }
    
    func logNetworkResponse(url: String, statusCode: Int, responseTime: TimeInterval) {
        networkLogger.info("📡 Network Response: \(statusCode) - \(url) (\(String(format: "%.2f", responseTime))s)")
    }
    
    func logNetworkError(url: String, error: Error) {
        networkLogger.error("❌ Network Error: \(url) - \(error.localizedDescription)")
    }
    
    func logSandboxNetworkIssue() {
        networkLogger.warning("⚠️ Sandbox network restriction detected")
        networkLogger.warning("🔒 networkd_settings_read_from_file - Sandbox preventing access to networkd settings")
    }
    
    /// Detailed logging for URLSession URLError with CFNetwork details if present.
    /// - Parameters:
    ///   - url: The URL that failed.
    ///   - code: URLError.Code
    ///   - underlying: NSError cast of URLError to extract userInfo details (optional).
    ///   - path: Value of _NSURLErrorNWPathKey (optional).
    ///   - resolutionReport: Value of _NSURLErrorNWResolutionReportKey (optional).
    func logNetworkURLError(url: URL, code: URLError.Code, underlying: NSError?, path: String?, resolutionReport: String?) {
        let codeDesc = "\(code.rawValue) (\(String(describing: code)))"
        var components: [String] = []
        components.append("URL=\(url.absoluteString)")
        components.append("URLError=\(codeDesc)")
        
        if let underlying {
            // CFNetwork domain/code – try both public and underscored keys
            let cfDomain = (underlying.userInfo["kCFStreamErrorDomainKey"] as? Int)
                ?? (underlying.userInfo["_kCFStreamErrorDomainKey"] as? Int)
            let cfCode = (underlying.userInfo["kCFStreamErrorCodeKey"] as? Int)
                ?? (underlying.userInfo["_kCFStreamErrorCodeKey"] as? Int)
            if let d = cfDomain, let c = cfCode {
                components.append("CFNetwork=\(d)/\(c)")
            }
            // Standard domain/code
            components.append("NSError=\(underlying.domain)(\(underlying.code))")
            
            // Try to pull path/resolution from userInfo if not provided by caller
            if path == nil, let p = underlying.userInfo["_NSURLErrorNWPathKey"] as? String, !p.isEmpty {
                components.append("Path=\(p)")
            }
            if resolutionReport == nil, let r = underlying.userInfo["_NSURLErrorNWResolutionReportKey"] as? String, !r.isEmpty {
                components.append("Resolution=\(r)")
            }
        }
        
        if let path, !path.isEmpty {
            components.append("Path=\(path)")
        }
        if let resolutionReport, !resolutionReport.isEmpty {
            components.append("Resolution=\(resolutionReport)")
        }
        
        networkLogger.error("❌ URLSession URLError: \(components.joined(separator: " | "))")
    }
    
    /// Specialized DNS failure logging, when you can identify CFNetwork domain/code.
    func logDNSFailure(host: String, cfDomain: Int?, cfCode: Int?, details: String?) {
        var parts: [String] = ["Host=\(host)"]
        if let d = cfDomain, let c = cfCode {
            parts.append("CFNetwork=\(d)/\(c)")
        }
        if let details, !details.isEmpty {
            parts.append("Details=\(details)")
        }
        networkLogger.error("🧩 DNS Failure: \(parts.joined(separator: " | "))")
    }
    
    /// Log non-2xx HTTP status for easier correlation.
    func logHTTPStatus(url: URL, status: Int) {
        networkLogger.warning("📡 HTTP Status: \(status) - \(url.absoluteString)")
    }
    
    /// Optional helper to log only the network path string.
    func logNetworkPathInfo(_ path: String) {
        networkLogger.info("🛣️ Network Path: \(path)")
    }
    
    // MARK: - WebKit Debug Logging
    
    func logWebKitStart() {
        webKitLogger.info("🌐 WebKit initializing")
    }
    
    func logWebKitProcessCrash(pid: Int, reason: String) {
        webKitLogger.error("💥 WebKit Process Crash: PID \(pid) - \(reason)")
    }
    
    func logWebKitNavigationStart(url: String) {
        webKitLogger.info("🧭 WebKit Navigation: \(url)")
    }
    
    func logWebKitNavigationComplete(url: String) {
        webKitLogger.info("✅ WebKit Navigation Complete: \(url)")
    }
    
    func logWebKitNavigationError(url: String, error: Error) {
        webKitLogger.error("❌ WebKit Navigation Error: \(url) - \(error.localizedDescription)")
    }
    
    func logWebKitGPUProcessCrash() {
        webKitLogger.error("🎮 GPU Process Crash detected")
    }
    
    func logWebKitNetworkProcessCrash() {
        webKitLogger.error("🌐 Network Process Crash detected")
    }
    
    func logWebKitAssertionError(pid: Int, assertion: String) {
        webKitLogger.error("⚠️ WebKit Assertion Error: PID \(pid) - \(assertion)")
    }
    
    // MARK: - Search Debug Logging
    
    func logSearchStart(query: String) {
        searchLogger.info("🔍 Search Started: '\(query)'")
    }
    
    func logSearchInitiated(query: String) {
        searchLogger.info("🚀 Search process initiated for: '\(query)'")
    }
    
    func logSearchViewModelReady() {
        searchLogger.info("📊 SearchViewModel initialized and ready")
    }
    
    func logSearchTaskCreated() {
        searchLogger.info("⚡ Search task created and started")
    }
    
    func logSearchTaskCancelled() {
        searchLogger.info("🛑 Search task cancelled")
    }
    
    func logSearchTaskCompleted() {
        searchLogger.info("✅ Search task completed successfully")
    }
    
    func logSearchComplete(query: String, resultCount: Int) {
        searchLogger.info("✅ Search Complete: '\(query)' - \(resultCount) results")
    }
    
    func logSearchError(query: String, error: Error) {
        searchLogger.error("❌ Search Error: '\(query)' - \(error.localizedDescription)")
    }
    
    func logSearchStateChange(_ state: String) {
        searchLogger.info("🔄 Search state changed: \(state)")
    }
    
    func logSearchParameters(query: String, language: String, region: String, count: Int) {
        searchLogger.info("🔧 Search Parameters: Query: '\(query)', Language: '\(language)', Region: '\(region)', Count: \(count)")
    }
    
    func logAPIPayload(url: String, parameters: [URLQueryItem]) {
        var paramString = ""
        for param in parameters {
            if param.name != "api_key" { // Don't log API key for security
                paramString += "\(param.name)=\(param.value ?? ""), "
            } else {
                paramString += "\(param.name)=[HIDDEN], "
            }
        }
        if !paramString.isEmpty {
            paramString = String(paramString.dropLast(2)) // Remove last ", "
        }
        searchLogger.info("🌐 API Payload: \(url)")
        searchLogger.info("📋 API Parameters: \(paramString)")
    }
    
    func logSearchParametersExtended(query: String, language: String, region: String, count: Int, 
                                    location: String?, safe: String?, tbm: String?, tbs: String?, as_qdr: String?) {
        var params = "Query: '\(query)', Language: '\(language)', Region: '\(region)', Count: \(count)"
        
        if let location = location, !location.isEmpty {
            params += ", Location: '\(location)'"
        }
        if let safe = safe, !safe.isEmpty {
            params += ", Safe: '\(safe)'"
        }
        if let tbm = tbm, !tbm.isEmpty {
            params += ", Type: '\(tbm)'"
        }
        if let tbs = tbs, !tbs.isEmpty {
            params += ", Time: '\(tbs)'"
        }
        if let as_qdr = as_qdr, !as_qdr.isEmpty {
            params += ", Date: '\(as_qdr)'"
        }
        
        searchLogger.info("🔧 Extended Search Parameters: \(params)")
    }
    
    func logSerpAPICall(query: String, apiKeyPresent: Bool) {
        searchLogger.info("🔍 SerpAPI Call: '\(query)' - API Key: \(apiKeyPresent ? "Present" : "Missing")")
    }
    
    func logOpenAICall(query: String, apiKeyPresent: Bool) {
        searchLogger.info("🤖 OpenAI Call: '\(query)' - API Key: \(apiKeyPresent ? "Present" : "Missing")")
    }
    
    // MARK: - Security Debug Logging
    
    func logKeychainAccess(operation: String, key: String, success: Bool) {
        securityLogger.info("🔐 Keychain \(operation): \(key) - \(success ? "Success" : "Failed")")
    }
    
    func logSandboxEntitlement(entitlement: String, granted: Bool) {
        securityLogger.info("🛡️ Sandbox Entitlement: \(entitlement) - \(granted ? "Granted" : "Denied")")
    }
    
    func logSecurityWarning(message: String) {
        securityLogger.warning("⚠️ Security Warning: \(message)")
    }
    
    // MARK: - Performance Debug Logging
    
    func logPerformanceStart(operation: String) {
        logger.info("⏱️ Performance: \(operation) started")
    }
    
    func logPerformanceEnd(operation: String, duration: TimeInterval) {
        logger.info("⏱️ Performance: \(operation) completed in \(String(format: "%.3f", duration))s")
    }
    
    // MARK: - Error Handling
    
    func logCriticalError(component: String, error: Error) {
        logger.critical("💥 Critical Error in \(component): \(error.localizedDescription)")
    }
    
    func logWarning(component: String, message: String) {
        logger.warning("⚠️ Warning in \(component): \(message)")
    }
    
    func logInfo(component: String, message: String) {
        logger.info("ℹ️ Info in \(component): \(message)")
    }
}

// MARK: - Convenience Extensions

extension DebugLogger {
    func logSearchViewModelAction(_ action: String, details: String = "") {
        searchLogger.info("🔍 SearchViewModel: \(action)\(details.isEmpty ? "" : " - \(details)")")
    }
    
    func logWebViewAction(_ action: String, details: String = "") {
        webKitLogger.info("🌐 WebView: \(action)\(details.isEmpty ? "" : " - \(details)")")
    }
    
    func logNetworkAction(_ action: String, details: String = "") {
        networkLogger.info("🌐 Network: \(action)\(details.isEmpty ? "" : " - \(details)")")
    }
}
