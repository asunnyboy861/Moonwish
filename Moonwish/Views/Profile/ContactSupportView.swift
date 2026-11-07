import SwiftUI

struct SupportSubject: Identifiable, Hashable {
    let name: String
    let icon: String

    var id: String { name }
}

enum SupportSubjects {
    static let all: [SupportSubject] = [
        SupportSubject(name: "General", icon: "bubble.left.fill"),
        SupportSubject(name: "Feature Suggestion", icon: "lightbulb.fill"),
        SupportSubject(name: "Bug Report", icon: "ant.fill"),
        SupportSubject(name: "Usage Question", icon: "questionmark.circle.fill"),
        SupportSubject(name: "Performance Issue", icon: "gauge.with.dots.needle.67percent"),
        SupportSubject(name: "UI Improvement", icon: "paintpalette.fill"),
        SupportSubject(name: "Other", icon: "ellipsis.circle.fill")
    ]
}

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSubject: String = "General"
    @State private var customSubject: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var submitting = false
    @State private var statusMessage: String?
    @State private var isError = false

    private let messageLimit = 1000

    private var emailValid: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private var subjectValue: String {
        selectedSubject == "Other" ? customSubject.trimmingCharacters(in: .whitespacesAndNewlines) : selectedSubject
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        emailValid &&
        !subjectValue.isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        message.count <= messageLimit
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("How can we help?")
                            .font(Theme.title(.title2))
                            .foregroundStyle(Theme.halo)
                        Text("Choose a topic, tell us what happened, and we will reply by email within 48 hours.")
                            .font(.footnote)
                            .foregroundStyle(Theme.mist)

                        subjectGrid

                        if selectedSubject == "Other" {
                            TextField("What is it about?", text: $customSubject)
                                .textFieldStyle(SupportFieldStyle())
                        }

                        TextField("Your name", text: $name)
                            .textFieldStyle(SupportFieldStyle())

                        TextField("yourname@example.com", text: $email)
                            .textFieldStyle(SupportFieldStyle())
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        VStack(alignment: .trailing, spacing: 6) {
                            TextEditor(text: $message)
                                .frame(minHeight: 140)
                                .scrollContentBackground(.hidden)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Theme.cardFill)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Theme.cardStroke, lineWidth: 1)
                                        )
                                )
                                .overlay(alignment: .topLeading) {
                                    if message.isEmpty {
                                        Text("Tell us what's on your mind...")
                                            .font(.body)
                                            .foregroundStyle(Theme.mist)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 18)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .onChange(of: message) { _, newValue in
                                    if newValue.count > messageLimit {
                                        message = String(newValue.prefix(messageLimit))
                                    }
                                }
                            Text("\(message.count) / \(messageLimit)")
                                .font(.caption2)
                                .foregroundStyle(Theme.mist)
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            if submitting {
                                ProgressView().tint(Theme.midnightDeep)
                            } else {
                                Text("Submit")
                            }
                        }
                        .buttonStyle(GoldButtonStyle())
                        .disabled(!canSubmit || submitting)
                        .opacity(canSubmit && !submitting ? 1 : 0.6)

                        Text("We only use your email to respond to this feedback.")
                            .font(.caption2)
                            .foregroundStyle(Theme.mist)

                        if !email.isEmpty && !emailValid {
                            StatusBanner(text: "Please enter a valid email address.", isError: true)
                        }
                        if let statusMessage {
                            StatusBanner(text: statusMessage, isError: isError)
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

    private var subjectGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(SupportSubjects.all.filter { $0.name != "Other" }) { subject in
                subjectTile(subject)
            }
            subjectTile(SupportSubjects.all.first { $0.name == "Other" }!)
                .gridCellColumns(2)
                .frame(maxWidth: .infinity)
        }
    }

    private func subjectTile(_ subject: SupportSubject) -> some View {
        let selected = selectedSubject == subject.name
        return Button {
            selectedSubject = subject.name
        } label: {
            HStack(spacing: 8) {
                Image(systemName: subject.icon)
                    .font(.footnote)
                Text(subject.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                }
            }
            .foregroundStyle(selected ? Theme.midnightDeep : Theme.halo)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? Theme.gold : Theme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? Theme.gold : Theme.cardStroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(subject.name)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func submit() {
        submitting = true
        statusMessage = nil
        Task {
            do {
                try await SupportService.submit(name: name, email: email, subject: subjectValue, message: message)
                statusMessage = "Thank you! Your feedback has been sent."
                isError = false
                name = ""
                email = ""
                message = ""
                customSubject = ""
                selectedSubject = "General"
            } catch {
                statusMessage = error.localizedDescription
                isError = true
            }
            submitting = false
        }
    }
}

struct SupportFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Theme.cardStroke, lineWidth: 1)
                    )
            )
            .foregroundStyle(Theme.halo)
    }
}
