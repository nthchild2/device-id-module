import { registerWebModule, NativeModule } from 'expo';

// FintechSecurityModule is not available on the web platform.
class FintechSecurityModule extends NativeModule<{}> {}

export default registerWebModule(FintechSecurityModule, 'FintechSecurityModule');
