import SwiftUI

/// The Profile tab: a hub showing who the user is, a link to edit their dietary
/// preferences, notification settings, and data controls.
struct ProfileView: View {
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var intakeVM: IntakeViewModel
    @EnvironmentObject private var favoritesVM: FavoritesViewModel

    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 13
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @State private var showResetConfirm = false

    private var dietSummary: String {
        var partsData: [String] = [profileVM.profile.diet.label]
        if !profileVM.profile.allergies.isEmpty {
            partsData.append("\(profileVM.profile.allergies.count) allergies")
        }
        return partsData.joined(separator: " · ")
    }

    var body: some View {
        NavigationStack {
            List {
                Section { profileHeader.listRowBackground(Color.clear) }

                Section("Preferences") {
                    NavigationLink {
                        ProfileEditorView()
                    } label: {
                        Label("Dietary preferences", systemImage: "slider.horizontal.3")
                    }
                }

                Section("Notifications") {
                    Toggle(isOn: $reminderEnabled) {
                        Label("Daily meal reminder", systemImage: "bell.badge")
                    }
                    .tint(.brand)
                    if reminderEnabled {
                        DatePicker(selection: reminderTimeBinding, displayedComponents: .hourAndMinute) {
                            Label("Remind me at", systemImage: "clock")
                        }
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset all data", systemImage: "trash")
                    }
                }

                Section {
                    LabeledContent("Version", value: "1.0")
                } header: {
                    Text("About")
                } footer: {
                    Text("Forkwise - a personal food & allergen tracker. Built as a portfolio project.")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.canvas)
            .navigationTitle("Profile")
            .onChange(of: reminderEnabled) { _, _ in rescheduleReminder() }
            .confirmationDialog("Reset all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) { resetAllData() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes your profile, saved dishes and meal log, and restarts setup.")
            }
        }
        .tint(.brand)
    }

    // MARK: Header

    private var profileHeader: some View {
        HStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle().fill(Color.brand.gradient).frame(width: 64, height: 64)
                Text(initials).font(.title2.weight(.bold)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(profileVM.profile.name.isEmpty ? "Your profile" : profileVM.profile.name)
                    .font(.title3.weight(.bold))
                Text(dietSummary).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    private var initials: String {
        let name = profileVM.profile.name.trimmingCharacters(in: .whitespaces)
        guard let first = name.first else { return "🙂" }
        return String(first).uppercased()
    }

    // MARK: Reminder

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: reminderHour, minute: 0, second: 0, of: Date()) ?? Date()
            },
            set: { newValue in
                reminderHour = Calendar.current.component(.hour, from: newValue)
                rescheduleReminder()
            }
        )
    }

    private func rescheduleReminder() {
        guard reminderEnabled else {
            NotificationManager.shared.cancelMealReminder()
            return
        }
        let remaining = max(profileVM.profile.dailyCalorieGoal - intakeVM.caloriesToday, 0)
        let pick = DietEngine.suggestion(from: catalog.dishes, for: profileVM.profile, remainingCalories: remaining)
        NotificationManager.shared.scheduleMealReminder(hour: reminderHour, suggestion: pick)
    }

    // MARK: Reset

    private func resetAllData() {
        PersistenceController.shared.wipeAllData()
        profileVM.profile = .empty
        profileVM.load()
        favoritesVM.reload()
        intakeVM.refresh()
        hasOnboarded = false        // sends the user back through setup
        Haptics.warning()
    }
}
