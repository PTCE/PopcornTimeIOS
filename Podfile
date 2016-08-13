platform :ios, '9.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/PTCE-TEAM/Specs'
source 'https://github.com/PTCE-TEAM/CocoaSpecs'

target "Popcorn Time" do
    pod 'Alamofire', git: 'https://github.com/Alamofire/Alamofire.git', branch: 'swift2.3'
    pod 'AlamofireImage', git: 'https://github.com/Alamofire/AlamofireImage.git', branch: 'swift2.3'
    pod 'AlamofireNetworkActivityIndicator', git: 'https://github.com/Alamofire/AlamofireNetworkActivityIndicator.git', branch: 'swift2.3'
    pod 'KMPlaceholderTextView'
    pod 'SwiftyJSON'
    pod 'FloatRatingView', git: 'https://github.com/strekfus/FloatRatingView.git'
    pod 'AlamofireXMLRPC', git: 'https://github.com/PTCE-TEAM/AlamofireXMLRPC.git'
    pod 'Reachability'
    pod 'XCDYouTubeKit'
    pod 'JGProgressHUD'
    pod 'google-cast-sdk'
    pod 'GZIP'
    pod 'OBSlider'
    pod 'ColorArt'
    pod '1PasswordExtension'
    pod 'PopcornTorrent/iOS'
    pod 'MobileVLCKit-prod'
    pod 'SwiftyTimer'
    pod 'SRT2VTT'
end

post_install do |installer|
    #    puts 'Copying Acknowledgements into Settings bundle'.yellow
    #FileUtils.cp_r('Pods/Target Support Files/Pods-LocalSearch3/Pods-LocalSearch3-acknowledgements.plist', 'Settings.bundle/Acknowledgements.plist', :remove_destination => true)
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
            config.build_settings['SWIFT_VERSION'] = '2.3'
            config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
            config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'NO_SIGNING/'
            config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = ''
            config.build_settings['CODE_SIGN_IDENTITY[sdk=watchos*]'] = ''
        end
    end
end
