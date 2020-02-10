source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

def shared_pods
  pod 'RxSwift',    '~> 5.0'
  pod 'RxCocoa',    '~> 5.0'
  pod 'RxRelay',    '~> 5.0'
end

target 'RxEntity' do
    shared_pods
end

target 'RxEntityTests' do
    shared_pods
    
    pod 'RxBlocking', '~> 5.0'
    pod 'RxTest', '~> 5.0'
end
