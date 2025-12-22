import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.showGrid) private var showGrid = true
    @AppStorage(SettingsKeys.showNumbers) private var showNumbers = true
    @AppStorage(SettingsKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKeys.particlesEnabled) private var particlesEnabled = true

    @State private var showResetAllAlert = false

    var body: some View {
        Form {
            Section("Display") {
                Toggle("Grid", isOn: $showGrid)
                Toggle("Numbers", isOn: $showNumbers)
            }

            Section("Effects") {
                Toggle("Haptics", isOn: $hapticsEnabled)
                Toggle("Particles", isOn: $particlesEnabled)
            }

            Section("Data") {
                Button(role: .destructive) {
                    showResetAllAlert = true
                } label: {
                    Text("Reset All Progress")
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Reset all progress?", isPresented: $showResetAllAlert) {
            Button("Reset", role: .destructive) {
                ProgressStore.resetAllProgress()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete saved progress for all pictures.")
        }
    }
}

