//
//  SearchParametersView.swift
//  DailyWebScanner
//
//  Created by Jörg-Peter Deuster on 19.10.25.
//

import SwiftUI

struct SearchParametersView: View {
    // Persistent storage for search parameters
    @AppStorage("searchLanguage") var language: String = "" // "Any" option
    @AppStorage("searchRegion") var region: String = "" // "Any" option  
    @AppStorage("searchLocation") var location: String = "" // "Any" option
    @AppStorage("searchSafeSearch") var safeSearch: String = "off"
    @AppStorage("searchType") var searchType: String = "" // "All" option
    @AppStorage("searchTimeRange") var timeRange: String = "" // "Any Time" option
    @AppStorage("searchDateRange") var dateRange: String = "" // "Any" option
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with toggle
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text("Search Parameters")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Hide" : "Show")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            
            if isExpanded {
                VStack(spacing: 20) {
                    // Basic Parameters
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.blue)
                                .font(.title3)
                            Text("Basic Settings")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
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
                                    ForEach(LanguageHelper.languages, id: \.code) { lang in
                                        Text(lang.name.isEmpty ? "Any" : "\(lang.name) (\(lang.code))").tag(lang.code)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onChange(of: language) { _, newValue in
                                    DebugLogger.shared.logWebViewAction("Language changed to: '\(newValue)'")
                                }
                            }
                            
                            // Region
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Region")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $region) {
                                    ForEach(LanguageHelper.countries, id: \.code) { country in
                                        Text(country.name.isEmpty ? "Any" : "\(country.name) (\(country.code))").tag(country.code)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onChange(of: region) { _, newValue in
                                    DebugLogger.shared.logWebViewAction("Region changed to: '\(newValue)'")
                                }
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
                                    Text("Mexico").tag("Mexico")
                                    Text("Netherlands").tag("Netherlands")
                                    Text("Sweden").tag("Sweden")
                                    Text("Norway").tag("Norway")
                                    Text("Denmark").tag("Denmark")
                                    Text("Finland").tag("Finland")
                                    Text("Switzerland").tag("Switzerland")
                                    Text("Austria").tag("Austria")
                                    Text("Belgium").tag("Belgium")
                                    Text("Poland").tag("Poland")
                                    Text("Czech Republic").tag("Czech Republic")
                                    Text("Hungary").tag("Hungary")
                                    Text("Portugal").tag("Portugal")
                                    Text("Greece").tag("Greece")
                                    Text("Turkey").tag("Turkey")
                                    Text("Russia").tag("Russia")
                                    Text("South Korea").tag("South Korea")
                                    Text("Singapore").tag("Singapore")
                                    Text("Hong Kong").tag("Hong Kong")
                                    Text("Taiwan").tag("Taiwan")
                                    Text("Thailand").tag("Thailand")
                                    Text("Malaysia").tag("Malaysia")
                                    Text("Indonesia").tag("Indonesia")
                                    Text("Philippines").tag("Philippines")
                                    Text("Vietnam").tag("Vietnam")
                                    Text("South Africa").tag("South Africa")
                                    Text("Egypt").tag("Egypt")
                                    Text("Israel").tag("Israel")
                                    Text("UAE").tag("United Arab Emirates")
                                    Text("Saudi Arabia").tag("Saudi Arabia")
                                    Text("Argentina").tag("Argentina")
                                    Text("Chile").tag("Chile")
                                    Text("Colombia").tag("Colombia")
                                    Text("Peru").tag("Peru")
                                    Text("Venezuela").tag("Venezuela")
                                    Text("New Zealand").tag("New Zealand")
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
    
    
    // Public methods to get current parameters
    func getParameters() -> (language: String, region: String, location: String, safe: String, tbm: String, tbs: String, as_qdr: String, nfpr: String, filter: String) {
        let params = (
            language: language,
            region: region,
            location: location,
            safe: safeSearch,
            tbm: searchType,
            tbs: timeRange,
            as_qdr: dateRange,
            nfpr: "",
            filter: ""
        )
        
        // Debug: Log the parameters
        DebugLogger.shared.logWebViewAction("SearchParametersView.getParameters() - Language: '\(params.language)', Region: '\(params.region)', Location: '\(params.location)', Safe: '\(params.safe)', TBM: '\(params.tbm)', TBS: '\(params.tbs)', AS_QDR: '\(params.as_qdr)'")
        
        return params
    }
}

#Preview {
    SearchParametersView()
        .frame(width: 400)
}
