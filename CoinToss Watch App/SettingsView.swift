import SwiftUI

/// Secondary screen: which coin is in play, and whether tosses make a sound.
struct SettingsView: View {
    @Binding var selectedStyleID: String
    @Binding var soundEnabled: Bool

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
            soundEnabled: .constant(true)
        )
    }
}
