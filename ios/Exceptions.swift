import ExpoModulesCore

internal final class IdentifierStorageAccessException: Exception {
  override var code: String {
    "ERR_IDENTIFIER_STORAGE_ACCESS"
  }

  override var reason: String {
    "The device identifier storage (Keychain) could not be accessed"
  }
}

internal final class IdentifierUnavailableException: Exception {
  override var code: String {
    "ERR_IDENTIFIER_UNAVAILABLE"
  }

  override var reason: String {
    "No device identifier is available on this device"
  }
}
