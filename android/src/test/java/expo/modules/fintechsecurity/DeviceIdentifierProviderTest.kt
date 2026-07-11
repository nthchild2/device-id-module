package expo.modules.fintechsecurity

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class DeviceIdentifierProviderTest {

  @Test
  fun `returns the android id when present`() {
    val provider = DeviceIdentifierProvider(readAndroidId = { "9f2f00b0c94e7e65" })

    assertEquals("9f2f00b0c94e7e65", provider.getIdentifier())
  }

  @Test
  fun `throws when the android id is null`() {
    val provider = DeviceIdentifierProvider(readAndroidId = { null })

    assertThrows(IdentifierUnavailableException::class.java) {
      provider.getIdentifier()
    }
  }

  @Test
  fun `throws when the android id is blank`() {
    val provider = DeviceIdentifierProvider(readAndroidId = { "" })

    assertThrows(IdentifierUnavailableException::class.java) {
      provider.getIdentifier()
    }
  }
}
