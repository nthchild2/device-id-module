package expo.modules.fintechsecurity

import android.content.Context
import android.provider.Settings

class DeviceIdentifierProvider(private val context: Context) {
  fun getIdentifier(): String {
    val androidId = Settings.Secure.getString(
      context.contentResolver,
      Settings.Secure.ANDROID_ID,
    )
    if (androidId.isNullOrBlank()) {
      throw IdentifierUnavailableException()
    }
    return androidId
  }
}
