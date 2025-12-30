import SwiftUI

/// Edits the dietary profile that powers all personalisation. Changes save to
/// Core Data immediately so they're reflected across the app the moment you
/// leave the screen.
struct ProfileEditorView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel

    var body: some View {
        Form {
            Section("About you") {
                TextField("Your name", text: $profileVM.profile.name)
            }

            Section("Diet") {
                Picker("Preference", selection: $profileVM.profile.diet) {
                    ForEach(DietPreference.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section {
                ForEach(Allergen.allCases) { allergen in
                    Toggle(isOn: binding(for: allergen)) {
                        Text("\(allergen.emoji)  \(allergen.label)")
                    }
                    .tint(.brand)
                }
            } header: {
                Text("I'm allergic to")
            } footer: {
                Text("Dishes containing anything you select are flagged across the app.")
            }

            Section("Daily calorie goal") {
                Stepper(value: $profileVM.profile.dailyCalorieGoal, in: 1000...4000, step: 50) {
                    Text("\(profileVM.profile.dailyCalorieGoal) kcal")
                }
            }
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: profileVM.profile) { _, _ in profileVM.save() }
    }

    private func binding(for allergen: Allergen) -> Binding<Bool> {
        Binding(
            get: { profileVM.profile.allergies.contains(allergen) },
            set: { isOn in
                Haptics.selection()
                if isOn { profileVM.profile.allergies.insert(allergen) }
                else { profileVM.profile.allergies.remove(allergen) }
            }
        )
    }
}
