import Foundation
import Testing

@testable import DeskCore

@Test func guideRetrievalEvaluation() {
  let fixtures = [
    ("printer offline queue", "Printer: offline or queued jobs"),
    ("wifi network internet", "Wi-Fi: connection without internet"),
    ("app crash launch version", "App: repeated crash on launch"),
  ]
  for (query, expected) in fixtures {
    #expect(GuideSearch.search(query, in: DeskStore.samples).first?.guide.title == expected)
  }
  #expect(GuideSearch.search("orchid gardening", in: DeskStore.samples).isEmpty)
  #expect(GuideSearch.search("", in: DeskStore.samples).isEmpty)
}
@Test func reviewedTicketsPersistAndRejectStaleEdits() async throws {
  let url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent(
    "desk.json")
  defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
  let store = DeskStore(url: url)
  let sample = try await store.addSampleGuides()
  var ticket = DeskCase(
    title: "Printer offline", description: "Queue paused", resolution: "Check selected printer",
    sourceIDs: sample.guides.map(\.id))
  _ = try await store.save(ticket)
  ticket.status = "Resolved"
  _ = try await store.save(ticket)
  await #expect(throws: DeskError.self) { _ = try await store.save(ticket) }
  #expect(try await DeskStore(url: url).load().cases[0].status == "Resolved")
  #expect(try await store.addSampleGuides().guides.count == 3)
}
@Test func corruptHistoryIsNotReplaced() async throws {
  let url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: url) }
  let original = Data("broken".utf8)
  try original.write(to: url)
  await #expect(throws: DeskError.self) { _ = try await DeskStore(url: url).load() }
  #expect(try Data(contentsOf: url) == original)
}

@Test func guideExcerptsRetainRelevantLaterText() {
  let guide = Guide(
    title: "Troubleshooting",
    body: String(repeating: "Introduction ", count: 1000)
      + "\nPrinter queue: inspect paused jobs and selected printer.")
  let excerpt = GuideSearch.excerpt(guide, query: "printer queue")
  #expect(excerpt.contains("paused jobs"))
  #expect(excerpt.count <= 1500)
}
