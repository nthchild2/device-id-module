package expo.modules.fintechsecurity

import expo.modules.kotlin.exception.CodedException

class IdentifierUnavailableException :
  CodedException(
    "ERR_IDENTIFIER_UNAVAILABLE",
    "No device identifier is available on this device",
    null,
  )
