Pod::Spec.new do |s|

  s.name         = "IAPHelper"
  s.version      = "1.1"
  s.summary      = "In App Purchases Helper. Base on IAPHelper"
  s.homepage     = 'http://superdanny.link/'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Danny' => 'boy736809040@gmail.com' }
  s.requires_arc = true
  s.platform     = :ios
  s.platform     = :ios, '7.0'
  s.source       = { :git => "https://github.com/SuperDannyBoy/IAPHelper.git", :tag => "1.0" }
  s.source_files = "IAPHelper/*.{h,m}"
  s.public_header_files = "IAPHelper/*.h"
  s.framework  = 'StoreKit'
  s.dependency 'JNKeychain'
end
