# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

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
   pod 'SwiftEntryKit'
   pod 'SwiftyStoreKit'
   pod 'IQKeyboardManagerSwift'
   pod 'PhoneNumberKit'
   pod 'SwiftConfettiView'
   pod 'SwiftySound'
   pod 'SwiftyMenu', '~> 1.0.1'
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

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
         end
    end
  end
end
