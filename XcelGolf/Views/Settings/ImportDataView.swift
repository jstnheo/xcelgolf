import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportDataView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFilePicker = false
    @State private var isImporting = false
    @State private var importResult: ImportResult?
    @State private var showingResults = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 48))
                            .foregroundColor(theme.primary)
                        
                        Text("Import Practice Data")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textPrimary)
                        
                        Text("Import your golf practice sessions from a CSV file")
                            .font(.body)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Instructions
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(theme.primary)
                                Text("CSV Format Requirements")
                                    .font(.headline)
                                    .foregroundColor(theme.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your CSV file should include these columns:")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(csvColumns, id: \.self) { column in
                                        HStack {
                                            Text("•")
                                                .foregroundColor(theme.primary)
                                            Text(column)
                                                .font(.caption)
                                                .foregroundColor(theme.textSecondary)
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Supported Categories:")
                                    .font(.subheadline)
                                    .foregroundColor(theme.textSecondary)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 4) {
                                    ForEach(DrillCategory.allCases, id: \.self) { category in
                                        Text(category.displayName)
                                            .font(.caption)
                                            .foregroundColor(theme.textSecondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(theme.cardBackground)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Import Button
                    VStack(spacing: 16) {
                        Button(action: {
                            showingFilePicker = true
                        }) {
                            HStack {
                                if isImporting {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "doc.badge.plus")
                                }
                                Text(isImporting ? "Importing..." : "Select CSV File")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isImporting)
                        
                        Text("Duplicate sessions will be automatically skipped")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.commaSeparatedText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Import Results", isPresented: $showingResults) {
            Button("OK") {
                importResult = nil
            }
        } message: {
            if let result = importResult {
                Text(formatImportResults(result))
            }
        }
        .alert("Import Error", isPresented: $showingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private var csvColumns: [String] {
        [
            "Session Date",
            "Session Notes",
            "Drill Name",
            "Drill Description",
            "Category",
            "Max Score",
            "Actual Score",
            "Success Rate",
            "Drill Notes",
            "Completed At"
        ]
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importCSVFile(from: url)
        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func importCSVFile(from url: URL) {
        isImporting = true
        
        Task {
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    await MainActor.run {
                        errorMessage = "Unable to access the selected file"
                        showingError = true
                        isImporting = false
                    }
                    return
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                let data = try Data(contentsOf: url)
                let result = try await DataImportService.importFromCSV(data: data, modelContext: modelContext)
                
                await MainActor.run {
                    self.importResult = result
                    self.showingResults = true
                    self.isImporting = false
                }
                
            } catch {
                await MainActor.run {
                    if let importError = error as? ImportError {
                        self.errorMessage = importError.localizedDescription
                    } else {
                        self.errorMessage = "Import failed: \(error.localizedDescription)"
                    }
                    self.showingError = true
                    self.isImporting = false
                }
            }
        }
    }
    
    private func formatImportResults(_ result: ImportResult) -> String {
        var message = ""
        
        if result.sessionsImported > 0 {
            message += "✅ \(result.sessionsImported) session\(result.sessionsImported == 1 ? "" : "s") imported\n"
        }
        
        if result.drillsImported > 0 {
            message += "✅ \(result.drillsImported) drill\(result.drillsImported == 1 ? "" : "s") imported\n"
        }
        
        if result.duplicatesSkipped > 0 {
            message += "⚠️ \(result.duplicatesSkipped) duplicate\(result.duplicatesSkipped == 1 ? "" : "s") skipped\n"
        }
        
        if !result.errors.isEmpty {
            message += "❌ \(result.errors.count) error\(result.errors.count == 1 ? "" : "s") encountered\n"
        }
        
        if result.sessionsImported == 0 && result.drillsImported == 0 {
            message = "No new data was imported."
        }
        
        return message.trimmingCharacters(in: .newlines)
    }
}

#Preview {
    ImportDataView()
        .environment(\.theme, SageGreenTheme())
} 