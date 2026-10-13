import SwiftUI
import OrbitCore

/// The 00:00–24:00 day timeline for one selected civil day: hour rulers,
/// timed blocks projected via `TaskDayProjector`, and a minimal local greedy
/// lane layout so overlapping tasks stay visible side by side. Blocks are
/// read-only visuals: tap opens the existing interval editor of the source
/// task, context menu reuses existing complete/reopen and date operations.
/// No resize/drag, no stored layout, no new core API.
struct DayTimelineView: View {
    let segments: [TaskDayIntervalSegment]
    /// Resolves a projected task UUID to the live shared-model task object.
    let task: (UUID) -> OrbitTask?
    let onEditInterval: (OrbitTask) -> Void
    let onComplete: (OrbitTask) -> Void
    let onReopen: (OrbitTask) -> Void
    let onEditDate: (OrbitTask) -> Void

    /// Uniform linear hour height.
    private let hourHeight: CGFloat = 64
    private static let laneInset: CGFloat = 56

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    ruler
                    blocks
                }
                .frame(height: 24 * hourHeight + 16)
                .background(Color(.systemBackground))
            }
            .onAppear {
                proxy.scrollTo("hour-08", anchor: .top)
            }
        }
    }

    // MARK: - Hour ruler

    private var ruler: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(spacing: 8) {
                    Text(String(format: "%02d:00", hour))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 1)
                    Spacer(minLength: 0)
                }
                .frame(height: hourHeight, alignment: .top)
                .id("hour-\(hour)")
            }
        }
        .padding(.leading, 8)
    }

    // MARK: - Blocks

    private var blocks: some View {
        let layout = laneLayout(for: segments)
        return ForEach(layout, id: \.segment.taskID) { item in
            if let task = task(item.segment.taskID) {
                timelineBlock(
                    for: item.segment,
                    task: task,
                    laneIndex: item.lane,
                    laneCount: item.laneCount
                )
            }
        }
    }

    private func timelineBlock(
        for segment: TaskDayIntervalSegment,
        task: OrbitTask,
        laneIndex: Int,
        laneCount: Int
    ) -> some View {
        let startOffset = CGFloat(segment.startMinute) / 60 * hourHeight
        let blockHeight = CGFloat(segment.endMinute - segment.startMinute) / 60 * hourHeight
        let endTimeText = segment.endMinute == 1440 ? "24:00" : clockString(segment.endMinute)
        let range = "\(clockString(segment.startMinute))–\(endTimeText)"
        let flags = continuationMarkers(segment)

        return Button(action: { onEditInterval(task) }) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(task.isCompleted ? Color(.systemGray4) : Color.orbitAccent.opacity(0.85))
                if segment.continuesFromPreviousDay {
                    VStack {
                        Image(systemName: "arrow.up.to.line")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 4)
                        Spacer(minLength: 0)
                    }
                }
                if segment.continuesIntoNextDay {
                    VStack {
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 4)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    if blockHeight >= 30 {
                        Text(task.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    if blockHeight >= 46 {
                        Text("\(range)\(flags)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.95))
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(height: max(blockHeight, 20))
        }
        .buttonStyle(.plain)
        .frame(
            width: laneWidth(laneCount: laneCount),
            height: max(blockHeight, 20),
            alignment: .top
        )
        .offset(x: blockX(laneIndex: laneIndex, laneCount: laneCount), y: startOffset)
        .contentShape(Rectangle())
        .contextMenu {
            Button(task.isCompleted ? "Снова открыть" : "Завершить") {
                if task.isCompleted {
                    onReopen(task)
                } else {
                    onComplete(task)
                }
            }
            Button("Дата задачи…") { onEditDate(task) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(task.title), \(range)\(flags)")
        .accessibilityHint("Открывает редактор времени задачи")
        .accessibilityAddTraits(task.isCompleted ? [.isSelected] : [])
    }

    private func blockX(laneIndex: Int, laneCount: Int) -> CGFloat {
        Self.laneInset + CGFloat(laneIndex) * laneWidth(laneCount: laneCount)
    }

    private func laneWidth(laneCount: Int) -> CGFloat {
        let available = UIScreen.main.bounds.width - Self.laneInset - 12
        return max(60, available / CGFloat(max(laneCount, 1)) - 4)
    }

    private func clockString(_ minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }

    private func continuationMarkers(_ segment: TaskDayIntervalSegment) -> String {
        var markers = ""
        if segment.continuesFromPreviousDay { markers += " ↑" }
        if segment.continuesIntoNextDay { markers += " ↓" }
        return markers
    }

    // MARK: - Greedy lane layout (local, minimal)

    private struct LaidOutSegment {
        let segment: TaskDayIntervalSegment
        let lane: Int
        let laneCount: Int
    }

    /// Minimal greedy lane assignment over the accepted projection order.
    /// Half-open intersection: touching segments (`end == next.start`) do not
    /// conflict. Clusters are maximal bursts of transitively overlapping
    /// segments; each cluster gets `laneCount = maximum simultaneous lanes`
    /// and every segment in it is widened to that count. Nothing is stored.
    private func laneLayout(for segments: [TaskDayIntervalSegment]) -> [LaidOutSegment] {
        var lanes: [(end: Int, cluster: Int)] = []
        var assigned: [(segment: TaskDayIntervalSegment, lane: Int, cluster: Int)] = []
        var clusterEnd = -1
        var cluster = 0

        for segment in segments {
            if segment.startMinute >= clusterEnd {
                // New cluster: nothing on this day overlaps the previous burst.
                cluster += 1
                lanes = [(end: segment.endMinute, cluster: cluster)]
                assigned.append((segment, 0, cluster))
                clusterEnd = segment.endMinute
                continue
            }
            if let free = lanes.firstIndex(where: { $0.cluster == cluster && $0.end <= segment.startMinute }) {
                lanes[free].end = segment.endMinute
                assigned.append((segment, free, cluster))
            } else {
                lanes.append((end: segment.endMinute, cluster: cluster))
                assigned.append((segment, lanes.count - 1, cluster))
            }
            clusterEnd = max(clusterEnd, segment.endMinute)
        }

        let lanesPerCluster = Dictionary(grouping: assigned, by: \.cluster)
            .mapValues { Set($0.map(\.lane)).count }
        return assigned.map { item in
            LaidOutSegment(segment: item.segment, lane: item.lane, laneCount: lanesPerCluster[item.cluster] ?? 1)
        }
    }
}
