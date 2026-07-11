package expo.modules.fintechsecurity

import android.content.Context
import android.provider.Settings

class DeviceIdentifierProvider(
  private val readAndroidId: () -> String?,
) {
  constructor(context: Context) : this({
    Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
  })

  fun getIdentifier(): String {
    val androidId = readAndroidId()
    if (androidId.isNullOrBlank()) {
      throw IdentifierUnavailableException()
    }
    return androidId
  }
}
