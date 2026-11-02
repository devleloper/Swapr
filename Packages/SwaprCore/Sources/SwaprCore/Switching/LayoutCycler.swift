public enum LayoutCycler {
    /// The source that follows `currentID` among the non-excluded sources, wrapping around.
    /// If the current source is not part of the cycle, the cycle starts from its first member.
    /// Returns `nil` when there is nothing to switch to.
    public static func next(after currentID: String?, in sources: [InputSource], excluding excluded: Set<String>) -> InputSource? {
        let cycle = sources.filter { !excluded.contains($0.id) }
        guard let first = cycle.first else { return nil }
        guard let index = cycle.firstIndex(where: { $0.id == currentID }) else { return first }
        let next = cycle[(index + 1) % cycle.count]
        return next.id == currentID ? nil : next
    }
}
