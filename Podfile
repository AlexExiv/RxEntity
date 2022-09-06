source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

def shared_pods
  pod 'RxSwift',    '~> 6.5.0'
  pod 'RxCocoa',    '~> 6.5.0'
  pod 'RxRelay',    '~> 6.5.0'
end

target 'RxEntity' do
    shared_pods
end

target 'RxEntityTests' do
    shared_pods
    
    pod 'RxBlocking', '~> 6.5.0'
    pod 'RxTest', '~> 6.5.0'
end
