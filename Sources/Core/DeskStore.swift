import Foundation

public struct Guide: Codable, Sendable, Identifiable, Equatable {
  public var id: UUID
  public var title: String
  public var body: String
  public init(id: UUID = UUID(), title: String, body: String) {
    self.id = id
    self.title = title
    self.body = body
  }
}
public struct GuideMatch: Sendable, Identifiable {
  public var guide: Guide
  public var score: Double
  public var id: UUID { guide.id }
}
public enum GuideSearch {
  public static func tokens(_ text: String) -> Set<String> {
    Set(
      text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter {
        $0.count > 2
      })
  }
  public static func excerpt(_ guide: Guide, query: String, limit: Int = 1500) -> String {
    let words = tokens(query)
    let paragraphs = guide.body.components(separatedBy: "\n")
    let best =
      paragraphs.max { tokens($0).intersection(words).count < tokens($1).intersection(words).count }
      ?? guide.body
    let first =
      words.compactMap { best.range(of: $0, options: .caseInsensitive)?.lowerBound }.min()
      ?? best.startIndex
    let start = best.index(first, offsetBy: -100, limitedBy: best.startIndex) ?? best.startIndex
    return String(best[start...].prefix(max(0, limit)))
  }
  public static func search(_ query: String, in guides: [Guide], limit: Int = 4) -> [GuideMatch] {
    let words = tokens(query)
    guard !words.isEmpty else { return [] }
    return guides.compactMap { guide in
      let title = tokens(guide.title)
      let body = tokens(guide.body)
      let overlap = words.intersection(title.union(body))
      guard !overlap.isEmpty else { return nil }
      return GuideMatch(
        guide: guide,
        score: Double(overlap.count + words.intersection(title).count * 2) / Double(words.count))
    }.sorted { $0.score == $1.score ? $0.guide.title < $1.guide.title : $0.score > $1.score }
      .prefix(max(0, limit)).map { $0 }
  }
}
public struct DeskCase: Codable, Sendable, Identifiable, Equatable {
  public var id = UUID()
  public var title: String
  public var description: String
  public var resolution: String
  public var sourceIDs: [UUID]
  public var priority: String
  public var status = "Open"
  public var created = Date()
  public var revision = 0
  public init(
    title: String, description: String, resolution: String, sourceIDs: [UUID],
    priority: String = "Normal"
  ) {
    self.title = title
    self.description = description
    self.resolution = resolution
    self.sourceIDs = sourceIDs
    self.priority = priority
  }
}
public struct DeskSnapshot: Codable, Sendable {
  public var version = 1
  public var guides: [Guide] = []
  public var cases: [DeskCase] = []
  public init() {}
}
public enum DeskError: LocalizedError, Sendable {
  case invalid, conflict, corrupt
  public var errorDescription: String? {
    switch self {
    case .invalid: "Enter a title and description within the displayed limits."
    case .conflict: "This record changed. Reopen it before saving."
    case .corrupt: "The saved library couldn't be read. Its file has been preserved."
    }
  }
}
public actor DeskStore {
  private let url: URL
  private var state: DeskSnapshot?
  public init(url: URL) { self.url = url }
  public func load() throws -> DeskSnapshot {
    if let state { return state }
    if FileManager.default.fileExists(atPath: url.path) {
      let data = try Data(contentsOf: url)
      guard data.count <= 10_000_000,
        let value = try? JSONDecoder().decode(DeskSnapshot.self, from: data), value.version == 1,
        Set(value.guides.map(\.id)).count == value.guides.count,
        Set(value.cases.map(\.id)).count == value.cases.count
      else { throw DeskError.corrupt }
      state = value
    } else {
      state = DeskSnapshot()
    }
    return state!
  }
  private func persist(_ value: DeskSnapshot) throws {
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try JSONEncoder().encode(value).write(to: url, options: .atomic)
    state = value
  }
  public func save(_ item: DeskCase) throws -> DeskSnapshot {
    guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      item.title.count <= 200,
      !item.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      item.description.count <= 4000, item.resolution.count <= 8000,
      ["Low", "Normal", "High"].contains(item.priority), ["Open", "Resolved"].contains(item.status)
    else { throw DeskError.invalid }
    var next = try load()
    var updated = item
    if let i = next.cases.firstIndex(where: { $0.id == item.id }) {
      guard next.cases[i].revision == item.revision else { throw DeskError.conflict }
      updated.revision += 1
      next.cases[i] = updated
    } else {
      next.cases.insert(updated, at: 0)
    }
    try persist(next)
    return next
  }
  public func addGuide(_ title: String, body: String) throws -> DeskSnapshot {
    guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, title.count <= 200,
      !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, body.count <= 12000
    else { throw DeskError.invalid }
    var next = try load()
    next.guides.append(Guide(title: title, body: body))
    try persist(next)
    return next
  }
  public func addSampleGuides() throws -> DeskSnapshot {
    var next = try load()
    for guide in Self.samples where !next.guides.contains(where: { $0.id == guide.id }) {
      next.guides.append(guide)
    }
    try persist(next)
    return next
  }
  public static let samples = [
    Guide(
      id: UUID(uuidString: "320FF413-E1D0-4E35-A391-862A39478131")!,
      title: "Printer: offline or queued jobs",
      body:
        "Sample guide. Check that the printer is powered on and connected to the same network. Inspect the selected printer and paused queue. Print a test page. If other devices also fail, record the printer model and network status before escalating. Do not reset network settings without the owner's agreement."
    ),
    Guide(
      id: UUID(uuidString: "320FF413-E1D0-4E35-A391-862A39478132")!,
      title: "Wi-Fi: connection without internet",
      body:
        "Sample guide. Check whether one device or every device is affected. Confirm the intended Wi-Fi network, then test a known site. Record router status and whether a wired device has internet. Do not request passwords or suggest bypassing certificate warnings. Escalate an outage affecting multiple devices."
    ),
    Guide(
      id: UUID(uuidString: "320FF413-E1D0-4E35-A391-862A39478133")!,
      title: "App: repeated crash on launch",
      body:
        "Sample guide. Record the app version, operating system, and last successful launch. Try a normal restart and check for an official update. Collect an approved crash report after removing private data. Do not delete the app's documents as a troubleshooting shortcut."
    ),
  ]
}
