//
//  SearchSettingsView.swift
//  DailyWebScanner
//
//  Created by Jörg-Peter Deuster on 18.10.25.
//

import SwiftUI

struct SearchSettingsView: View {
    @AppStorage("serpLanguage") private var serpLanguage: String = "de"
    @AppStorage("serpRegion") private var serpRegion: String = "de"
    @AppStorage("serpCount") private var serpCount: Int = 20
    @AppStorage("serpLocation") private var serpLocation: String = "Germany"
    @AppStorage("serpSafe") private var serpSafe: String = "active"
    @AppStorage("serpTbm") private var serpTbm: String = "isch"
    @AppStorage("serpTbs") private var serpTbs: String = ""
    @AppStorage("serpAsQdr") private var serpAsQdr: String = "d"
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Parameters")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Configure default search parameters for Google Web Search")
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
                                
                                Picker("Language", selection: $serpLanguage) {
                                    Text("Deutsch").tag("de")
                                    Text("English").tag("en")
                                    Text("Français").tag("fr")
                                    Text("Español").tag("es")
                                    Text("Italiano").tag("it")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 150)
                            }
                            
                            GridRow {
                                Text("Region:")
                                    .fontWeight(.medium)
                                
                                Picker("Region", selection: $serpRegion) {
                                    Text("Deutschland").tag("de")
                                    Text("USA").tag("us")
                                    Text("UK").tag("uk")
                                    Text("Frankreich").tag("fr")
                                    Text("Spanien").tag("es")
                                    Text("Italien").tag("it")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 150)
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
                            
                            Text("Suchparameter")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                            GridRow {
                                Text("Number of Results:")
                                    .fontWeight(.medium)
                                
                                Picker("Number", selection: $serpCount) {
                                    Text("10").tag(10)
                                    Text("20").tag(20)
                                    Text("30").tag(30)
                                    Text("50").tag(50)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 100)
                            }
                            
                            GridRow {
                                Text("Location:")
                                    .fontWeight(.medium)
                                
                                TextField("e.g. Germany, USA, UK", text: $serpLocation)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                            }
                            
                            GridRow {
                                Text("Safe Search:")
                                    .fontWeight(.medium)
                                
                                Picker("Safe Search", selection: $serpSafe) {
                                    Text("Active").tag("active")
                                    Text("Inactive").tag("off")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 150)
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
                            
                            Text("Zeit & Typ Filter")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                            GridRow {
                                Text("Zeitraum:")
                                    .fontWeight(.medium)
                                
                                Picker("Zeitraum", selection: $serpAsQdr) {
                                    Text("Letzte 24h").tag("d")
                                    Text("Letzte Woche").tag("w")
                                    Text("Letzter Monat").tag("m")
                                    Text("Letztes Jahr").tag("y")
                                    Text("Alle Zeit").tag("")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 150)
                            }
                            
                            GridRow {
                                Text("Suchtyp:")
                                    .fontWeight(.medium)
                                
                                Picker("Suchtyp", selection: $serpTbm) {
                                    Text("Alle").tag("")
                                    Text("Bilder").tag("isch")
                                    Text("News").tag("nws")
                                    Text("Videos").tag("vid")
                                    Text("Shopping").tag("shop")
                                }
                                .pickerStyle(.menu)
                                .frame(width: 150)
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            
                            Text("Information")
                                .font(.headline)
                        }
                        
                        Text("Diese Einstellungen werden als Standard für alle Suchvorgänge verwendet. Sie können die Parameter bei Bedarf in der Hauptanwendung anpassen.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
    }
}

#Preview {
    SearchSettingsView()
}
