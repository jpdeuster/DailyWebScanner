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
    
    func logSearchComplete(query: String, resultCount: Int) {
        searchLogger.info("✅ Search Complete: '\(query)' - \(resultCount) results")
    }
    
    func logSearchError(query: String, error: Error) {
        searchLogger.error("❌ Search Error: '\(query)' - \(error.localizedDescription)")
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
