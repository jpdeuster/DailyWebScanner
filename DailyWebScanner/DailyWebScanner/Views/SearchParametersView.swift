//
//  SearchParametersView.swift
//  DailyWebScanner
//
//  Created by Jörg-Peter Deuster on 19.10.25.
//

import SwiftUI

struct SearchParametersView: View {
    @State private var language: String = ""
    @State private var region: String = ""
    @State private var location: String = ""
    @State private var safeSearch: String = ""
    @State private var searchType: String = ""
    @State private var timeRange: String = ""
    @State private var dateRange: String = ""
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with toggle
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.blue)
                    Text("Search Parameters")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                VStack(spacing: 16) {
                    // Basic Parameters
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Basic Settings")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            // Language
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Language")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $language) {
                                    Text("Any").tag("")
                                    Text("Deutsch (de)").tag("de")
                                    Text("English (en)").tag("en")
                                    Text("Français (fr)").tag("fr")
                                    Text("Español (es)").tag("es")
                                    Text("Italiano (it)").tag("it")
                                    Text("Português (pt)").tag("pt")
                                    Text("Nederlands (nl)").tag("nl")
                                    Text("Русский (ru)").tag("ru")
                                    Text("中文 (zh)").tag("zh")
                                    Text("日本語 (ja)").tag("ja")
                                    Text("한국어 (ko)").tag("ko")
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Region
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Region")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $region) {
                                    Text("Any").tag("")
                                    Text("Deutschland (de)").tag("de")
                                    Text("United States (us)").tag("us")
                                    Text("United Kingdom (uk)").tag("uk")
                                    Text("France (fr)").tag("fr")
                                    Text("Spain (es)").tag("es")
                                    Text("Italy (it)").tag("it")
                                    Text("Canada (ca)").tag("ca")
                                    Text("Australia (au)").tag("au")
                                    Text("Austria (at)").tag("at")
                                    Text("Switzerland (ch)").tag("ch")
                                    Text("Netherlands (nl)").tag("nl")
                                    Text("Japan (jp)").tag("jp")
                                    Text("China (cn)").tag("cn")
                                    Text("India (in)").tag("in")
                                    Text("Brazil (br)").tag("br")
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    
                    // Advanced Parameters
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Advanced Settings")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            // Location
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Location")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $location) {
                                    Text("Any").tag("")
                                    Text("Germany").tag("Germany")
                                    Text("United States").tag("United States")
                                    Text("United Kingdom").tag("United Kingdom")
                                    Text("France").tag("France")
                                    Text("Spain").tag("Spain")
                                    Text("Italy").tag("Italy")
                                    Text("Canada").tag("Canada")
                                    Text("Australia").tag("Australia")
                                    Text("Japan").tag("Japan")
                                    Text("China").tag("China")
                                    Text("India").tag("India")
                                    Text("Brazil").tag("Brazil")
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Safe Search
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Safe Search")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $safeSearch) {
                                    Text("Any").tag("")
                                    Text("Off").tag("off")
                                    Text("Active").tag("active")
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Search Type
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Search Type")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $searchType) {
                                    Text("All").tag("")
                                    Text("Images").tag("isch")
                                    Text("Videos").tag("vid")
                                    Text("News").tag("nws")
                                    Text("Books").tag("bks")
                                    Text("Shopping").tag("shop")
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Time Range
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time Range")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $timeRange) {
                                    Text("Any Time").tag("")
                                    Text("Past Hour").tag("qdr:h")
                                    Text("Past Day").tag("qdr:d")
                                    Text("Past Week").tag("qdr:w")
                                    Text("Past Month").tag("qdr:m")
                                    Text("Past Year").tag("qdr:y")
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    
                    // Reset Button
                    HStack {
                        Spacer()
                        
                        Button("Reset to Defaults") {
                            resetToDefaults()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func resetToDefaults() {
        withAnimation(.easeInOut(duration: 0.2)) {
            language = ""
            region = ""
            location = ""
            safeSearch = ""
            searchType = ""
            timeRange = ""
            dateRange = ""
        }
    }
    
    // Public methods to get current parameters
    func getParameters() -> (language: String, region: String, location: String, safe: String, tbm: String, tbs: String, as_qdr: String) {
        return (
            language: language,
            region: region,
            location: location,
            safe: safeSearch,
            tbm: searchType,
            tbs: timeRange,
            as_qdr: dateRange
        )
    }
}

#Preview {
    SearchParametersView()
        .frame(width: 400)
}
