import Foundation
import Security

enum KeychainError: Error, Equatable {
  /// The Keychain could not be read or written
  case accessError(OSStatus)
  /// The stored item exists but could not be decoded as a UTF-8 string.
  case unexpectedData
}

protocol KeychainStoring {
  func read(key: String) throws -> String?
  func write(key: String, value: String) throws
}

struct KeychainStore: KeychainStoring {
  private let service = "expo.modules.fintechsecurity"

  func read(key: String) throws -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecReturnData as String: true,
    ]

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    switch status {
    case errSecSuccess:
      guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
        throw KeychainError.unexpectedData
      }
      return value
    case errSecItemNotFound:
      return nil
    default:
      throw KeychainError.accessError(status)
    }
  }

  func write(key: String, value: String) throws {
    // AfterFirstUnlockThisDeviceOnly: available from the first unlock onwards
    // (minimizes the locked-Keychain window) and never migrates to another
    // device via iCloud Keychain or device-to-device restore. Synchronizable
    // is not set, so it defaults to false.
    let attributes: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      kSecValueData as String: Data(value.utf8),
    ]

    let status = SecItemAdd(attributes as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw KeychainError.accessError(status)
    }
  }
}
