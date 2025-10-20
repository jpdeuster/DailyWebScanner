# Contributing to DailyWebScanner

**Welcome to our learning community!** 🎓

This is a **hobby project for learning purposes** - I explicitly encourage everyone to use, modify, and extend this code freely. Whether you're learning Swift, macOS development, or just want to experiment with search technology, you're welcome here!

## 🌟 Open Source Philosophy

- ✅ **Use the code freely** - Modify, extend, and adapt it for your own needs
- ✅ **Share your improvements** - Submit pull requests with your enhancements  
- ✅ **Suggest new features** - Propose ideas and planning suggestions
- ✅ **Learn together** - Use this project as a learning resource
- ✅ **No pressure** - This is a hobby project, contribute when you feel like it

Thank you for your interest in contributing to DailyWebScanner! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues
- Use the [GitHub Issues](https://github.com/jpdeuster/DailyWebScanner/issues) to report bugs
- Provide detailed information about the issue
- Include steps to reproduce the problem
- Specify your macOS version and Xcode version

### Suggesting Features
- **Feature requests coming soon** - GitHub Discussions will be available when repository is created
- **I welcome all suggestions!** - Even wild ideas are appreciated
- Describe the feature and its benefits
- Consider the impact on existing functionality
- **Planning suggestions are especially welcome** - Help shape the roadmap

### Code Contributions
1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Test thoroughly**
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to the branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

## 📋 Development Guidelines

### Code Style
- Follow Swift style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small

### Testing
- Test your changes thoroughly
- Ensure the app works with and without OpenAI integration
- Test in sandbox mode
- Verify network functionality

### Security
- Never commit API keys or sensitive data
- Use Keychain for secure storage
- Follow security best practices
- Review security implications of changes

## 🏗️ Development Setup

### Prerequisites
- macOS 14.0 or later
- Xcode 15.0 or later
- SerpAPI account (for testing)
- OpenAI account (optional, for testing AI features)

### Building
```bash
# Clone the repository (when available on GitHub)
# git clone https://github.com/jpdeuster/DailyWebScanner.git
# cd DailyWebScanner

# For now, use local development:
cd /path/to/DailyWebScanner

# Open in Xcode
open DailyWebScanner.xcodeproj

# Build from command line
xcodebuild -project DailyWebScanner.xcodeproj -scheme DailyWebScanner -configuration Debug build
```

### Testing Checklist
- [ ] App builds without errors
- [ ] Search functionality works with SerpAPI
- [ ] AI summarization works with OpenAI (if key provided)
- [ ] App works without OpenAI key (fallback to original snippets)
- [ ] Search history is saved and displayed
- [ ] Settings can be configured
- [ ] App runs in sandbox mode
- [ ] No sensitive data is exposed in logs

## 📁 Project Structure

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

## 🔒 Security Guidelines

### API Keys
- Never hardcode API keys in source code
- Use Keychain for secure storage
- Test with placeholder keys
- Document key requirements in README

### Data Privacy
- All data stored locally
- No cloud synchronization
- Respect user privacy
- Follow macOS privacy guidelines

## 📝 Pull Request Guidelines

### Before Submitting
- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] Documentation updated
- [ ] Security implications considered
- [ ] No sensitive data exposed

### PR Description
- Describe the changes made
- Explain the motivation
- List any breaking changes
- Include screenshots if UI changes
- Reference related issues

## 🐛 Bug Reports

When reporting bugs, please include:

1. **Environment**:
   - macOS version
   - Xcode version
   - App version

2. **Steps to Reproduce**:
   - Clear, numbered steps
   - Expected behavior
   - Actual behavior

3. **Additional Information**:
   - Screenshots if applicable
   - Console logs if relevant
   - System configuration

## 💡 Feature Requests

When suggesting features:

1. **Describe the feature**
2. **Explain the benefits**
3. **Consider implementation complexity**
4. **Think about user impact**
5. **Check for existing similar requests**

## 🎓 Learning & Experimentation

### **For Learners**
- **Start small** - Begin with simple modifications
- **Ask questions** - No question is too basic
- **Share your experiments** - Document what you tried and learned
- **Learn from others** - Study how others have modified the code

### **For Experimenters**
- **Try new approaches** - Experiment with different implementations
- **Test edge cases** - Push the boundaries of what's possible
- **Share discoveries** - Document interesting findings
- **Propose alternatives** - Suggest different ways to solve problems

### **For Contributors**
- **Document your learning** - Share what you learned while contributing
- **Explain your approach** - Help others understand your thinking
- **Be patient with feedback** - We're all learning together
- **Celebrate progress** - Share your achievements, no matter how small

## 📞 Getting Help

- **Issues**: [GitHub Issues](https://github.com/jpdeuster/DailyWebScanner/issues)
- **Discussions**: Coming soon on GitHub  
- **Security**: See [SECURITY.md](docs/legal/SECURITY.md) for security-related issues
- **Learning Questions**: Feel free to ask about Swift, macOS development, or any technical concepts

## 🙏 Recognition

Contributors will be recognized in:
- README.md acknowledgments
- Release notes
- GitHub contributors list

Thank you for contributing to DailyWebScanner! 🎉
