platform :osx, '26.0'

project 'Yippy', {
  'Debug' => :debug,
  'Release' => :release,
  'Beta Debug' => :debug,
  'Beta Release' => :release,
  'XCTest' => :debug
}

target 'Yippy' do
    use_frameworks!

    pod 'Default'
    pod 'RxSwift', '~> 6'
    pod 'RxCocoa', '~> 6'

    target 'YippyTests' do
        inherit! :search_paths
        pod 'RxBlocking', '~> 6'
        pod 'RxTest', '~> 6'
    end

    target 'YippyUITests' do
        inherit! :search_paths
        pod 'RxBlocking', '~> 6'
        pod 'RxTest', '~> 6'
    end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '26.0'
        end
    end
end
