import Foundation

final class DeviceIdentifierProvider {
  static let identifierKey = "device-identifier"

  private let store: KeychainStoring
  private let makeIdentifier: () -> String

  init(
    store: KeychainStoring = KeychainStore(),
    makeIdentifier: @escaping () -> String = { UUID().uuidString }
  ) {
    self.store = store
    self.makeIdentifier = makeIdentifier
  }

  func getIdentifier() throws -> String {
    if let existing = try store.read(key: Self.identifierKey) {
      return existing
    }

    let identifier = makeIdentifier()
    try store.write(key: Self.identifierKey, value: identifier)
    return identifier
  }
}
