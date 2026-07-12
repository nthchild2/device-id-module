Pod::Spec.new do |s|
  s.name           = 'FintechSecurity'
  s.version        = '0.1.0'
  s.summary        = 'Expo native module that returns a unique device identifier'
  s.description    = 'Returns a UUID generated once and persisted in the Keychain (survives reinstalls, never migrates to another device). See the repository README for the design rationale.'
  s.author         = 'nthchild1'
  s.homepage       = 'https://github.com/nthchild2/device-id-module#readme'
  s.platforms      = {
    :ios => '16.4',
    :tvos => '16.4'
  }
  s.source         = { git: '' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"
end
