import Security
import XCTest

@testable import FintechSecurityCore

final class FakeKeychainStore: KeychainStoring {
  var storedValue: String?
  var readError: Error?
  var writeError: Error?
  private(set) var writtenValues: [String] = []

  func read(key: String) throws -> String? {
    if let readError {
      throw readError
    }
    return storedValue
  }

  func write(key: String, value: String) throws {
    if let writeError {
      throw writeError
    }
    writtenValues.append(value)
    storedValue = value
  }
}

final class DeviceIdentifierProviderTests: XCTestCase {

  func testReturnsStoredIdentifierWithoutGeneratingANewOne() throws {
    let store = FakeKeychainStore()
    store.storedValue = "stored-uuid"
    var generatorCalls = 0
    let provider = DeviceIdentifierProvider(store: store) {
      generatorCalls += 1
      return "new-uuid"
    }

    XCTAssertEqual(try provider.getIdentifier(), "stored-uuid")
    XCTAssertEqual(generatorCalls, 0)
    XCTAssertTrue(store.writtenValues.isEmpty)
  }

  func testGeneratesPersistsAndReturnsWhenNoIdentifierIsStored() throws {
    let store = FakeKeychainStore()
    let provider = DeviceIdentifierProvider(store: store) { "new-uuid" }

    XCTAssertEqual(try provider.getIdentifier(), "new-uuid")
    XCTAssertEqual(store.writtenValues, ["new-uuid"])
  }

  /// The critical case: a Keychain *access* error (e.g. locked before first
  /// unlock) must not be treated as "no identifier stored". Generating and
  /// persisting a new UUID here would overwrite the original once the
  /// Keychain heals, permanently changing the device's identity.
  func testAccessErrorOnReadPropagatesAndGeneratesNothing() {
    let store = FakeKeychainStore()
    store.readError = KeychainError.accessError(errSecInteractionNotAllowed)
    var generatorCalls = 0
    let provider = DeviceIdentifierProvider(store: store) {
      generatorCalls += 1
      return "new-uuid"
    }

    XCTAssertThrowsError(try provider.getIdentifier()) { error in
      XCTAssertEqual(error as? KeychainError, .accessError(errSecInteractionNotAllowed))
    }
    XCTAssertEqual(generatorCalls, 0)
    XCTAssertTrue(store.writtenValues.isEmpty)
  }

  func testWriteFailurePropagates() {
    let store = FakeKeychainStore()
    store.writeError = KeychainError.accessError(errSecNotAvailable)
    let provider = DeviceIdentifierProvider(store: store) { "new-uuid" }

    XCTAssertThrowsError(try provider.getIdentifier()) { error in
      XCTAssertEqual(error as? KeychainError, .accessError(errSecNotAvailable))
    }
  }

  func testUnexpectedDataErrorPropagates() {
    let store = FakeKeychainStore()
    store.readError = KeychainError.unexpectedData
    let provider = DeviceIdentifierProvider(store: store) { "new-uuid" }

    XCTAssertThrowsError(try provider.getIdentifier()) { error in
      XCTAssertEqual(error as? KeychainError, .unexpectedData)
    }
    XCTAssertTrue(store.writtenValues.isEmpty)
  }
}
