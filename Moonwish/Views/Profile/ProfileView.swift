import AVFoundation
import SwiftData
import SwiftUI
import UIKit
import UserNotifications

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Query private var wishes: [Wish]
    @Query private var sessions: [AudioSession]
    @Query private var entries: [JournalEntry]

    @AppStorage("faceIDLock") private var faceIDLock = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("personalVoiceEnabled") private var personalVoiceEnabled = false

    @State private var showPaywall = false
    @State private var showBYO = false
    @State private var showSupport = false
    @State private var showWeekly = false
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var message: String?
    @State private var isError = false
    @State private var streakCount = 0
    @State private var graceRemaining = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        subscriptionGroup
                        aiGroup
                        dataGroup
                        comfortGroup
                        supportGroup
                        footer
                    }
                    .padding(22)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(Theme.title(.title2))
                        .foregroundStyle(Theme.halo)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showBYO) {
            BYOAPISettingsView()
        }
        .sheet(isPresented: $showSupport) {
            ContactSupportView()
        }
        .sheet(isPresented: $showWeekly) {
            WeeklyReportView()
        }
        .sheet(isPresented: $showShare) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
        .onAppear(perform: refresh)
        .onChange(of: purchaseManager.isPlus) { _, _ in refresh() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Moonwish")
                .font(Theme.title(.largeTitle))
                .foregroundStyle(Theme.halo)
            Text("Everything private stays on this device and in your iCloud.")
                .font(.footnote)
                .foregroundStyle(Theme.mist)
        }
        .padding(.top, 8)
    }

    private var subscriptionGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Subscription")
            HStack(spacing: 12) {
                Image(systemName: purchaseManager.isPlus ? "crown.fill" : "moon.stars.fill")
                    .foregroundStyle(Theme.gold)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(purchaseManager.isPlus ? "Moonwish Plus is active" : "You are on the free tier")
                        .font(.body)
                        .foregroundStyle(Theme.halo)
                    Text(purchaseManager.isPlus ? "Cloud quota: \(CloudQuotaService.shared.remaining) generations left this month" : "Unlimited on-device sessions, 20+ library tracks")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
                Spacer()
            }
            if !purchaseManager.isPlus {
                Button {
                    showPaywall = true
                } label: {
                    Label("Explore Moonwish Plus", systemImage: "sparkles")
                }
                .buttonStyle(GoldButtonStyle(compact: true))
            }
            Button {
                Task {
                    await purchaseManager.restorePurchases()
                    if purchaseManager.isPlus {
                        message = "Your purchases were restored."
                        isError = false
                    } else {
                        message = "No active subscription was found."
                        isError = true
                    }
                }
            } label: {
                Text("Restore Purchases")
                    .font(.footnote)
                    .foregroundStyle(Theme.mist)
            }
            .buttonStyle(.plain)
            Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                .font(.footnote)
                .foregroundStyle(Theme.gold)
        }
        .moonCard()
    }

    private var aiGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "AI engines")
            SettingsRow(icon: "apple.logo", title: "Apple Intelligence", subtitle: AppleIntelligenceService.isAvailable ? "Available on this device" : "Needs iOS 26 and supported hardware", trailing: AppleIntelligenceService.isAvailable ? "On" : "Off")
            Divider().overlay(Theme.cardStroke)
            Button {
                showBYO = true
            } label: {
                SettingsRow(icon: "key.fill", title: "Custom API key", subtitle: BYOSettingsStore.shared.hasKey ? "\(BYOSettingsStore.shared.provider.title) · \(BYOSettingsStore.shared.model)" : "Use your own OpenAI-compatible key", trailing: BYOSettingsStore.shared.hasKey ? "Set" : "Not set", showsChevron: true)
            }
            .buttonStyle(.plain)
        }
        .moonCard()
    }

    private var dataGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Your data")
            SettingsRow(icon: "icloud.fill", title: "iCloud backup", subtitle: DataStore.iCloudAccountAvailable ? "Signed in. Changes sync automatically." : "Local only. Sign in to iCloud to sync.", trailing: DataStore.iCloudAccountAvailable ? "On" : "Local")
            Divider().overlay(Theme.cardStroke)
            Button {
                showWeekly = true
            } label: {
                SettingsRow(icon: "chart.bar.fill", title: "Weekly moon report", subtitle: "Your last seven days", trailing: "", showsChevron: true)
            }
            .buttonStyle(.plain)
            Divider().overlay(Theme.cardStroke)
            Button {
                exportData()
            } label: {
                SettingsRow(icon: "square.and.arrow.up", title: "Export wishes & audio", subtitle: "Shared as a folder with a JSON manifest", trailing: "", showsChevron: true)
            }
            .buttonStyle(.plain)
            Divider().overlay(Theme.cardStroke)
            SettingsRow(icon: "cloud.fill", title: "Grace cards", subtitle: "A missed night does not erase your streak", trailing: "\(graceRemaining)")
            Divider().overlay(Theme.cardStroke)
            SettingsRow(icon: "flame.fill", title: "Current streak", subtitle: "Keep showing up, gently", trailing: "\(streakCount) nights")
        }
        .moonCard()
    }

    private var comfortGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Rituals & privacy")
            Toggle(isOn: Binding(
                get: { notificationsEnabled },
                set: { newValue in
                    notificationsEnabled = newValue
                    if newValue {
                        Task {
                            let granted = await NotificationService.requestAuthorization()
                            if granted {
                                NotificationService.scheduleEveningReminder()
                                message = "Evening reminder set for 9:30 PM."
                                isError = false
                            } else {
                                notificationsEnabled = false
                                message = "Notifications are disabled in system settings."
                                isError = true
                            }
                        }
                    } else {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["moonwish.evening"])
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Evening moon reminder")
                        .foregroundStyle(Theme.halo)
                    Text("A gentle nudge at 9:30 PM")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
            }
            .tint(Theme.gold)

            Divider().overlay(Theme.cardStroke)

            Toggle(isOn: $faceIDLock) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Face ID lock")
                        .foregroundStyle(Theme.halo)
                    Text("Keep your wishes and journal private")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
            }
            .tint(Theme.gold)

            Divider().overlay(Theme.cardStroke)

            Toggle(isOn: Binding(
                get: { personalVoiceEnabled },
                set: { newValue in
                    if newValue {
                        AVSpeechSynthesizer.requestPersonalVoiceAuthorization { status in
                            DispatchQueue.main.async {
                                if status == .authorized {
                                    personalVoiceEnabled = true
                                } else {
                                    personalVoiceEnabled = false
                                    message = "Personal Voice is not authorized on this device."
                                    isError = true
                                }
                            }
                        }
                    } else {
                        personalVoiceEnabled = false
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Personal Voice")
                        .foregroundStyle(Theme.halo)
                    Text("Use your own voice for affirmations on Plus")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
            }
            .tint(Theme.gold)
        }
        .moonCard()
    }

    private var supportGroup: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Support & legal")
            Button {
                showSupport = true
            } label: {
                SettingsRow(icon: "envelope.fill", title: "Contact Support", subtitle: "We reply within 48 hours", trailing: "", showsChevron: true)
            }
            .buttonStyle(.plain)
            Divider().overlay(Theme.cardStroke)
            Link(destination: AppConfig.supportURL) {
                SettingsRow(icon: "questionmark.circle.fill", title: "Support page & FAQ", subtitle: "Subscription help and answers", trailing: "", showsChevron: true)
            }
            Divider().overlay(Theme.cardStroke)
            Link(destination: AppConfig.privacyURL) {
                SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", subtitle: "How your data stays yours", trailing: "", showsChevron: true)
            }
            Divider().overlay(Theme.cardStroke)
            Link(destination: AppConfig.termsURL) {
                SettingsRow(icon: "doc.text.fill", title: "Terms of Use", subtitle: "Subscription terms and EULA", trailing: "", showsChevron: true)
            }
            if let message {
                StatusBanner(text: message, isError: isError)
            }
        }
        .moonCard()
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text("Moonwish")
                .font(.system(.footnote, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.halo)
            Text(AppConfig.versionText)
                .font(.caption2)
                .foregroundStyle(Theme.mist)
            Text("Motivational and mindfulness content. Not medical advice.")
                .font(.caption2)
                .foregroundStyle(Theme.mist)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func refresh() {
        let state = StreakEngine.state(in: modelContext, isPlus: purchaseManager.isPlus)
        streakCount = state.currentStreak
        graceRemaining = state.graceRemaining
    }

    private func exportData() {
        if let url = ExportService.makePackage(wishes: wishes, entries: entries, sessions: sessions) {
            shareURL = url
            showShare = true
            message = "Your export is ready."
            isError = false
        } else {
            message = "Could not prepare the export. Please try again."
            isError = true
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var trailing: String
    var showsChevron: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.gold)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Theme.halo)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                        .lineLimit(2)
                }
            }
            Spacer()
            if !trailing.isEmpty {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(Theme.gold)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.mist)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
