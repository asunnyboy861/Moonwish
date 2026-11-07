import SwiftUI

struct BYOAPISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = BYOSettingsStore.shared

    @State private var keyInput: String = ""
    @State private var testing = false
    @State private var statusMessage: String?
    @State private var isError = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Use your own AI key")
                                .font(Theme.title(.title2))
                                .foregroundStyle(Theme.halo)
                            Text("Moonwish works without a key. Adding one lets you use a model you already pay for and generate without any cloud quota.")
                                .font(.footnote)
                                .foregroundStyle(Theme.mist)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "Provider")
                            Picker("Provider", selection: Binding(
                                get: { store.provider },
                                set: { store.apply(provider: $0) }
                            )) {
                                ForEach(BYOProvider.allCases) { provider in
                                    Text(provider.title).tag(provider)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.gold)

                            TextField("Base URL", text: $store.baseURL)
                                .textFieldStyle(SupportFieldStyle())
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            TextField("Model", text: $store.model)
                                .textFieldStyle(SupportFieldStyle())
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            SecureField(store.hasKey ? "Key saved. Enter a new key to replace it." : "API key", text: $keyInput)
                                .textFieldStyle(SupportFieldStyle())
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            Text("Keys are stored in the iOS Keychain and are never sent anywhere except the endpoint you choose.")
                                .font(.caption2)
                                .foregroundStyle(Theme.mist)
                        }
                        .moonCard()

                        VStack(spacing: 10) {
                            Button {
                                saveSettings()
                                statusMessage = "Custom API settings saved."
                                isError = false
                            } label: {
                                Label("Save", systemImage: "checkmark")
                            }
                            .buttonStyle(GoldButtonStyle())

                            Button {
                                Task { await testConnection() }
                            } label: {
                                if testing {
                                    ProgressView().tint(Theme.halo)
                                } else {
                                    Label("Test connection", systemImage: "bolt.horizontal.circle")
                                }
                            }
                            .buttonStyle(GhostButtonStyle())
                            .disabled(testing)

                            if store.hasKey {
                                Button("Remove saved key", role: .destructive) {
                                    store.clearKey()
                                    keyInput = ""
                                    statusMessage = "Your saved key was removed."
                                    isError = false
                                }
                                .font(.footnote)
                            }

                            if let statusMessage {
                                StatusBanner(text: statusMessage, isError: isError)
                            }
                        }
                    }
                    .padding(22)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.mist)
                }
            }
        }
    }

    private func saveSettings() {
        if !keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            store.saveKey(keyInput)
            keyInput = ""
        }
        store.persist()
    }

    private func testConnection() async {
        saveSettings()
        guard store.hasKey else {
            statusMessage = "Enter an API key first."
            isError = true
            return
        }
        testing = true
        statusMessage = nil
        let started = Date()
        do {
            let input = WishInput(wish: "I feel calm and confident", category: WishDomain.myself.rawValue, answers: ["Calm"], targetDate: nil)
            _ = try await CloudAIService.shared.generateWithBYO(input: input)
            let elapsed = Int(Date().timeIntervalSince(started) * 1000)
            statusMessage = "Connection successful in \(elapsed) ms."
            isError = false
        } catch {
            statusMessage = error.localizedDescription
            isError = true
        }
        testing = false
    }
}
