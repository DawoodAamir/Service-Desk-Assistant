import Observation
import SwiftUI

@main struct DeskApp: App {
  @State private var model = DeskModel()
  var body: some Scene { WindowGroup { DeskView(model: model) } }
}
@MainActor @Observable final class DeskModel {
  var snapshot = DeskSnapshot()
  var error: String?
  var ready = false
  let store: DeskStore
  init() {
    let folder = URL.applicationSupportDirectory
    let run = ProcessInfo.processInfo.environment["DESK_TEST_RUN"].flatMap(UUID.init(uuidString:))
    store = DeskStore(
      url: folder.appendingPathComponent(
        run.map { "Tests/\($0)/desk.json" } ?? "ServiceDesk/library.json"))
  }
  func load() async {
    do {
      snapshot = try await store.load()
      ready = true
    } catch { self.error = error.localizedDescription }
  }
  func save(_ item: DeskCase) async -> Bool {
    do {
      snapshot = try await store.save(item)
      return true
    } catch {
      self.error = error.localizedDescription
      return false
    }
  }
}
