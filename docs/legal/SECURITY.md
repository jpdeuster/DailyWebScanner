# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in this project, please **DO NOT** report it publicly via GitHub Issues.

Instead, contact us directly at: [Your Email Address]

## Security Measures

### API Keys and Sensitive Data
- ✅ **No hardcoded API keys** in source code
- ✅ **Keychain integration** for secure API key storage
- ✅ **Sandbox permissions** for minimal system access
- ✅ **Entitlements file** for controlled permissions

### Data Privacy
- 🔒 **Local storage**: All data is stored locally in the Keychain
- 🔒 **No cloud synchronization**: No data is sent to external servers
- 🔒 **Sandbox isolation**: App runs in isolated environment

### Network Security
- 🔐 **HTTPS-only**: All API calls use encrypted connections
- 🔐 **API key masking**: Keys are not displayed in logs or URLs
- 🔐 **Minimal permissions**: Only necessary network permissions

## Scope of Responsibility

This project is responsible for the security of the following components:

- ✅ **App Code**: SwiftUI application
- ✅ **API Integration**: SerpAPI and OpenAI
- ✅ **Data Persistence**: SwiftData and Keychain
- ✅ **Network Communication**: URLSession

## Out of Scope

- ❌ **External APIs**: SerpAPI, OpenAI
- ❌ **Operating System**: macOS Sandbox
- ❌ **Third-party Services**: GitHub, etc.

## Best Practices for Developers

1. **Never commit API keys**
2. **Use environment variables for testing**
3. **Regular security updates**
4. **Code reviews for security-critical changes**

## Known Security Considerations

- **Sandbox restrictions**: App can only access explicitly allowed resources
- **Keychain access**: Only the app itself can access stored keys
- **Network isolation**: No local network services

---

**Last Updated**: October 2024
