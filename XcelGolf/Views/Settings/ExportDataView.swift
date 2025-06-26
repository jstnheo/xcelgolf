import SwiftUI
import SwiftData
import MessageUI

struct ExportDataView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \PracticeSession.date, order: .reverse)
    private var allSessions: [PracticeSession]
    
    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedDateRange: ExportDateRange = .all
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingMailComposer = false
    @State private var exportData: Data?
    @State private var fileName: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    Section("Export Format") {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(format.rawValue)
                                        .font(.headline)
                                        .foregroundColor(theme.textPrimary)
                                    Text(formatDescription(format))
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }
                                Spacer()
                                if selectedFormat == format {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(theme.primary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFormat = format
                            }
                        }
                    }
                    
                    Section("Date Range") {
                        ForEach(ExportDateRange.allCases, id: \.self) { range in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(range.displayName)
                                        .font(.headline)
                                        .foregroundColor(theme.textPrimary)
                                    Text(range.description)
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                }
                                Spacer()
                                if selectedDateRange == range {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(theme.primary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDateRange = range
                            }
                        }
                    }
                    
                    Section("Data Summary") {
                        let filteredSessions = getFilteredSessions()
                        let totalDrills = filteredSessions.flatMap { $0.drills }.count
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(theme.primary)
                            Text("Sessions")
                            Spacer()
                            Text("\(filteredSessions.count)")
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(theme.primary)
                            Text("Drills")
                            Spacer()
                            Text("\(totalDrills)")
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        if let earliestDate = filteredSessions.last?.date,
                           let latestDate = filteredSessions.first?.date {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(theme.primary)
                                Text("Date Range")
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(DateFormatter.shortDate.string(from: earliestDate))
                                        .foregroundColor(theme.textSecondary)
                                        .font(.caption)
                                    Text("to")
                                        .foregroundColor(theme.textSecondary)
                                        .font(.caption2)
                                    Text(DateFormatter.shortDate.string(from: latestDate))
                                        .foregroundColor(theme.textSecondary)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                // Export Button
                VStack(spacing: 16) {
                    Button(action: performExport) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(isExporting ? "Exporting..." : "Export Data")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isExporting || getFilteredSessions().isEmpty)
                    
                    if getFilteredSessions().isEmpty {
                        Text("No data available for the selected date range")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(theme.background)
            }
            .navigationTitle("Export Data")
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
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showingMailComposer) {
            if MFMailComposeViewController.canSendMail(),
               let data = exportData {
                MailComposeView(
                    subject: "Golf Practice Data Export",
                    messageBody: generateEmailBody(),
                    attachmentData: data,
                    attachmentFileName: fileName,
                    attachmentMimeType: selectedFormat.mimeType
                )
            } else {
                MailUnavailableView()
            }
        }
    }
    
    private func formatDescription(_ format: ExportFormat) -> String {
        switch format {
        case .csv:
            return "Spreadsheet format, compatible with Excel and Google Sheets"
        case .json:
            return "Structured data format, preserves all data relationships"
        }
    }
    
    private func getFilteredSessions() -> [PracticeSession] {
        let startDate = selectedDateRange.startDate
        return allSessions.filter { session in
            session.date >= startDate
        }
    }
    
    private func performExport() {
        isExporting = true
        
        Task {
            let sessions = getFilteredSessions()
            fileName = DataExportService.generateFileName(format: selectedFormat)
            
            guard let data = DataExportService.exportData(sessions: sessions, format: selectedFormat) else {
                await MainActor.run {
                    isExporting = false
                }
                return
            }
            
            await MainActor.run {
                self.exportData = data
                
                // Save to temporary file for sharing
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    try data.write(to: tempURL)
                    self.exportedFileURL = tempURL
                    
                    // Show sharing options
                    if MFMailComposeViewController.canSendMail() {
                        showingMailComposer = true
                    } else {
                        showingShareSheet = true
                    }
                } catch {
                    print("Failed to write export file: \(error)")
                }
                
                isExporting = false
            }
        }
    }
    
    private func generateEmailBody() -> String {
        let sessions = getFilteredSessions()
        let totalDrills = sessions.flatMap { $0.drills }.count
        
        return """
        Hi,
        
        I'm sharing my golf practice data with you. Here's a summary:
        
        • Total Sessions: \(sessions.count)
        • Total Drills: \(totalDrills)
        • Date Range: \(selectedDateRange.displayName)
        • Export Format: \(selectedFormat.rawValue)
        
        The attached file contains detailed information about my practice sessions, including drill performance, scores, and notes.
        
        Best regards
        """
    }
}

// MARK: - Export Date Range
enum ExportDateRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    case threeMonths = "threeMonths"
    case sixMonths = "sixMonths"
    case year = "year"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .week: return "Last 7 Days"
        case .month: return "Last 30 Days"
        case .threeMonths: return "Last 3 Months"
        case .sixMonths: return "Last 6 Months"
        case .year: return "Last Year"
        case .all: return "All Time"
        }
    }
    
    var description: String {
        switch self {
        case .week: return "Export data from the past week"
        case .month: return "Export data from the past month"
        case .threeMonths: return "Export data from the past 3 months"
        case .sixMonths: return "Export data from the past 6 months"
        case .year: return "Export data from the past year"
        case .all: return "Export all available data"
        }
    }
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return Date.distantPast
        }
    }
}

// MARK: - Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let messageBody: String
    let attachmentData: Data
    let attachmentFileName: String
    let attachmentMimeType: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setMessageBody(messageBody, isHTML: false)
        composer.addAttachmentData(attachmentData, mimeType: attachmentMimeType, fileName: attachmentFileName)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Mail Unavailable View
struct MailUnavailableView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 60))
                    .foregroundColor(theme.textSecondary)
                
                Text("Mail Not Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Text("Please set up Mail on your device or use the share option to export your data through other apps.")
                    .font(.body)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("OK") {
                    dismiss()
                }
                .padding()
                .background(theme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Mail Unavailable")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
} 