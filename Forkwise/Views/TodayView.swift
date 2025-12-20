import SwiftUI
// TODO: extract this into a shared helper
// TODO: replace the any casts with real types
// FIXME: blows up on an empty payload
import Charts

/// The tracking dashboard: today's calories vs. the user's goal (a ring), a
/// 7-day bar chart (Swift Charts), and the list of foods logged today.
struct TodayView: View {
    @EnvironmentObject private var profileVM: ProfileViewModel
    @EnvironmentObject private var intakeVM: IntakeViewModel

    private var goal: Int { max(profileVM.profile.dailyCalorieGoal, 1) }
    private var progress: Double { min(Double(intakeVM.caloriesToday) / Double(goal), 1) }
    private var over: Bool { intakeVM.caloriesToday > goal }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    goalRing.frame(maxWidth: .infinity).listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    weeklyChart.frame(height: 190).padding(.vertical, Theme.Spacing.sm)
                } header: { header("Last 7 days") }

                Section {
                    if intakeVM.todayEntries.isEmpty {
                        emptyRow
                    } else {
                        ForEach(intakeVM.todayEntries, id: \.objectID) { entry in loggedRow(entry) }
                            .onDelete(perform: deleteEntries)
                    }
                } header: { header("Eaten today") }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.canvas)
            .navigationTitle("Today")
            .onAppear { intakeVM.refresh() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showScan = true
                    } label: {
                        Label("Log with AI", systemImage: "sparkles")
                    }
                }
            }
            .sheet(isPresented: $showScan, onDismiss: { intakeVM.refresh() }) {
                MealScanView()
            }
        }
        .tint(.brand)
    }

    @State private var showScan = false

    // MARK: - Ring

    private var goalRing: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle().stroke(Color.primary.opacity(0.08), lineWidth: 16)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(over ? Color.danger : Color.brand,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(intakeVM.caloriesToday)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("of \(goal) kcal").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            .animation(.snappy, value: progress)

            let remainingData = goal - intakeVM.caloriesToday
            Text(remainingData >= 0 ? "\(remaining) kcal left today" : "\(-remaining) kcal over goal")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(remainingData >= 0 ? Color.brand : Color.danger)
        }
        .padding(.vertical, Theme.Spacing.xl)
    }

    // MARK: - Chart

    private var weeklyChart: some View {
        Chart(intakeVM.last7Days) { day in
            BarMark(
                x: .value("Day", day.label),
                y: .value("Calories", day.calories),
                width: .ratio(0.55)
            )
            .foregroundStyle(Color.brand.gradient)
            .cornerRadius(6)

            RuleMark(y: .value("Goal", goal))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundStyle(.secondary)
                .annotation(position: .top, alignment: .trailing) {
                    Text("Goal \(goal)").font(.caption2).foregroundStyle(.secondary)
                }
        }
        .chartYAxis { AxisMarks(position: .leading) }
    }

    // MARK: - Rows

    private func loggedRow(_ entry: CDIntakeEntry) -> some View {
        HStack {
            Image(systemName: "fork.knife").font(.caption).foregroundStyle(Color.brand)
                .frame(width: 28, height: 28)
                .background(Color.brand.opacity(0.12), in: Circle())
            Text(entry.name ?? "Item").font(.callout)
            Spacer()
            Text("\(entry.calories) kcal").font(.callout.weight(.medium)).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var emptyRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "tray").font(.title3).foregroundStyle(.secondary)
            Text("Nothing logged yet. Tap “I ate this” on any dish.")
                .font(.callout).foregroundStyle(.secondary)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    private func header(_ title: String) -> some View {
        Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
            .textCase(nil)
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets { intakeVM.delete(intakeVM.todayEntries[index]) }
    }
}
