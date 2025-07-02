Pod::Spec.new do |s|
  s.name             = 'device_attestation'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter plugin for device attestation.'
  s.description      = <<-DESC
                       A Flutter plugin that provides device attestation features for iOS.
                       DESC
  s.homepage         = 'https://github.com/krungsri/device_attestation'
  s.license          = { :file => 'LICENSE' }
  s.author           = { 'Krungsri' => 'support@krungsri.com' }
  s.source           = { :git => 'https://github.com/krungsri/device_attestation.git', :tag => s.version.to_s }
  
  s.platform        = :ios, '10.0'
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
end