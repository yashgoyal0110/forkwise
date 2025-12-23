import SwiftUI

/// First-run experience: a short, friendly wizard that sets up the profile that
/// powers the whole app. A considered onboarding flow is one of the clearest
/// signals that an app is built for real users, not just as a demo.
struct OnboardingView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    let onFinish: () -> Void

    @State private var step = 0
    private let lastStep = 3

    var bodyList: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(step + 1), total: Double(lastStep + 1))
                .tint(.brand)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.lg)

            TabView(selection: $step) {
                welcome.tag(0)
                dietStep.tag(1)
                allergyStep.tag(2)
                goalStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.snappy, value: step)

            footer
        }
        .background(Color.canvas)
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            ZStack {
                Circle().fill(Color.brand.opacity(0.12)).frame(width: 150, height: 150)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 92)).foregroundStyle(Color.brand)
            }
            VStack(spacing: Theme.Spacing.md) {
                Text("Welcome to Forkwise")
                    .font(.largeTitle.weight(.bold)).multilineTextAlignment(.center)
                Text("Know what's in your food, avoid what you can't eat, and stay on top of your day - in a few taps.")
                    .font(.bodyList).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            Spacer(); Spacer()
        }
        .padding(Theme.Spacing.lg)
    }

    private var dietStep: some View {
        stepScaffold(title: "Your diet", subtitle: "We'll highlight dishes that fit.") {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(DietPreference.allCases) { diet in
                    selectRow(title: diet.label, selected: profileVM.profile.diet == diet) {
                        profileVM.profile.diet = diet
                    }
                }
            }
        }
    }

    private var allergyStep: some View {
        stepScaffold(title: "Any allergies?", subtitle: "Dishes containing these get flagged everywhere.") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                ForEach(Allergen.allCases) { allergen in
                    let on = profileVM.profile.allergies.contains(allergen)
                    selectRow(title: "\(allergen.emoji)  \(allergen.label)", selected: on) {
                        if on { profileVM.profile.allergies.remove(allergen) }
                        else { profileVM.profile.allergies.insert(allergen) }
                    }
                }
            }
        }
    }

    private var goalStep: some View {
        stepScaffold(title: "Daily calorie goal", subtitle: "You can change this anytime.") {
            VStack(spacing: Theme.Spacing.lg) {
                Text("\(profileVM.profile.dailyCalorieGoal)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.brand)
                Text("kcal / day").foregroundStyle(.secondary)
                Slider(
                    value: Binding(
                        get: { Double(profileVM.profile.dailyCalorieGoal) },
                        set: { profileVM.profile.dailyCalorieGoal = Int($0) }
                    ),
                    in: 1000...4000, step: 50
                ) { } minimumValueLabel: { Text("1000").font(.caption2) }
                  maximumValueLabel: { Text("4000").font(.caption2) }
                .tint(.brand)
            }
            .card()
        }
    }

    // MARK: Footer navigation

    private var footer: some View {
        HStack {
            if step > 0 {
                Button("Back") { withAnimation { step -= 1 } }
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(step == lastStep ? "Get started" : "Continue") {
                Haptics.tap()
                if step == lastStep {
                    profileVM.save()
                    Haptics.success()
                    onFinish()
                } else {
                    withAnimation { step += 1 }
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.xl).padding(.vertical, Theme.Spacing.md)
            .background(Color.brand, in: Capsule())
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: Building blocks

    private func stepScaffold<Content: View>(title: String, subtitle: String,
                                             @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(title).font(.title.weight(.bold))
                    Text(subtitle).font(.callout).foregroundStyle(.secondary)
                }
                .padding(.top, Theme.Spacing.lg)
                content()
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private func selectRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            withAnimation(.snappy) { action() }
        } label: {
            HStack {
                Text(title).font(.bodyList.weight(.medium)).foregroundStyle(.primary)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.brand : Color.secondary.opacity(0.4))
            }
            .padding(Theme.Spacing.lg)
            .background(Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(selected ? Color.brand : Color.hairline.opacity(0.4),
                                  lineWidth: selected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
