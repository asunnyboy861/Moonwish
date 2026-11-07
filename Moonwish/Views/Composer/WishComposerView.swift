import SwiftUI

struct WishComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @StateObject private var viewModel = WishComposerViewModel()
    @StateObject private var dictation = SpeechDictation()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                StarField().ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        switch viewModel.step {
                        case .domain:
                            domainStep
                        case .wish:
                            wishStep
                        case .chips:
                            chipsStep
                        case .timing:
                            timingStep
                        case .generating:
                            generatingStep
                        case .finished:
                            finishedStep
                        }
                    }
                    .padding(22)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Theme.mist)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isGenerating)
        .sheet(item: $viewModel.playbackItem) { item in
            PlayerView(item: item)
        }
        .onChange(of: dictation.transcript) { _, newValue in
            if !newValue.isEmpty {
                viewModel.wishText = newValue
            }
        }
        .onDisappear {
            if dictation.isRecording { dictation.stop() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(progressIndex >= index ? Theme.gold : Theme.cardStroke)
                        .frame(height: 3)
                }
            }
            Text(title)
                .font(Theme.title(.title2))
                .foregroundStyle(Theme.halo)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(Theme.mist)
        }
        .padding(.top, 8)
    }

    private var progressIndex: Int {
        switch viewModel.step {
        case .domain: return 0
        case .wish: return 1
        case .chips: return 2
        case .timing: return 3
        case .generating, .finished: return 4
        }
    }

    private var title: String {
        switch viewModel.step {
        case .domain: return "What is this wish about?"
        case .wish: return "Say it like it is already yours."
        case .chips: return "A few quick touches."
        case .timing: return "When should it arrive?"
        case .generating: return "The moon is writing."
        case .finished: return "Your audio is ready."
        }
    }

    private var subtitle: String {
        switch viewModel.step {
        case .domain: return "Choose the life area your wish belongs to."
        case .wish: return "One sentence is enough. You can speak it."
        case .chips: return "Tap only. No typing needed."
        case .timing: return "Optional. This creates a gentle check-in."
        case .generating: return "Your words are becoming a personal bedtime ritual."
        case .finished: return "It was made only for you."
        }
    }

    private var domainStep: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            ForEach(WishDomain.allCases) { domain in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.select(domain: domain)
                    }
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: domain.icon)
                            .font(.title2)
                            .foregroundStyle(Theme.gold)
                        Text(domain.rawValue)
                            .font(Theme.title(.title3))
                            .foregroundStyle(Theme.halo)
                        Text(domain.prompt)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.mist)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 148)
                    .moonCard()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(domain.rawValue) wish")
            }
        }
    }

    private var wishStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField(viewModel.domain?.prompt ?? "I want...", text: $viewModel.wishText, axis: .vertical)
                .font(.title3)
                .foregroundStyle(Theme.halo)
                .lineLimit(3...6)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Theme.cardFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Theme.cardStroke, lineWidth: 1)
                        )
                )

            HStack(spacing: 12) {
                Button {
                    dictation.toggle()
                } label: {
                    Label(dictation.isRecording ? "Stop dictation" : "Speak it", systemImage: dictation.isRecording ? "waveform.circle.fill" : "mic.fill")
                        .font(.footnote)
                }
                .buttonStyle(GhostButtonStyle())
                .accessibilityLabel(dictation.isRecording ? "Stop dictation" : "Speak your wish")

                if dictation.isRecording {
                    Text("Listening...")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
            }

            if let message = dictation.errorMessage {
                StatusBanner(text: message, isError: true)
            }

            Button("Continue") {
                viewModel.continueToChips()
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(viewModel.wishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(viewModel.wishText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
        }
    }

    private var chipsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let question = viewModel.currentQuestion {
                Text(question.prompt)
                    .font(Theme.title(.title3))
                    .foregroundStyle(Theme.halo)
                    .padding(.top, 6)
                ForEach(question.options, id: \.self) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.choose(option: option)
                        }
                    } label: {
                        HStack {
                            Text(option)
                                .font(.body)
                                .foregroundStyle(Theme.halo)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Theme.mist)
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.cardFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Theme.cardStroke, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option)
                }
            }

            Button("Skip the extra questions") {
                viewModel.skipChips()
            }
            .font(.footnote)
            .foregroundStyle(Theme.mist)
            .padding(.top, 4)
        }
    }

    private var timingStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle(isOn: $viewModel.wantsCapsule) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set a Time Capsule date")
                        .font(.body)
                        .foregroundStyle(Theme.halo)
                    Text("You will get a gentle nudge to celebrate it.")
                        .font(.caption)
                        .foregroundStyle(Theme.mist)
                }
            }
            .tint(Theme.gold)

            if viewModel.wantsCapsule {
                DatePicker("Arrival date", selection: $viewModel.capsuleDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .tint(Theme.gold)
                    .foregroundStyle(Theme.halo)
            }

            if let errorMessage = viewModel.errorMessage {
                StatusBanner(text: errorMessage, isError: true)
            }

            Button {
                Task {
                    await viewModel.generate(context: modelContext, isPlus: purchaseManager.isPlus)
                }
            } label: {
                Label("Generate my audio", systemImage: "sparkles")
            }
            .buttonStyle(GoldButtonStyle())
        }
    }

    private var generatingStep: some View {
        VStack(spacing: 20) {
            BreathingMoon(phase: MoonPhaseCalculator.phase(), glow: 0.8)
                .frame(height: 200)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(viewModel.streamedLines.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.callout)
                                .foregroundStyle(index == viewModel.streamedLines.count - 1 ? Theme.halo : Theme.mist)
                                .transition(.opacity)
                                .id(index)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 220)
                .onChange(of: viewModel.streamedLines.count) { _, newCount in
                    withAnimation {
                        proxy.scrollTo(newCount - 1, anchor: .bottom)
                    }
                }
            }
            HStack(spacing: 8) {
                ProgressView()
                    .tint(Theme.gold)
                Text("Weaving voice and sound…")
                    .font(.footnote)
                    .foregroundStyle(Theme.mist)
            }
        }
    }

    private var finishedStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.gold)
            Text(viewModel.engineLabel)
                .font(.caption)
                .foregroundStyle(Theme.mist)
            Text("Your session is saved in My Channel.")
                .font(.footnote)
                .foregroundStyle(Theme.halo)
            Button("Done") {
                dismiss()
            }
            .buttonStyle(GoldButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }
}
