import { NativeModule, requireNativeModule } from 'expo';

declare class FintechSecurityModule extends NativeModule<{}> {
      /**
       * Returns a unique device identifier.
       * iOS: IDFV (does NOT survive reinstall if it's the vendor's only app; dies on factory reset).
       * Android: ANDROID_ID (survives reinstall, dies on factory reset).
       */
      getIdentifier(): Promise<string>;
      }

export default requireNativeModule<FintechSecurityModule>('FintechSecurity');
