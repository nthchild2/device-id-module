// Reexport the native module. On web, it will be resolved to FintechSecurityModule.web.ts
// and on native platforms to FintechSecurityModule.ts
export { default } from './FintechSecurityModule';
export * from './FintechSecurity.types';
