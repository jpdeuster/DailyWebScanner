# DailyWebScanner

[![Version](https://img.shields.io/badge/version-0.5.5-orange.svg)](https://github.com/jpdeuster/DailyWebScanner)
[![macOS](https://img.shields.io/badge/macOS-14.0+-green.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 🎯 Overview

DailyWebScanner is a powerful macOS application for comprehensive web search, content analysis, and article storage. Built with SwiftUI and SwiftData, it provides intelligent search capabilities with AI-powered content extraction and analysis.

## 📁 Project Structure

### **📱 Application**
- **SwiftUI Interface** - Modern, native macOS application
- **SwiftData Database** - Local data persistence with relationships
- **Multi-Window Support** - Separate windows for different views
- **AI Integration** - OpenAI client code present (not tested) support

### **📚 Documentation**
- **[Project Documentation](docs/project/)** - Main project information
- **[Architecture Documentation](docs/architecture/)** - Technical architecture details
- **[Development Documentation](docs/development/)** - Development roadmap and planning
- **[Legal Documentation](docs/legal/)** - Legal information and security

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

## 🌟 Features

- 🔍 **Google Web Search**: Full Google search integration via SerpAPI
- 🌐 **Web Search Engine**: Comprehensive web search capabilities
- 🤖 **AI Summaries**: Optional OpenAI integration for intelligent content summarization
- 📱 **Native macOS App**: Built with SwiftUI for modern macOS experience
- 🔒 **Security First**: Sandbox-compatible with secure Keychain storage
- 📊 **Search History**: Automatically saves and displays past searches
- 📝 **Clean Text**: Clean article text with line breaks
- 🌍 **International**: Search parameters support multiple languages and regions
- 🏷️ **Smart Tagging**: Organize articles with custom tags and tag management
- 🎯 **Quality Control**: Intelligent content filtering with customizable patterns

## 📊 Current Features

### **✅ Implemented (Beta 0.5.5)**
- **Google Search Integration** - Via SerpAPI
- **Content Analysis** - Full article extraction with images
- **AI Integration** - OpenAI client code present (not tested)
- **Per-Search Parameters** - Dynamic search configuration
- **Multi-Window Interface** - Separate windows for different views
- **Search History** - Basic search record storage
- **API Status Bar** - In ContentView: SerpAPI/OpenAI status + quick test and SerpAPI credits
- **Plain Text Focus** - Focus on clean text with line breaks
- **Plain Text Files** - Optional saving as .txt per article
- **Robust DB Size** - Detect SwiftData store/sqlite with WAL/SHM and report accurately
- **Info Tab Images** - Show thumbnails or "No pics available" in article Info tab
- **JSON Persistence** - Persist extracted links, videos, and metadata as JSON
- **Smart Tagging System** - Custom tags for article organization with tag management
- **Quality Control** - Content quality assessment with customizable filtering patterns
- **Modern UI** - Consistent, professional interface across all views

### **🔄 Planned Features**
- **Automated Search System** - Scheduled searches with timers (v0.7.0)
- **Smart Categorization** - AI-powered content classification (v0.8.0)
- **Export Functionality** - Data export in various formats (v0.9.0)
- **Cloud Integration** - iCloud sync for data synchronization (v0.9.0)

## 🏗️ Architecture

### **📁 Project Organization**
```
DailyWebScanner/
├── 📁 Models/          # SwiftData models
├── 📁 Views/           # SwiftUI views
├── 📁 ViewModels/      # Business logic
├── 📁 Services/        # API integrations
├── 📁 Utils/           # Helper functions
└── 📁 Extensions/      # Swift extensions
```

### **🔧 Technology Stack**
- **SwiftUI** - Modern UI framework
- **SwiftData** - Local data persistence with relationships
- **SerpAPI** - Google search integration
- **OpenAI API** - AI-powered content analysis
- **macOS Sandbox** - Security and privacy
- **Quality Assessment** - Heuristic-based content filtering
- **Tag Management** - Many-to-many relationships for article organization

## 📈 Development Status

- **Current Version**: Beta 0.5.5
- **Status**: Fully functional with core features + tagging & quality control
- **Next Release**: v0.6.0 (Automated Search System)
- **Target**: App Store v1.0.0

## 📖 Documentation

### **📋 Project Information**
- [CHANGELOG](docs/project/CHANGELOG.md) - Version history
- [CONTRIBUTING](docs/project/CONTRIBUTING.md) - Contribution guidelines

### **🏗️ Architecture**
- [Current Architecture](docs/architecture/INFO_CURRENT_ARCHITECTURE.md) - Technical architecture
- [Content Analysis Concept](docs/architecture/INFO_CONTENT_ANALYSIS_CONCEPT.md) - Content analysis system

### **🚀 Development**
- [Development Roadmap](docs/development/ROADMAP.md) - Development roadmap

### **⚖️ Legal**
- [Disclaimer](docs/legal/DISCLAIMER.md) - Legal disclaimer
- [Security](docs/legal/SECURITY.md) - Security information

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

## 🔒 Security

- **Sandbox Isolation**: App runs in isolated environment
- **Keychain Storage**: API keys stored securely
- **HTTPS Only**: All network communication encrypted
- **Minimal Permissions**: Only necessary system access

See [SECURITY.md](docs/legal/SECURITY.md) for detailed security information.

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

See [DISCLAIMER.md](docs/legal/DISCLAIMER.md) for complete legal information.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/jpdeuster/DailyWebScanner/issues)
- **Discussions**: Coming soon on GitHub
- **Contact**: [jp@deuster.eu](mailto:jp@deuster.eu)
- **Security**: See [SECURITY.md](docs/legal/SECURITY.md) for security-related issues

## 🙏 Acknowledgments

- [SerpAPI](https://serpapi.com) for Google web search integration
- [Google](https://google.com) for providing comprehensive web search capabilities
- [OpenAI](https://openai.com) for AI summarization
- Apple for SwiftUI and macOS frameworks

---

**Made with ❤️ for macOS**

*DailyWebScanner - Your intelligent search companion*