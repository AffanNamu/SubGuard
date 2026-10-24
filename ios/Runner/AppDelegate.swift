import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let channelName = "com.nassaracoretech.unimarkly/incoming"
  private static let maxBytes: Int64 = 200 * 1024 * 1024

  private var channel: FlutterMethodChannel?
  private var dartReady = false
  private var held: [[String: Any]] = []
  private let worker = DispatchQueue(label: "com.nassaracoretech.unimarkly.incoming", qos: .userInitiated)

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let ch = FlutterMethodChannel(name: AppDelegate.channelName, binaryMessenger: controller.binaryMessenger)
      ch.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return result(FlutterMethodNotImplemented) }
        if call.method == "ready" {
          self.dartReady = true
          let pending = self.held
          self.held = []
          result(pending)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      channel = ch
    }
    worker.async { AppDelegate.pruneOldCopies(olderThan: 24 * 60 * 60) }

    // A document that started the app is delivered to application(_:open:options:)
    // once the app has launched.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// "Open in UniMarkLy" from Files, Mail, Messages and other apps, and the
  /// share sheet's copy-to action. The URL may be security-scoped and may live
  /// in another app's or a cloud provider's folder, so it is only read, and
  /// copied to a private temporary folder straight away.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    guard url.isFileURL else {
      return super.application(app, open: url, options: options)
    }
    receive([url])
    return true
  }

  // MARK: - Receiving

  private func receive(_ urls: [URL]) {
    // Access to a security-scoped URL is requested here, on the main thread,
    // while the system still has it open for us, and released after the copy.
    let scoped = urls.map { ($0, $0.startAccessingSecurityScopedResource()) }
    emit(["type": "started", "count": urls.count])

    worker.async {
      var files: [[String: Any]] = []
      var failures: [[String: Any]] = []
      for (url, didStart) in scoped {
        switch AppDelegate.copy(url) {
        case .success(let file): files.append(file)
        case .failure(let failure): failures.append(failure.asMap)
        }
        if didStart { url.stopAccessingSecurityScopedResource() }
      }
      DispatchQueue.main.async {
        self.emit(["type": "files", "files": files, "failures": failures])
      }
    }
  }

  /// Events are held until Dart says it is ready, so a document that started
  /// the app is not lost.
  private func emit(_ event: [String: Any]) {
    if let channel = channel, dartReady {
      channel.invokeMethod("event", arguments: event)
    } else {
      held.append(event)
    }
  }

  // MARK: - Copying

  struct CopyFailure: Error {
    let name: String
    let message: String
    var asMap: [String: Any] { ["name": name, "message": message] }
  }

  static func copy(_ url: URL) -> Result<[String: Any], CopyFailure> {
    let name = safeName(url.lastPathComponent)
    let fm = FileManager.default

    if let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize, Int64(size) > maxBytes {
      return .failure(CopyFailure(
        name: name,
        message: "This file is too large to open here. Share it with another app, or open it on a computer."))
    }

    let folder = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("incoming", isDirectory: true)
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let target = folder.appendingPathComponent(name)

    do {
      try fm.createDirectory(at: folder, withIntermediateDirectories: true)
    } catch {
      return .failure(CopyFailure(
        name: name, message: "There is no room to keep a copy of this file on the phone."))
    }

    // File coordination makes a file in iCloud Drive or another provider
    // download first, and keeps it from changing while it is read.
    var coordinationError: NSError?
    var copyError: Error?
    NSFileCoordinator(filePresenter: nil).coordinate(
      readingItemAt: url, options: [.withoutChanges], error: &coordinationError
    ) { readable in
      do {
        try fm.copyItem(at: readable, to: target)
      } catch {
        copyError = error
      }
    }

    if coordinationError != nil || copyError != nil {
      try? fm.removeItem(at: folder)
      let error = (copyError ?? coordinationError) as NSError?
      let noSpace = error?.code == NSFileWriteOutOfSpaceError
      return .failure(CopyFailure(
        name: name,
        message: noSpace
          ? "The phone is out of storage space, so the file could not be opened. Free some space and try again."
          : "UniMarkLy could not read this file. It may be in a location that is not available. Open it again, or share it from the app that has it."))
    }

    let size = ((try? fm.attributesOfItem(atPath: target.path))?[.size] as? NSNumber)?.int64Value ?? 0
    if size > maxBytes {
      try? fm.removeItem(at: folder)
      return .failure(CopyFailure(
        name: name,
        message: "This file is too large to open here. Share it with another app, or open it on a computer."))
    }

    // A file the system copied into this app's own Inbox is ours to tidy up.
    if url.path.contains("/Documents/Inbox/") { try? fm.removeItem(at: url) }

    var file: [String: Any] = [
      "id": UUID().uuidString,
      "path": target.path,
      "name": name,
      "size": size,
    ]
    if let mime = UTType(filenameExtension: target.pathExtension)?.preferredMIMEType {
      file["mime"] = mime
    }
    return .success(file)
  }

  /// A file name that is safe to create: no folders, no control characters, no
  /// leading dots, not too long, never empty. The extension is kept.
  static func safeName(_ raw: String) -> String {
    var n = raw
    if let slash = n.lastIndex(where: { $0 == "/" || $0 == "\\" }) { n = String(n[n.index(after: slash)...]) }
    let bad = CharacterSet.controlCharacters.union(CharacterSet(charactersIn: ":*?\"<>|"))
    n = n.unicodeScalars.map { bad.contains($0) ? "_" : String($0) }.joined()
    n = n.trimmingCharacters(in: .whitespaces)
    while n.hasPrefix(".") { n.removeFirst() }
    n = n.trimmingCharacters(in: .whitespaces)
    if n.count > 120 {
      let ext = (n as NSString).pathExtension
      if !ext.isEmpty && ext.count <= 10 {
        n = String(n.prefix(120 - ext.count - 1)) + "." + ext
      } else {
        n = String(n.prefix(120))
      }
    }
    return n.isEmpty ? "document" : n
  }

  /// Removes copies left from earlier runs.
  static func pruneOldCopies(olderThan seconds: TimeInterval) {
    let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("incoming", isDirectory: true)
    let fm = FileManager.default
    guard let items = try? fm.contentsOfDirectory(
      at: root, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
    for item in items {
      let modified = (try? item.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
      if let modified = modified, Date().timeIntervalSince(modified) > seconds {
        try? fm.removeItem(at: item)
      }
    }
  }
}
