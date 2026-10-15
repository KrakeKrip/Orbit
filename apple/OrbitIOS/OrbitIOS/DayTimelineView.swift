import SwiftUI
import OrbitCore

/// The 00:00–24:00 day timeline for one selected civil day: hour rulers,
/// timed blocks projected via `TaskDayProjector`, and a minimal local greedy
/// lane layout so overlapping tasks stay visible side by side.
///
/// Painted block height is the exact interval duration
/// (`(end − start) / 60 × hourHeight`, e.g. one minute ≈ 1.07pt at 64pt/hour)
/// — no stretching to a fake block size. Tap and long-press (context menu)
/// act on the painted stripe itself. For tiny/dense intervals the native
/// «⋯» → «Задачи дня» menu next to the date controls in `CalendarDayScreen`
/// is the accessible selection path: it lists only the real segments of the
/// selected day with the existing callbacks (interval editor, date editor,
/// complete/reopen).
/// Full title/range stay in the accessibility labels. No resize/drag, no
/// stored layout, no new core API.
struct DayTimelineView: View {
    @Environment(\.orbitAppearance) private var appearance
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let segments: [TaskDayIntervalSegment]
    /// Resolves a projected task UUID to the live shared-model task object.
    let task: (UUID) -> OrbitTask?
    let onEditInterval: (OrbitTask) -> Void
    let onComplete: (OrbitTask) -> Void
    let onReopen: (OrbitTask) -> Void
    let onEditDate: (OrbitTask) -> Void
    let onRename: (OrbitTask) -> Void
    let onDelete: (OrbitTask) -> Void

    /// Uniform linear hour height.
    private let hourHeight: CGFloat = 64
    private static let laneInset: CGFloat = 56
    private static let laneTrailing: CGFloat = 10
    /// Visible gutter between side-by-side lanes.
    private static let laneGutter: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        ruler
                        blocks(containerWidth: geometry.size.width)
                            .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: segments)
                    }
                    .frame(width: geometry.size.width, height: 24 * hourHeight + 24)
                    .background(appearance.canvas)
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
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
        // Exact painted geometry: one minute is 1.0667pt at 64pt/hour — no
        // floor, no stretch. The compact menu above is the accessible path
        // to tiny stripes.
        let paintedHeight = CGFloat(segment.endMinute - segment.startMinute) / 60 * hourHeight
        let endTimeText = segment.endMinute == 1440 ? "24:00" : clockString(segment.endMinute)
        let range = "\(clockString(segment.startMinute))–\(endTimeText)\(continuationMarkers(segment))"

        return Menu {
            menuActions(for: task)
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(task.isCompleted ? Color(.systemGray4) : Color.orbitAccent.opacity(0.85))
                if paintedHeight >= 24 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(task.isCompleted ? Color(.systemGray5) : .white)
                            .lineLimit(1)
                        Text(range)
                            .font(.caption2)
                            .foregroundStyle(task.isCompleted ? Color(.systemGray5) : .white.opacity(0.95))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                }
                if segment.continuesFromPreviousDay {
                    Image(systemName: "arrow.up.to.line")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 3)
                }
                if segment.continuesIntoNextDay {
                    VStack {
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 3)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(
            width: laneWidth(laneCount: laneCount, containerWidth: containerWidth),
            height: paintedHeight,
            alignment: .top
        )
        .clipped()
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 6))
        .contextMenu {
            menuActions(for: task)
        } preview: {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title).font(.headline)
                Text(range).font(.subheadline.monospacedDigit())
            }
            .padding(14)
            .frame(width: min(300, max(160, containerWidth - 32)), alignment: .leading)
            .background(appearance.canvas, in: RoundedRectangle(cornerRadius: 14))
        }
        .orbitLongPressFeedback()
        .orbitMenuFeedback()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(task.title), \(range)")
        .accessibilityHint("Открывает меню задачи; меню в шапке — полный список")
        .accessibilityAddTraits(task.isCompleted ? [.isSelected] : [])
        // Position outside the interactive source: the menu's local source
        // rect no longer includes a translated, origin-based snapshot.
        .position(
            x: blockX(laneIndex: laneIndex, laneCount: laneCount, containerWidth: containerWidth)
                + laneWidth(laneCount: laneCount, containerWidth: containerWidth) / 2,
            y: startOffset + paintedHeight / 2
        )
    }

    private func menuActions(for task: OrbitTask) -> some View {
        OrbitTaskMenuActions(
            task: task,
            onToggle: { if task.isCompleted { onReopen(task) } else { onComplete(task) } },
            onEditDate: { onEditDate(task) }, onEditInterval: { onEditInterval(task) },
            onRename: { onRename(task) }, onDelete: { onDelete(task) }
        )
    }

    private func laneWidth(laneCount: Int, containerWidth: CGFloat) -> CGFloat {
        let available = containerWidth - Self.laneInset - Self.laneTrailing
        let count = CGFloat(max(laneCount, 1))
        return max(1, (available - (count - 1) * Self.laneGutter) / count)
    }

    private func blockX(laneIndex: Int, laneCount: Int, containerWidth: CGFloat) -> CGFloat {
        Self.laneInset + CGFloat(laneIndex) * (laneWidth(laneCount: laneCount, containerWidth: containerWidth) + Self.laneGutter)
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
