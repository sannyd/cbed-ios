# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

def rx_pods
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxGesture'
  pod 'RxDataSources'
  pod 'RxNuke'
  pod 'RxSwiftExt'
  pod 'RxAlamofire'
end

def utility_pods
   pod 'SnapKit'
   pod 'SwiftLint'
   pod 'KeychainSwift'
   pod 'IQKeyboardManagerSwift'
end

def sso_pods
  pod 'Firebase/Performance'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'GoogleSignIn'
  pod 'FBSDKCoreKit'
  pod 'FBSDKLoginKit'
end

target 'CBED' do
  use_frameworks!

  rx_pods
  utility_pods
  sso_pods

end
