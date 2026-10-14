import SwiftUI

public struct WhatsNewSheetView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "globe.americas.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundStyle(Color.accentColor)

                Text(String(localized: "storykit.whatsnew.title"))
                    .font(.system(size: 24, weight: .bold))

                Text(String(localized: "storykit.whatsnew.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)

            // Features List
            VStack(alignment: .leading, spacing: 20) {
                featureRow(
                    icon: "mountain.2.fill",
                    color: .orange,
                    title: String(localized: "storykit.whatsnew.feat1.title"),
                    description: String(localized: "storykit.whatsnew.feat1.desc")
                )

                featureRow(
                    icon: "building.columns.fill",
                    color: .blue,
                    title: String(localized: "storykit.whatsnew.feat2.title"),
                    description: String(localized: "storykit.whatsnew.feat2.desc")
                )

                featureRow(
                    icon: "map.fill",
                    color: .green,
                    title: String(localized: "storykit.whatsnew.feat3.title"),
                    description: String(localized: "storykit.whatsnew.feat3.desc")
                )

                featureRow(
                    icon: "macwindow",
                    color: .purple,
                    title: String(localized: "storykit.whatsnew.feat4.title"),
                    description: String(localized: "storykit.whatsnew.feat4.desc")
                )
            }
            .padding(.horizontal, 20)

            Spacer()

            // Dismiss Button
            Button(action: { dismiss() }) {
                Text(String(localized: "storykit.whatsnew.continue"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 480, height: 520)
    }

    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
