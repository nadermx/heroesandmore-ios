import SwiftUI
import PhotosUI

struct ScannerView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var scanResult: ScanResult?
    @State private var isScanning = false
    @State private var error: String?
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Scanner icon
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Text("Scan Collectibles")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Take a photo or select an image to identify items and get pricing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    NavigationLink {
                        CameraScanView { image in
                            selectedImage = image
                            Task { await scanImage(image) }
                        }
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle("Scanner")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .onChange(of: selectedItem) {
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        await scanImage(image)
                    }
                }
            }
            .sheet(item: $scanResult) { result in
                ScanResultSheet(result: result)
            }
            .sheet(isPresented: $showHistory) {
                ScanHistoryView()
            }
            .overlay {
                if isScanning {
                    scanningOverlay
                }
            }
            .alert("Scan Error", isPresented: .constant(error != nil)) {
                Button("OK") { error = nil }
            } message: {
                if let error = error {
                    Text(error)
                }
            }
        }
    }

    private var scanningOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Scanning...")
                    .foregroundStyle(.white)
                    .fontWeight(.medium)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }

    private func scanImage(_ image: UIImage) async {
        isScanning = true
        error = nil

        do {
            scanResult = try await ScannerService.shared.scanImage(image: image)
        } catch {
            self.error = error.localizedDescription
        }

        isScanning = false
    }
}

struct CameraScanView: View {
    var onCapture: (UIImage) -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        // Camera integration would go here
        // For now, showing placeholder
        VStack {
            Text("Camera View")
                .font(.headline)

            Text("Camera integration requires UIViewControllerRepresentable")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            Button("Cancel") {
                dismiss()
            }
        }
        .navigationTitle("Take Photo")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ScanResultSheet: View {
    let result: ScanResult

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Scanned image
                    if let url = URL(string: result.image) {
                        AsyncImageView(url: url, contentMode: .fit)
                            .frame(height: 200)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }

                    // Results
                    if result.matches.isEmpty {
                        EmptyStateView(
                            icon: "questionmark.circle",
                            title: "No Matches Found",
                            message: "We couldn't identify this item. Try a clearer photo."
                        )
                        .frame(height: 200)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Matches Found")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(result.matches) { match in
                                ScanMatchCard(match: match)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Scan Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ScanMatchCard: View {
    let match: ScanMatch

    var body: some View {
        NavigationLink {
            PriceGuideDetailView(itemId: match.priceGuideItemId)
        } label: {
            HStack(spacing: 12) {
                // Image
                if let imageUrl = match.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImageView(url: url)
                        .frame(width: 70, height: 70)
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 70, height: 70)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(match.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    if let price = match.averagePrice {
                        Text("$\(price)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(match.confidencePercent)%")
                        .font(.headline)
                        .foregroundStyle(confidenceColor)

                    Text("match")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    private var confidenceColor: Color {
        if match.confidencePercent >= 90 {
            return .green
        } else if match.confidencePercent >= 70 {
            return .orange
        } else {
            return .red
        }
    }
}

struct ScanHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var scans: [ScanResult] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView()
                } else if let error = error {
                    ErrorView(message: error) {
                        Task { await loadScans() }
                    }
                } else if scans.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "No Scan History",
                        message: "Your scanned items will appear here"
                    )
                } else {
                    List(scans) { scan in
                        ScanHistoryRow(scan: scan)
                    }
                }
            }
            .navigationTitle("Scan History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadScans()
            }
        }
    }

    private func loadScans() async {
        isLoading = true
        error = nil

        do {
            let response = try await ScannerService.shared.getScans()
            scans = response.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct ScanHistoryRow: View {
    let scan: ScanResult

    var body: some View {
        HStack(spacing: 12) {
            if let url = URL(string: scan.image) {
                AsyncImageView(url: url)
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 2) {
                if let firstMatch = scan.matches.first {
                    Text(firstMatch.name)
                        .font(.subheadline)
                } else {
                    Text("No matches")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let date = scan.created {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("\(scan.matches.count) matches")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

extension ScanResult: Identifiable {}

#Preview {
    ScannerView()
}
