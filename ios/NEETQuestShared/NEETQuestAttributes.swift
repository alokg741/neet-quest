import Foundation
#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
public struct NEETQuestAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String
        public var endDate: Date
        public var isPaused: Bool
        public var remainingSeconds: Int

        public init(title: String, endDate: Date, isPaused: Bool, remainingSeconds: Int) {
            self.title = title
            self.endDate = endDate
            self.isPaused = isPaused
            self.remainingSeconds = remainingSeconds
        }
    }

    public var xpReward: Int
    public init(xpReward: Int = 50) {
        self.xpReward = xpReward
    }
}
#endif
