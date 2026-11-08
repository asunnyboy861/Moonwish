import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var selectedPlan: Plan = .yearly
    @State private var purchasing = false
    @State private var message: String?
    @State private var isError = false

    enum Plan {
        case monthly
        case yearly
    }

    private var yearlyPrice: String {
        purchaseManager.yearlyProduct?.displayPrice ?? "$29.99"
    }

    private var monthlyPrice: String {
        purchaseManager.monthlyProduct?.displayPrice ?? "$7.99"
    }

    private var boosterPrice: String {
        purchaseManager.boosterProduct?.displayPrice ?? "$1.99"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                StarField().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Theme.gold)
                            Text("Moonwish Plus")
                                .font(Theme.title(.largeTitle))
                                .foregroundStyle(Theme.halo)
                            Text("Sleep deeper. Manifest louder.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.mist)
                        }
                        .padding(.top, 12)

                        featuresCard
                        planCards
                        subscribeSection
                        boosterCard
                        restoreRow
                        legalSection
                    }
                    .padding(22)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Theme.mist)
                    }
                    .accessibilityLabel("Close paywall")
                }
            }
        }
        .onChange(of: purchaseManager.isPlus) { _, isPlus in
            if isPlus {
                message = "Plus is active. Everything is unlocked."
                isError = false
            }
        }
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow(icon: "bed.double.fill", title: "8-hour seamless overnight mode", detail: "Sleep through the whole night with a gentle fade out.")
            featureRow(icon: "waveform", title: "All 21 soundscapes", detail: "Theta, 432 Hz, rain, ocean, lo-fi, and more.")
            featureRow(icon: "cloud.fill", title: "30 deep cloud sessions each month", detail: "Richer scripts through the Moonwish cloud engine.")
            featureRow(icon: "person.wave.2.fill", title: "Personal Voice", detail: "Hear affirmations in your own voice.")
            featureRow(icon: "bolt.fill", title: "Cloud Booster anytime", detail: "Add 30 more cloud sessions for $1.99 whenever you need them.")
        }
        .moonCard()
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Theme.gold)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Theme.halo)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.mist)
            }
        }
    }

    private var planCards: some View {
        HStack(spacing: 12) {
            planCard(plan: .monthly, title: "Monthly", price: monthlyPrice, suffix: "/ month", badge: nil)
            planCard(plan: .yearly, title: "Yearly", price: yearlyPrice, suffix: "/ year", badge: "7 days free")
        }
    }

    private func planCard(plan: Plan, title: String, price: String, suffix: String, badge: String?) -> some View {
        let selected = selectedPlan == plan
        return Button {
            selectedPlan = plan
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(.subheadline, design: .default, weight: .semibold))
                    .foregroundStyle(Theme.halo)
                Text(price)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                Text(suffix)
                    .font(.caption2)
                    .foregroundStyle(Theme.mist)
                if let badge {
                    Text(badge.uppercased())
                        .font(.system(.caption2, design: .default, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(Theme.midnightDeep)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Capsule().fill(Theme.gold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? Theme.gold.opacity(0.16) : Theme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selected ? Theme.gold : Theme.cardStroke, lineWidth: selected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) plan, \(price) \(suffix)")
    }

    private var subscribeSection: some View {
        VStack(spacing: 10) {
            Button {
                Task { await purchaseSelected() }
            } label: {
                if purchasing {
                    ProgressView().tint(Theme.midnightDeep)
                } else {
                    Text(selectedPlan == .yearly ? "Start 7-day free trial" : "Subscribe monthly")
                }
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(purchasing)

            Text(selectedPlan == .yearly
                 ? "7 days free, then \(yearlyPrice)/year, cancel anytime."
                 : "\(monthlyPrice)/month, auto-renews until canceled.")
                .font(.caption)
                .foregroundStyle(Theme.mist)
                .multilineTextAlignment(.center)

            Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage or cancel in your App Store account settings.")
                .font(.caption2)
                .foregroundStyle(Theme.mist)
                .multilineTextAlignment(.center)

            if let message = message, !ScreenshotMode.isActive {
                StatusBanner(text: message, isError: isError)
            }
            if let loadError = purchaseManager.loadError, !ScreenshotMode.isActive {
                StatusBanner(text: loadError, isError: true)
            }
            if purchaseManager.products.isEmpty && !purchaseManager.isLoading && !ScreenshotMode.isActive {
                Text("Subscription options could not be loaded. Check your connection and try again.")
                    .font(.caption2)
                    .foregroundStyle(Theme.danger)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var boosterCard: some View {
        Button {
            Task {
                guard let product = purchaseManager.boosterProduct else {
                    message = "The booster is not available right now."
                    isError = true
                    return
                }
                let success = await purchaseManager.purchase(product)
                if success {
                    message = "30 cloud generations were added."
                    isError = false
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cloud Booster")
                        .font(.body)
                        .foregroundStyle(Theme.halo)
                    Text("30 extra cloud sessions · \(boosterPrice) once")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
                Spacer()
                Text("Buy")
                    .font(.footnote)
                    .foregroundStyle(Theme.gold)
            }
            .padding(16)
            .moonCard(padding: 0)
        }
        .buttonStyle(.plain)
    }

    private var restoreRow: some View {
        HStack {
            Button("Restore Purchases") {
                Task {
                    await purchaseManager.restorePurchases()
                    message = purchaseManager.isPlus ? "Your purchases were restored." : "No active subscription was found."
                    isError = !purchaseManager.isPlus
                }
            }
            .font(.footnote)
            .foregroundStyle(Theme.halo)

            Spacer()

            Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                .font(.footnote)
                .foregroundStyle(Theme.gold)
        }
    }

    private var legalSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 18) {
                Link("Privacy Policy", destination: AppConfig.privacyURL)
                Link("Terms of Use", destination: AppConfig.termsURL)
            }
            .font(.caption)
            .foregroundStyle(Theme.gold)

            Text("Moonwish is a motivational and mindfulness tool. It does not provide medical advice.")
                .font(.caption2)
                .foregroundStyle(Theme.mist)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 12)
    }

    private func purchaseSelected() async {
        purchasing = true
        message = nil
        let product = selectedPlan == .yearly ? purchaseManager.yearlyProduct : purchaseManager.monthlyProduct
        guard let product else {
            purchasing = false
            message = "This plan is not available right now. Please try again later."
            isError = true
            return
        }
        let success = await purchaseManager.purchase(product)
        purchasing = false
        if success {
            message = "Plus is active. Everything is unlocked."
            isError = false
        } else if let error = purchaseManager.loadError {
            message = error
            isError = true
        }
    }
}
