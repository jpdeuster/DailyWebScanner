//
//  SearchSettingsView.swift
//  DailyWebScanner
//
//  Created by Jörg-Peter Deuster on 18.10.25.
//

import SwiftUI

struct SearchSettingsView: View {
    // Use correct UserDefaults keys that match SearchViewModel
    @AppStorage("settings.serp.hl") private var serpLanguage: String = ""
    @AppStorage("settings.serp.gl") private var serpRegion: String = ""
    @AppStorage("settings.serp.num") private var serpCount: Int = 20
    @AppStorage("settings.serp.location") private var serpLocation: String = ""
    @AppStorage("settings.serp.safe") private var serpSafe: String = ""
    @AppStorage("settings.serp.tbm") private var serpTbm: String = ""
    @AppStorage("settings.serp.tbs") private var serpTbs: String = ""
    @AppStorage("settings.serp.as_qdr") private var serpAsQdr: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Parameters")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Configure default search parameters for Google Web Search. These settings are used as defaults for all search operations. You can adjust the parameters in the main application as needed.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 10)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Language & Region
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                                .font(.title2)
                            
                            Text("Language & Region")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                            GridRow {
                                Text("Language:")
                                    .fontWeight(.medium)
                                
                                Picker("", selection: $serpLanguage) {
                                    Text("Any").tag("")
                                    Text("Deutsch").tag("de")
                                    Text("English").tag("en")
                                    Text("Français").tag("fr")
                                    Text("Español").tag("es")
                                    Text("Italiano").tag("it")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 180)
                            }
                            
                            GridRow {
                                Text("Region:")
                                    .fontWeight(.medium)
                                
                                Picker("", selection: $serpRegion) {
                                    Text("Any").tag("")
                                    Text("Deutschland").tag("de")
                                    Text("USA").tag("us")
                                    Text("UK").tag("uk")
                                    Text("Frankreich").tag("fr")
                                    Text("Spanien").tag("es")
                                    Text("Italien").tag("it")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 180)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Search Parameters
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            Text("Search Parameters")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                            GridRow {
                                Text("Number of Results:")
                                    .fontWeight(.medium)
                                
                                Picker("", selection: $serpCount) {
                                    Text("10").tag(10)
                                    Text("20").tag(20)
                                    Text("30").tag(30)
                                    Text("50").tag(50)
                                    Text("100").tag(100)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 120)
                            }
                            
                            GridRow {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Location:")
                                        .fontWeight(.medium)
                                    Text("Geographic location for search results")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Picker("", selection: $serpLocation) {
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
                                .frame(width: 200)
                            }
                            
                            GridRow {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Safe Search:")
                                        .fontWeight(.medium)
                                    Text("Filter out adult content")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Picker("", selection: $serpSafe) {
                                    Text("Active").tag("active")
                                    Text("Inactive").tag("off")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 200)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Time & Type Filters
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                                .font(.title2)
                            
                            Text("Time & Type Filters")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                            GridRow {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Time Range:")
                                        .fontWeight(.medium)
                                    Text("Filter results by publication date")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Picker("", selection: $serpAsQdr) {
                                    Text("Past 24h").tag("d")
                                    Text("Past Week").tag("w")
                                    Text("Past Month").tag("m")
                                    Text("Past Year").tag("y")
                                    Text("Any Time").tag("")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 200)
                            }
                            
                            GridRow {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Search Type:")
                                        .fontWeight(.medium)
                                    Text("Type of content to search for")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Picker("", selection: $serpTbm) {
                                    Text("All").tag("")
                                    Text("Images").tag("isch")
                                    Text("News").tag("nws")
                                    Text("Videos").tag("vid")
                                    Text("Shopping").tag("shop")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 200)
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    
                }
            }
        }
        .padding()
        .frame(minWidth: 700, minHeight: 600)
    }
}

#Preview {
    SearchSettingsView()
}
