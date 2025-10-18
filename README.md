# DailyWebScanner

A modern macOS app for daily web searches with Google Search integration and optional AI-powered summarization.

[![Version](https://img.shields.io/badge/version-0.5--beta-orange.svg)](https://github.com/jpdeuster/DailyWebScanner)
[![macOS](https://img.shields.io/badge/macOS-14.0+-green.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 🌟 Features

- 🔍 **Google Web Search**: Full Google search integration via SerpAPI
- 🌐 **Web Search Engine**: Comprehensive web search capabilities
- 🤖 **AI Summaries**: Optional OpenAI integration for intelligent content summarization
- 📱 **Native macOS App**: Built with SwiftUI for modern macOS experience
- 🔒 **Security First**: Sandbox-compatible with secure Keychain storage
- 📊 **Search History**: Automatically saves and displays past searches
- 🎨 **Modern UI**: Responsive design with HTML rendering
- 🌍 **International**: Supports multiple languages and regions

## 🚀 Quick Start

### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later
- SerpAPI account (required)
- OpenAI account (optional)

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/jpdeuster/DailyWebScanner.git
cd DailyWebScanner
```

2. **Open in Xcode:**
```bash
open DailyWebScanner.xcodeproj
```

3. **Build and run** (⌘+R)

## ⚙️ Configuration

### SerpAPI Setup (Required)
1. Sign up at [SerpAPI](https://serpapi.com)
2. Get your API key from the dashboard
3. Add it in the app settings

### OpenAI Setup (Optional)
1. Create an account at [OpenAI](https://platform.openai.com)
2. Generate an API key
3. Add it in the app settings

> **Note**: Without an OpenAI key, the app will use original search snippets instead of AI summaries.

## 🔍 Search Capabilities

### **Google Web Search Integration**
- **Full Google Search**: Access to Google's complete web search index
- **Real-time Results**: Get the latest search results as they appear on Google
- **Rich Snippets**: Display enhanced search results with images, ratings, and structured data
- **Search Operators**: Support for Google's advanced search operators
- **Localized Results**: Search results in your preferred language and region

### **Web Search Features**
- **Comprehensive Coverage**: Search across the entire web, not just specific sites
- **Fresh Content**: Access to the most recent web content
- **Diverse Sources**: Results from websites, blogs, news sites, academic sources, and more
- **Quality Ranking**: Google's sophisticated ranking algorithm ensures relevant results
- **Mobile-friendly**: Results optimized for both desktop and mobile content

## 📖 Usage

1. **Start Searching**: Enter your search query and press Enter
2. **View Results**: Browse Google search results with intelligent AI summaries
3. **Explore History**: Access your past searches anytime
4. **Customize Settings**: Configure API keys and search parameters

## 🏗️ Architecture

### Core Components
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Local data persistence
- **SerpAPI**: Google web search integration
- **Google Search**: Full Google search engine access
- **OpenAI**: AI-powered summarization
- **WebKit**: HTML content rendering
- **Keychain**: Secure credential storage

### Project Structure
```
DailyWebScanner/
├── DailyWebScannerApp.swift      # App entry point
├── ContentView.swift             # Main UI
├── SearchViewModel.swift         # Search logic
├── SerpAPIClient.swift           # SerpAPI integration
├── OpenAIClient.swift            # OpenAI integration
├── HTMLRenderer.swift            # HTML rendering
├── WebView.swift                 # WebKit integration
├── SettingsView.swift            # Settings interface
├── KeychainHelper.swift          # Secure storage
├── SearchRecord.swift            # Data model
├── SearchResult.swift            # Result model
└── DailyWebScanner.entitlements  # Sandbox permissions
```

## 🔧 Development

### Building
```bash
xcodebuild -project DailyWebScanner.xcodeproj -scheme DailyWebScanner -configuration Debug build
```

### Testing
The app has been tested with:
- ✅ Google web search via SerpAPI + OpenAI integration
- ✅ Google web search via SerpAPI without OpenAI
- ✅ Sandbox mode
- ✅ Network access
- ✅ Keychain storage
- ✅ Various search queries and result types
- ✅ International search results

### Requirements
- **Minimum macOS**: 14.0
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **Dependencies**: None (uses system frameworks only)

## 🔒 Security

- **Sandbox Isolation**: App runs in isolated environment
- **Keychain Storage**: API keys stored securely
- **HTTPS Only**: All network communication encrypted
- **Minimal Permissions**: Only necessary system access

See [SECURITY.md](SECURITY.md) for detailed security information.

## 🤝 Contributing

**This is a hobby project for learning purposes!** I explicitly encourage everyone to:

- ✅ **Use the code freely** - Modify, extend, and adapt it for your own needs
- ✅ **Share improvements** - Submit pull requests with your enhancements
- ✅ **Suggest features** - Propose new ideas and planning suggestions
- ✅ **Learn together** - Use this project as a learning resource

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Development Guidelines
- Follow Swift style guidelines
- Add tests for new features
- Update documentation
- Ensure security best practices
- **Share your learning journey** - Document what you learned while contributing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer & Data Responsibility

**Important Legal Notice:**

- **No Warranty**: This software is provided "as is" without any warranty or guarantee
- **User Responsibility**: You are solely responsible for your use of this application and any data you process
- **No Liability**: The developer assumes no responsibility for any consequences of using this software
- **Data Usage**: You are responsible for complying with all applicable laws and regulations regarding data processing
- **API Keys**: You are responsible for the security and proper use of your API keys
- **Search Results**: You are responsible for how you use, store, and process search results
- **Privacy**: You are responsible for protecting your own privacy and that of others
- **Compliance**: Ensure your use complies with terms of service of external APIs (SerpAPI, OpenAI, etc.)

**This is a hobby project for learning purposes. Use at your own risk.**

See [DISCLAIMER.md](DISCLAIMER.md) for complete legal information.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/jpdeuster/DailyWebScanner/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jpdeuster/DailyWebScanner/discussions)
- **Security**: See [SECURITY.md](SECURITY.md) for security-related issues

## 🗺️ Roadmap

### 🚧 Current Development (Beta 0.5)
- [x] Google web search integration via SerpAPI
- [x] Full web search capabilities
- [x] Optional OpenAI integration
- [x] Search history with SwiftData
- [x] Sandbox security implementation
- [x] Modern SwiftUI interface

### 📋 Upcoming Releases

#### **v0.6 - Enhanced User Experience**
- [ ] **Local SQL Database**: SQLite integration for search results storage
- [ ] **Search Filters**: Date range, language, region filters
- [ ] **Result Sorting**: Sort by relevance, date, source
- [ ] **Keyboard Shortcuts**: Quick access and navigation
- [ ] **Dark Mode**: Complete dark mode support
- [ ] **Accessibility**: VoiceOver and accessibility improvements

#### **v0.7 - Export & Sharing**
- [ ] **PDF Export**: Export search results to PDF
- [ ] **Markdown Export**: Export results in Markdown format
- [ ] **Share Integration**: Native macOS sharing
- [ ] **Print Support**: Print search results
- [ ] **Bookmark Management**: Save and organize bookmarks

#### **v0.8 - Advanced Search**
- [ ] **Custom Search Engines**: Bing, DuckDuckGo, Yandex support
- [ ] **Search Operators**: Advanced search syntax support
- [ ] **Image Search**: Visual search capabilities
- [ ] **News Search**: Dedicated news search mode
- [ ] **Academic Search**: Scholar and academic sources

#### **v0.9 - AI Enhancement**
- [ ] **Multiple AI Providers**: Claude, Gemini, local models
- [ ] **Custom AI Prompts**: User-defined summarization prompts
- [ ] **AI Comparison**: Compare summaries from different AI providers
- [ ] **Smart Categorization**: AI-powered result categorization
- [ ] **Trend Analysis**: AI-powered trend detection

#### **v1.0 - Production Ready**
- [ ] **Performance Optimization**: Faster search and rendering
- [ ] **Error Handling**: Comprehensive error management
- [ ] **User Onboarding**: Interactive tutorial
- [ ] **Settings Migration**: Import/export settings
- [ ] **Stability**: Production-ready stability

#### **v1.1 - Collaboration**
- [ ] **Team Sharing**: Share search results with teams
- [ ] **Collaborative Filtering**: Shared search preferences
- [ ] **Comments System**: Add notes to search results
- [ ] **Search Collections**: Organize searches into collections
- [ ] **Export Templates**: Custom export formats

#### **v1.2 - Advanced Features**
- [ ] **Search Automation**: Scheduled searches
- [ ] **Alert System**: Notifications for new results
- [ ] **API Integration**: Third-party service integration
- [ ] **Plugin System**: Extensible architecture
- [ ] **Advanced Analytics**: Search pattern analysis

#### **v2.0 - Cloud & Sync**
- [ ] **Cloud Synchronization**: iCloud sync (optional)
- [ ] **Cross-Device**: iPhone/iPad companion app
- [ ] **Web Dashboard**: Browser-based interface
- [ ] **Team Workspaces**: Collaborative workspaces
- [ ] **Enterprise Features**: SSO, admin controls

### 🎯 Long-term Vision
- [ ] **AI Research Assistant**: Advanced research capabilities
- [ ] **Knowledge Graph**: Build personal knowledge networks
- [ ] **Voice Search**: Voice-activated search
- [ ] **AR Integration**: Augmented reality search
- [ ] **Machine Learning**: Personalized search algorithms

## 🙏 Acknowledgments

- [SerpAPI](https://serpapi.com) for Google web search integration
- [Google](https://google.com) for providing comprehensive web search capabilities
- [OpenAI](https://openai.com) for AI summarization
- Apple for SwiftUI and macOS frameworks

---

**Made with ❤️ for macOS**

*DailyWebScanner - Your intelligent search companion*
