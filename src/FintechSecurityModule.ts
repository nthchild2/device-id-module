import { NativeModule, requireNativeModule } from 'expo';

declare class FintechSecurityModule extends NativeModule<{}> {}

export default requireNativeModule<FintechSecurityModule>('FintechSecurity');
