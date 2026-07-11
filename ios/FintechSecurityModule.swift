import ExpoModulesCore

public final class FintechSecurityModule: Module {
  public func definition() -> ModuleDefinition {
    Name("FintechSecurity")

    AsyncFunction("getIdentifier") { () throws -> String in
      do {
        return try DeviceIdentifierProvider().getIdentifier()
      } catch is KeychainError {
        throw IdentifierStorageAccessException()
      }
    }
  }
}
