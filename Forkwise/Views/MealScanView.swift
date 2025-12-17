import SwiftUI
import PhotosUI
import UIKit

/// The AI "log a meal" screen. Snap/pick a photo **or** describe a meal in words;
/// the backend (Gemini, server-side) returns an estimated calorie + allergen
/// breakdown, flagged SAFE/UNSAFE against the user's own allergy profile, which
/// can then be logged with one tap.
struct MealScanView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var intakeVM: IntakeViewModel
    @Environment(\.dismiss) private var dismiss

    private let ai = AIService()

    enum Mode: String, CaseIterable, Identifiable { case photo = "Photo", text = "Describe"; var id: String { rawValue } }
    @State private var mode: Mode = .photo

    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var imageData: Data?
    @State private var text = ""

    @State private var isLoading = false
    @State private var result: MealAnalysisResult?
    @State private var errorMessage: String?
    @State private var didLog = false

    private var allergies: [Allergen] { Array(profileVM.profile.allergies) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: mode) { _, _ in reset() }

                    if mode == .photo { photoInput } else { textInput }

                    if isLoading {
                        VStack(spacing: Theme.Spacing.sm) {
                            ProgressView().controlSize(.large)
                            Text("Analyzing with AI…").font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.top, Theme.Spacing.lg)
                    }

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.footnote).foregroundStyle(Color.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding().background(Color.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }

                    if let result { resultCard(result) }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Color.canvas)
            .navigationTitle("Log a meal with AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
        .tint(.brand)
    }

    // MARK: - Inputs

    private var photoInput: some View {
        VStack(spacing: Theme.Spacing.md) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable().scaledToFill()
                        .frame(height: 220).frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                } else {
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "camera.viewfinder").font(.system(size: 44))
                        Text("Choose a food photo").font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(Color.brand)
                    .frame(maxWidth: .infinity).frame(height: 160)
                    .background(Color.brand.opacity(0.08), in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .strokeBorder(Color.brand.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6])))
                }
            }
            .onChange(of: pickerItem) { _, newItem in Task { await loadImage(newItem) } }

            analyzeButton(enabled: imageData != nil) {
                guard let imageData else { return }
                await run { try await ai.analyze(imageData: imageData, allergies: allergies) }
            }
        }
    }

    private var textInput: some View {
        VStack(spacing: Theme.Spacing.md) {
            TextField("e.g. 2 rotis, dal and a mango lassi", text: $text, axis: .vertical)
                .lineLimit(2...4)
                .padding().background(Color.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.hairline.opacity(0.5), lineWidth: 0.5))

            analyzeButton(enabled: text.trimmingCharacters(in: .whitespaces).count > 1) {
                await run { try await ai.parse(text: text, allergies: allergies) }
            }
        }
    }

    private func analyzeButton(enabled: Bool, action: @escaping () async -> Void) -> some View {
        Button {
            Haptics.tap()
            Task { await action() }
        } label: {
            Label("Analyze", systemImage: "sparkles")
                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent).tint(.brand).controlSize(.large)
        .disabled(!enabled || isLoading)
    }

    // MARK: - Result

    private func resultCard(_ r: MealAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text(r.analysis.name).font(.title3.weight(.bold))
                Spacer()
                Text("\(r.analysis.calories) kcal").font(.headline).foregroundStyle(Color.brand)
            }

            SafetyBadge(safety: r.safety.asDishSafety)

            if !r.analysis.typedAllergens.isEmpty {
                FlowRow(r.analysis.typedAllergens) { a in
                    Text("\(a.emoji) \(a.label)").font(.caption)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.danger.opacity(0.10), in: Capsule()).foregroundStyle(Color.danger)
                }
            }

            if !r.analysis.notes.isEmpty {
                Text(r.analysis.notes).font(.footnote).foregroundStyle(.secondary)
            }

            Label("AI estimate · \(Int(r.analysis.confidence * 100))% confidence",
                  systemImage: "sparkles")
                .font(.caption2).foregroundStyle(.secondary)

            Button {
                intakeVM.log(name: r.analysis.name, calories: r.analysis.calories)
                Haptics.success()
                withAnimation(.snappy) { didLog = true }
            } label: {
                Label(didLog ? "Added to Today" : "Log it", systemImage: didLog ? "checkmark.circle.fill" : "plus.circle.fill")
                    .frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent).tint(didLog ? .safe : .brand).controlSize(.large)
            .disabled(didLog)
            .padding(.top, Theme.Spacing.xs)
        }
        .card()
    }

    // MARK: - Actions

    private func run(_ work: @escaping () async throws -> MealAnalysisResult) async {
        isLoading = true; errorMessage = nil; result = nil; didLog = false
        do {
            result = try await work()
            Haptics.selection()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't analyze that. Try again."
            Haptics.warning()
        }
        isLoading = false
    }

    private func loadImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        reset()
        guard let data = try? await item.loadTransferable(type: Data.self),
              let ui = UIImage(data: data) else {
            errorMessage = "Couldn't load that image."
            return
        }
        let resizedValue = ui.downscaled(maxDimension: 1024)
        previewImage = resizedValue
        imageData = resizedValue.jpegData(compressionQuality: 0.7)
    }

    private func reset() {
        result = nil; errorMessage = nil; didLog = false
    }
}

// TODO: the remaining handlers land in the next pass
