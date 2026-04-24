import SwiftUI

struct AboutSupportView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AureliaTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        headerCard
                        supportCard
                        privacyCard
                        reviewCard
                    }
                    .padding(24)
                }
            }
            .navigationTitle("About & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier("about.close")
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppMetadata.appName)
                .font(AureliaTheme.display(32, weight: .semibold))
                .foregroundStyle(AureliaTheme.parchment)

            Text(AppMetadata.descriptionOpening)
                .font(AureliaTheme.body(14, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))

            Text("Version \(versionText)")
                .font(AureliaTheme.body(12, weight: .semibold))
                .foregroundStyle(AureliaTheme.champagne)
        }
        .premiumCard()
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Support")
                .font(AureliaTheme.body(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AureliaTheme.champagne)

            Link("Email Support", destination: supportEmailURL)
                .font(AureliaTheme.body(15, weight: .bold))

            Text(AppMetadata.supportEmail)
                .font(AureliaTheme.body(13))
                .foregroundStyle(.white.opacity(0.68))
        }
        .premiumCard()
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Privacy")
                .font(AureliaTheme.body(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AureliaTheme.champagne)

            Text("Aurelia Words keeps gameplay local to the device and does not require an account.")
                .font(AureliaTheme.body(14, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))

            Text("Privacy policy URL placeholder")
                .font(AureliaTheme.body(12, weight: .bold))
                .foregroundStyle(AureliaTheme.parchment)

            Text(AppMetadata.privacyURLString)
                .font(AureliaTheme.body(12))
                .foregroundStyle(.white.opacity(0.66))
                .textSelection(.enabled)
        }
        .premiumCard()
    }

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Review Notes")
                .font(AureliaTheme.body(13, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AureliaTheme.champagne)

            Text(AppMetadata.reviewNotes)
                .font(AureliaTheme.body(14))
                .foregroundStyle(.white.opacity(0.72))
        }
        .premiumCard()
    }

    private var supportEmailURL: URL {
        URL(string: "mailto:\(AppMetadata.supportEmail)")!
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
