package expo.modules.fintechsecurity

import expo.modules.kotlin.exception.Exceptions
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class FintechSecurityModule : Module() {

  private val context
    get() = appContext.reactContext ?: throw Exceptions.ReactContextLost()

  override fun definition() = ModuleDefinition {
    Name("FintechSecurity")

    AsyncFunction("getIdentifier") {
      DeviceIdentifierProvider(context).getIdentifier()
    }
  }
}
