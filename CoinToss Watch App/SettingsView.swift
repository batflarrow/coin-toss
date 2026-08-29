import SwiftUI

/// Secondary screen: which coin is in play, whether tosses make a sound, and
/// whether the running tally shows under the coin.
struct SettingsView: View {
    @Binding var selectedStyleID: String
    @Binding var soundEnabled: Bool
    @Binding var tallyVisible: Bool

    var body: some View {
        List {
            Section("Coin") {
                ForEach(CoinStyle.all) { style in
                    CoinRow(
                        style: style,
                        isSelected: style.id == selectedStyleID,
                        select: { selectedStyleID = style.id }
                    )
                }
            }

            Section {
                Toggle("Sound", isOn: $soundEnabled)
                Toggle("Tally", isOn: $tallyVisible)
            }
        }
        .navigationTitle("Settings")
    }
}

private struct CoinRow: View {
    let style: CoinStyle
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 10) {
                CoinView(style: style, face: .heads, diameter: 30)
                Text(style.name)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(style.name)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            selectedStyleID: .constant(CoinStyle.quarter.id),
            soundEnabled: .constant(true),
            tallyVisible: .constant(true)
        )
    }
}
