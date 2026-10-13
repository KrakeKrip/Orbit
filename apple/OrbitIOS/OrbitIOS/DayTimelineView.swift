import SwiftUI
import OrbitCore

/// The 00:00–24:00 day timeline for one selected civil day: hour rulers,
/// timed blocks projected via `TaskDayProjector`, and a minimal local greedy
/// lane layout so overlapping tasks stay visible side by side. Lane widths
/// derive from the real container width (fit, no right clipping).
///
/// Painted geometry reflects the real interval duration (minimum 2pt for
/// visibility); tap and long-press (context menu) act on the painted stripe
/// itself, so adjacent short tasks never cover each other's controls. Full
/// title/range are always exposed via accessibility; tap opens the existing
/// interval editor of the source task, context menu reuses existing
/// complete/reopen and date operations. No resize/drag, no stored layout,
/// no new core API.
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
    private static let laneTrailing: CGFloat = 10
    /// Painted visibility floor for one-minute intervals; the real duration
    /// stays authoritative for layout neighbours (no 20pt stretching).
    private static let minPaintedHeight: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        ruler
                        blocks(containerWidth: geometry.size.width)
                    }
                    .frame(width: geometry.size.width, height: 24 * hourHeight + 24)
                    .background(Color(.systemBackground))
                }
                .onAppear {
                    proxy.scrollTo("hour-8", anchor: .top)
                }
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
            // 24:00 end boundary: a label on the closing line, not a 25th hour.
            HStack(spacing: 8) {
                Text("24:00")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .leading)
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 1)
                Spacer(minLength: 0)
            }
            .frame(height: 12, alignment: .top)
        }
        .padding(.leading, 8)
    }

    // MARK: - Blocks

    private func blocks(containerWidth: CGFloat) -> some View {
        let layout = laneLayout(for: segments)
        return ForEach(layout, id: \.segment.taskID) { item in
            if let task = task(item.segment.taskID) {
                timelineBlock(
                    for: item.segment,
                    task: task,
                    laneIndex: item.lane,
                    laneCount: item.laneCount,
                    containerWidth: containerWidth
                )
            }
        }
    }

    private func timelineBlock(
        for segment: TaskDayIntervalSegment,
        task: OrbitTask,
        laneIndex: Int,
        laneCount: Int,
        containerWidth: CGFloat
    ) -> some View {
        let startOffset = CGFloat(segment.startMinute) / 60 * hourHeight
        // Painted geometry = real duration; a tiny floor keeps one-minute
        // intervals visible without stretching to a fake 20pt block.
        let paintedHeight = max(
            CGFloat(segment.endMinute - segment.startMinute) / 60 * hourHeight,
            Self.minPaintedHeight
        )
        let endTimeText = segment.endMinute == 1440 ? "24:00" : clockString(segment.endMinute)
        let range = "\(clockString(segment.startMinute))–\(endTimeText)\(continuationMarkers(segment))"

        return Button(action: { onEditInterval(task) }) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(task.isCompleted ? Color(.systemGray4) : Color.orbitAccent.opacity(0.85))
            }
            .frame(height: paintedHeight)
        }
        .buttonStyle(.plain)
        .frame(width: laneWidth(laneCount: laneCount, containerWidth: containerWidth), alignment: .leading)
        .offset(x: blockX(laneIndex: laneIndex, laneCount: laneCount, containerWidth: containerWidth), y: startOffset)
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
        .accessibilityLabel("\(task.title), \(range)")
        .accessibilityHint("Открывает редактор времени задачи; удержание — завершить/дата")
        .accessibilityAddTraits(task.isCompleted ? [.isSelected] : [])
    }

    private func laneWidth(laneCount: Int, containerWidth: CGFloat) -> CGFloat {
        let available = containerWidth - Self.laneInset - Self.laneTrailing
        return max(2, available / CGFloat(max(laneCount, 1)) - 3)
    }

    private func blockX(laneIndex: Int, laneCount: Int, containerWidth: CGFloat) -> CGFloat {
        Self.laneInset + CGFloat(laneIndex) * laneWidth(laneCount: laneCount, containerWidth: containerWidth)
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
