import { NativeModule, requireNativeModule } from 'expo';

export type FintechSecurityModuleEvents = Record<never, never>;

export const IdentifierErrorCodes = {
  /** No identifier could be obtained from the device. */
  Unavailable: 'ERR_IDENTIFIER_UNAVAILABLE',
  /** The platform storage backing the identifier failed (iOS Keychain). */
  StorageAccess: 'ERR_IDENTIFIER_STORAGE_ACCESS',
} as const;

export type IdentifierErrorCode = (typeof IdentifierErrorCodes)[keyof typeof IdentifierErrorCodes];

declare class FintechSecurityModule extends NativeModule<FintechSecurityModuleEvents> {
  /**
   * Returns a unique device identifier.
   *
   * - iOS: UUID generated once and persisted in the Keychain
   *   (survives reinstalls, never migrates to another device).
   * - Android: ANDROID_ID (survives reinstalls, dies on factory reset).
   *
   * Rejects with an {@link IdentifierErrorCode} when no identifier
   * can be obtained.
   */
  getIdentifier(): Promise<string>;
}

export default requireNativeModule<FintechSecurityModule>('FintechSecurity');
