import SwiftUI

struct LicenseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("📄 MIT License")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("DailyWebScanner is released under the MIT License")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // License Text
                VStack(alignment: .leading, spacing: 16) {
                    Text("MIT License")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Copyright (c) 2024 DailyWebScanner")
                        .font(.body)
                        .fontWeight(.semibold)
                    
                    Text("Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:")
                        .font(.body)
                    
                    Text("The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.")
                        .font(.body)
                    
                    Text("THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.")
                        .font(.body)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Divider()
                
                // What This Means
                VStack(alignment: .leading, spacing: 12) {
                    Text("🤔 What This Means")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("✅ You CAN:")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Text("• Use the software for any purpose (commercial or personal)")
                        Text("• Modify the source code")
                        Text("• Distribute copies of the software")
                        Text("• Sell the software")
                        Text("• Use it in proprietary applications")
                        
                        Text("📋 You MUST:")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("• Include the copyright notice")
                        Text("• Include the license text")
                        Text("• Not hold the authors liable")
                        
                        Text("❌ You CANNOT:")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Text("• Remove the copyright notice")
                        Text("• Sue the authors for any damages")
                        Text("• Claim the software as your own")
                    }
                    .font(.body)
                }
                
                Divider()
                
                // Additional Disclaimer
                VStack(alignment: .leading, spacing: 12) {
                    Text("⚠️ Additional Disclaimer")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("This is a hobby project for learning purposes. The user assumes full responsibility for their use of this software and any data they process. The developer assumes no liability for any consequences of using this software.")
                        .font(.body)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    
                    Text("See DISCLAIMER.md for complete legal information.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Open Source Philosophy
                VStack(alignment: .leading, spacing: 12) {
                    Text("🌟 Open Source Philosophy")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This project encourages:")
                        Text("• Free use and modification of the code")
                        Text("• Learning and experimentation")
                        Text("• Community contributions and suggestions")
                        Text("• Sharing improvements with others")
                        Text("• Educational purposes")
                    }
                    .font(.body)
                }
                
                Divider()
                
                // Footer
                VStack(alignment: .leading, spacing: 8) {
                    Text("For questions about this license, please refer to the MIT License documentation or contact the project maintainer.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Last Updated: October 18, 2024")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LicenseView()
}
