import SwiftUI
import UniformTypeIdentifiers

struct DeskView: View {
  @Bindable var model: DeskModel
  @State private var selection: String? = "New case"
  @State private var issue = ""
  @State private var assistant = DeskAssistant()
  @State private var draft: DeskCase?
  @State private var guideEditor = false
  @State private var photo: URL?
  @State private var importing = false
  @State private var importBusy = false
  @State private var photoToken = UUID()
  @State private var photos = PhotoImport()
  private var matches: [GuideMatch] { GuideSearch.search(issue, in: model.snapshot.guides) }
  var body: some View {
    NavigationSplitView {
      List(selection: $selection) {
        NavigationLink(value: "New case") { Label("New case", systemImage: "square.and.pencil") }
        NavigationLink(value: "Guides") { Label("Knowledge guides", systemImage: "books.vertical") }
        Section("Cases") {
          ForEach(model.snapshot.cases) { item in
            NavigationLink(value: item.id.uuidString) {
              VStack(alignment: .leading) {
                Text(item.title)
                Text("\(item.status) · \(item.priority)").font(.caption).foregroundStyle(.secondary)
              }
            }
          }
        }
      }.navigationTitle("Service Desk")
        .navigationSplitViewColumnWidth(min: 220, ideal: 270)
    } detail: {
      if selection == "Guides" {
        guides
      } else if let item = model.snapshot.cases.first(where: { $0.id.uuidString == selection }) {
        caseDetail(item)
      } else {
        composer
      }
    }
    .task { await model.load() }
    .sheet(item: $draft) { item in TicketEditor(item: item, model: model) }
    .sheet(isPresented: $guideEditor) { GuideEditor(model: model) }
    .fileImporter(isPresented: $importing, allowedContentTypes: [.image]) { result in
      switch result {
      case .success(let url): importPhoto(url)
      case .failure(let error): model.error = error.localizedDescription
      }
    }
    .alert(
      "Couldn't finish",
      isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })
    ) {
      Button("OK") { model.error = nil }
    } message: {
      Text(model.error ?? "")
    }
    .onChange(of: issue) {
      assistant.cancel()
      assistant.text = ""
    }
    .onDisappear {
      assistant.cancel()
      if let photo {
        Task { await photos.remove(photo) }
        self.photo = nil
      }
    }
  }
  private var composer: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Start with the issue").font(.title2).bold()
          Text("Find a guide, ask for a suggestion, then review the ticket.").foregroundStyle(
            .secondary)
        }
        TextField("What is happening?", text: $issue, axis: .vertical).lineLimit(4...10)
          .textFieldStyle(.roundedBorder).accessibilityIdentifier("desk-issue")
        HStack {
          Button(
            photo == nil ? "Attach photo" : "Remove photo",
            systemImage: photo == nil ? "photo.badge.plus" : "xmark.circle"
          ) {
            assistant.cancel()
            assistant.text = ""
            if let photo {
              Task { await photos.remove(photo) }
              self.photo = nil
              photoToken = UUID()
            } else {
              importing = true
            }
          }.disabled(importBusy)
          if importBusy { ProgressView() }
          if photo != nil {
            Text("Photo attached · session only").font(.caption).foregroundStyle(.secondary)
          }
        }
        GroupBox("Matching guides") {
          VStack(alignment: .leading, spacing: 12) {
            if model.snapshot.guides.isEmpty {
              Text("Add your own guides or load the labelled sample set in Knowledge guides.")
                .foregroundStyle(.secondary)
            } else if matches.isEmpty {
              Text("No matching guide. Add details or prepare a manual ticket.").foregroundStyle(
                .secondary)
            }
            ForEach(matches) { match in
              DisclosureGroup(match.guide.title) {
                Text(match.guide.body).textSelection(.enabled).padding(.vertical, 8)
              }
            }
          }.frame(maxWidth: .infinity, alignment: .leading)
        }
        HStack {
          Button("Suggest next steps", systemImage: "sparkles") {
            assistant.generate(issue: issue, matches: matches, photo: photo, ticket: false)
          }
          .disabled(
            assistant.busy || !assistant.available || issue.isEmpty || matches.isEmpty || importBusy
          )
          if assistant.busy {
            ProgressView()
            Button("Cancel") { assistant.cancel() }
          }
        }
        if !assistant.available {
          Text("Apple Intelligence isn't ready. Guide search and manual tickets remain available.")
            .font(.callout).foregroundStyle(.secondary)
        }
        if let error = assistant.error { Text(error).foregroundStyle(.red) }
        if !assistant.text.isEmpty {
          GroupBox("Suggestion · review before use") {
            Text(assistant.text).textSelection(.enabled).frame(
              maxWidth: .infinity, alignment: .leading)
          }
          Text(
            "Retrieved guides are shown above. Their presence doesn't guarantee every generated claim is supported."
          ).font(.caption).foregroundStyle(.secondary)
        }
        HStack {
          Button("Prepare ticket", systemImage: "doc.text") {
            assistant.generate(issue: issue, matches: matches, photo: photo, ticket: true)
          }
          .disabled(!assistant.available || assistant.busy || issue.isEmpty || importBusy)
          Button("Review ticket", systemImage: "checkmark.square") {
            draft = DeskCase(
              title: String(
                issue.split(separator: "\n").first.map(String.init)?.prefix(100) ?? "New case"),
              description: String(issue.prefix(4000)),
              resolution: String(assistant.text.prefix(8000)), sourceIDs: matches.map(\.id))
          }.buttonStyle(.borderedProminent).disabled(
            issue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !model.ready
              || assistant.busy)
        }
      }.padding(24).frame(maxWidth: 780)
        .frame(maxWidth: .infinity, alignment: .center)
    }.navigationTitle("New case")
  }
  private var guides: some View {
    List {
      Section {
        Text(
          "Local troubleshooting material. Sample guides are illustrative and editable through new local guides; they are not vendor instructions."
        ).foregroundStyle(.secondary)
      }
      ForEach(model.snapshot.guides) { guide in
        DisclosureGroup(guide.title) { Text(guide.body).textSelection(.enabled) }
      }
      Section {
        Button("Add guide", systemImage: "plus") { guideEditor = true }.disabled(!model.ready)
        Button("Load sample guides", systemImage: "tray.and.arrow.down") {
          Task {
            do { model.snapshot = try await model.store.addSampleGuides() } catch {
              model.error = error.localizedDescription
            }
          }
        }
      }
    }.navigationTitle("Knowledge guides")
  }
  private func caseDetail(_ item: DeskCase) -> some View {
    List {
      Section("Issue") { Text(item.description).textSelection(.enabled) }
      Section("Reviewed notes") {
        Text(item.resolution.isEmpty ? "No notes" : item.resolution).textSelection(.enabled)
      }
      Section("Status") {
        LabeledContent("State", value: item.status)
        LabeledContent("Priority", value: item.priority)
        LabeledContent(
          "Created", value: item.created.formatted(date: .abbreviated, time: .shortened))
      }
      Section("Reference guides") {
        ForEach(model.snapshot.guides.filter { item.sourceIDs.contains($0.id) }) { guide in
          DisclosureGroup(guide.title) { Text(guide.body) }
        }
      }
    }.navigationTitle(item.title).toolbar { Button("Edit ticket") { draft = item } }
  }
  private func importPhoto(_ url: URL) {
    importBusy = true
    photoToken = UUID()
    let current = photoToken
    Task {
      defer { if current == photoToken { importBusy = false } }
      do {
        let result = try await photos.copy(url)
        guard current == photoToken else {
          await photos.remove(result)
          return
        }
        if let photo { await photos.remove(photo) }
        photo = result
        assistant.cancel()
        assistant.text = ""
      } catch { if current == photoToken { model.error = error.localizedDescription } }
    }
  }
}
private struct TicketEditor: View {
  @Environment(\.dismiss) private var dismiss
  @State var item: DeskCase
  var model: DeskModel
  @State private var saving = false
  var body: some View {
    NavigationStack {
      Form {
        if let error = model.error { Section { Text(error).foregroundStyle(.red) } }
        Section("Review") {
          TextField("Title", text: $item.title).accessibilityIdentifier("ticket-title")
          TextField("Issue", text: $item.description, axis: .vertical).lineLimit(3...8)
          TextField("Notes and next steps", text: $item.resolution, axis: .vertical).lineLimit(
            5...15
          ).accessibilityIdentifier("ticket-notes")
        }
        Section {
          Picker("Priority", selection: $item.priority) {
            ForEach(["Low", "Normal", "High"], id: \.self) { Text($0) }
          }
          Picker("Status", selection: $item.status) {
            ForEach(["Open", "Resolved"], id: \.self) { Text($0) }
          }
          Text(
            "Saving records this reviewed ticket locally. Nothing is sent to a customer or external service."
          ).font(.caption).foregroundStyle(.secondary)
        }
      }.navigationTitle("Review ticket")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }.disabled(saving)
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Save ticket") {
              saving = true
              Task {
                if await model.save(item) { dismiss() }
                saving = false
              }
            }.disabled(saving || item.title.isEmpty)
          }
        }
    }.frame(minWidth: 320, minHeight: 420).interactiveDismissDisabled(saving)
  }
}
private struct GuideEditor: View {
  @Environment(\.dismiss) private var dismiss
  var model: DeskModel
  @State private var title = ""
  @State private var bodyText = ""
  @State private var saving = false
  var body: some View {
    NavigationStack {
      Form {
        if let error = model.error { Text(error).foregroundStyle(.red) }
        TextField("Title", text: $title)
        TextField("Guide text", text: $bodyText, axis: .vertical).lineLimit(8...20)
        Text("Maximum 200 title characters and 12,000 body characters.").font(.caption)
      }
      .navigationTitle("Add guide").toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }.disabled(saving)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save guide") {
            saving = true
            Task {
              defer { saving = false }
              do {
                model.snapshot = try await model.store.addGuide(title, body: bodyText)
                dismiss()
              } catch { model.error = error.localizedDescription }
            }
          }.disabled(saving || title.isEmpty || bodyText.isEmpty)
        }
      }
    }.frame(minWidth: 320, minHeight: 420).interactiveDismissDisabled(saving)
  }
}
