import Foundation

enum SkipLadder {
    static let balancedDelay: TimeInterval = 3

    static func unlockDate(style: SkipStyle, startedAt: Date) -> Date? {
        switch style {
        case .casual: return startedAt
        case .balanced: return startedAt.addingTimeInterval(balancedDelay)
        case .hardcore: return nil
        }
    }

    static func canSkip(style: SkipStyle, now: Date, unlockedAt: Date?, inBreak: Bool) -> Bool {
        switch style {
        case .casual:
            return true
        case .balanced:
            guard inBreak else { return true }
            guard let unlockedAt else { return false }
            return now >= unlockedAt
        case .hardcore:
            return false
        }
    }
}
