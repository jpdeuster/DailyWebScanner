# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0-beta] - 2025-10-21

### Added
- **Initial Beta Release** of DailyWebScanner
- Web search functionality using SerpAPI with multi-page results
- Complete content extraction and article storage system
- LinkRecord system for individual article management
- Per-search parameter configuration (language, region, location, etc.)
- Multi-window interface with separate views for different functions
- AI Overview integration from Google search results
- Optional AI-powered summarization with OpenAI integration
- Search history with local storage using SwiftData
- Modern SwiftUI interface with HTML rendering
- Secure API key storage using Keychain
- Sandbox-compatible macOS app
- Professional project structure with organized folders
- Comprehensive documentation and security measures

### Features
- 🔍 **Google Web Search**: Full Google search integration via SerpAPI with multi-page results
- 📰 **Article Management**: Complete article storage with LinkRecord system
- 🎛️ **Per-Search Parameters**: Dynamic configuration for each search
- 🪟 **Multi-Window Interface**: Separate windows for search, articles, and settings
- 🤖 **AI Integration**: OpenAI client code present (not tested)
- 📊 **Search History**: Basic search record storage (SwiftData)
- 🎨 **Modern UI**: SwiftUI-based interface with HTML rendering
- 🌍 **International**: Search parameters support multiple languages and regions
- 🔒 **Security First**: Sandbox-compatible with secure Keychain storage
- 📁 **Professional Structure**: Organized folder structure for maintainability

### Technical Details
- **Framework**: SwiftUI, SwiftData
- **APIs**: SerpAPI, OpenAI
- **Security**: macOS App Sandbox, Keychain
- **Minimum macOS**: 14.0+
- **Dependencies**: None (uses system frameworks only)

### Security
- Sandbox isolation for enhanced security
- Secure API key storage in Keychain
- HTTPS-only network communication
- Minimal system permissions
- No hardcoded credentials in source code

### Known Issues (Beta)
- Some Swift 6 Sendable warnings (non-critical)
- WebKit crashes in certain sandbox configurations (mitigated)
- Limited error handling for network timeouts

---

## [Unreleased]

## [0.5.5] - 2025-10-22

### Added
- API Status Bar in ContentView (SerpAPI/OpenAI) with quick test and SerpAPI credits
- App Settings toggle to open Articles window automatically on launch
- Images in Info tab: thumbnails preview or "No pics available"
- JSON persistence for extracted links, videos and metadata

### Improved
- Robust SwiftData size detection (store/sqlite + WAL/SHM); logs downgraded to info on missing paths
- Progress UI wording and localized English strings

### Fixed
- Graceful handling for ModelContainer initialization error (alert + exit)
- Image display reliability (data: URIs, unsupported formats transcoded)

### Notes
- This is still a Beta; OpenAI client present but not fully exercised.

### v0.7.0 - Automated Search System
- [x] **Enable/Disable Toggle**: Individual control for each automated search
- [x] **Real-time Timer Display**: Live countdown to next search execution
- [x] **Automatic Execution**: Searches run automatically at scheduled times
- [x] **Persistent Timers**: Timer system survives app restarts
- [x] **Global Timer Management**: Centralized monitoring of all enabled searches
- [x] **Execution Tracking**: Count and timestamp of search executions
- [x] **Debug Logging**: Comprehensive logging for automated search operations

### v0.6.0 - HTML Viewer for Articles
- [ ] **HTML Article Viewer**: Dedicated viewer for article content
- [ ] **Enhanced Article Display**: Better formatting and readability
- [ ] **Content Navigation**: Easy browsing through article list
- [ ] **Search Integration**: Seamless connection with search results

### v0.8.0 - Smart Categorization
- [ ] **AI-Powered Content Classification**: Automatic content categorization
- [ ] **Advanced Tagging System**: Custom tag creation and management
- [ ] **Content Insights**: Quality scoring and source reliability analysis
- [ ] **Smart Recommendations**: AI-powered content suggestions
- [ ] **Tag-based Filtering**: Filter content by tags
- [ ] **Content Similarity**: Find similar articles

### v0.8.0 - Export & Integration
- [ ] **Export Functionality**: Export to CSV, JSON, PDF, HTML
- [ ] **Cloud Integration**: iCloud sync for data synchronization
- [ ] **External Integrations**: Browser extension support
- [ ] **API for Third-party**: Webhook support for automation
- [ ] **Backup & Restore**: Data backup and restore functionality
- [ ] **Cross-device Sync**: Share data across devices

### v0.9.0 - Advanced AI Features
- [ ] **Intelligent Content Analysis**: Sentiment analysis and topic trends
- [ ] **Personalized Recommendations**: AI-powered search suggestions
- [ ] **Advanced Analytics Dashboard**: Visual analytics and charts
- [ ] **Multi-language Analysis**: Content analysis in multiple languages
- [ ] **Smart Query Completion**: AI-powered search query suggestions
- [ ] **Content Summarization**: Improved AI summarization

### v1.0.0 - App Store Release
- [ ] **App Store Submission**: Complete App Store submission process
- [ ] **App Store Optimization**: Screenshots, descriptions, keywords
- [ ] **Final Testing**: Comprehensive testing on all supported devices
- [ ] **Privacy Policy**: Complete privacy policy and data handling
- [ ] **Terms of Service**: App Store terms and conditions compliance
- [ ] **Accessibility**: Full accessibility support for all users

### v1.1.0 - iPad & iCloud Support
- [ ] **iPad Support**: Universal app for macOS and iPad
- [ ] **iCloud Integration**: Cross-device data synchronization
- [ ] **Touch Interface**: Optimized for iPad touch interactions
- [ ] **Universal Purchase**: Single purchase for macOS and iPad
- [ ] **Cross-Device Sync**: Seamless data sharing between devices
- [ ] **iPad-Specific UI**: Optimized layouts for tablet interface

