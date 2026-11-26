import SwiftUI
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit

@main
struct NEETQuestWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            NEETQuestLiveActivity()
        }
    }
}

@available(iOS 16.1, *)
struct NEETQuestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NEETQuestAttributes.self) { context in
            // Lock Screen / Notification Center Banner
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [.purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(context.state.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("+\(context.attributes.xpReward) XP Focus Sprint")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.cyan)
                }

                Spacer()

                if context.state.isPaused {
                    Text("PAUSED")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(.orange)
                } else {
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(14)
            .activityBackgroundTint(Color(red: 10/255, green: 10/255, blue: 18/255))
            .activitySystemActionForegroundColor(.cyan)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("NEET Quest", systemImage: "bolt.fill")
                        .font(.caption.bold())
                        .foregroundColor(.cyan)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("+\(context.attributes.xpReward) XP")
                        .font(.caption.bold())
                        .foregroundColor(.purple)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.title)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                        Spacer()
                        if context.state.isPaused {
                            Text("PAUSED")
                                .font(.headline.monospacedDigit())
                                .foregroundColor(.orange)
                        } else {
                            Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                                .font(.title3.bold().monospacedDigit())
                                .foregroundColor(.white)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.cyan)
            } compactTrailing: {
                if context.state.isPaused {
                    Text("II")
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                } else {
                    Text(timerInterval: Date()...context.state.endDate, countsDown: true)
                        .font(.caption2.bold().monospacedDigit())
                        .frame(width: 44)
                }
            } minimal: {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.cyan)
            }
        }
    }
}
#endif
