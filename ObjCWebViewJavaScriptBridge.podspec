Pod::Spec.new do |spec|
    spec.name     = 'ObjCWebViewJavaScriptBridge'
    spec.version  = '1.0.0'
    spec.license  = 'MIT'
    spec.summary  = 'Cross-iframe WebView JavaScript Bridge'
    spec.homepage = 'https://github.com/ouyanghuacom/ObjCWebViewJavaScriptBridge'
    spec.author   = { 'ouyanghuacom' => 'ouyanghua.com@gmail.com' }
    spec.source   = { :git => 'https://github.com/ouyanghuacom/ObjCWebViewJavaScriptBridge.git',:tag => "#{spec.version}" }
    spec.description = 'Cross-iframe WebView JavaScript Bridge.'
    spec.requires_arc = true
    spec.source_files = 'ObjCWebViewJavaScriptBridge/*.{h,m}'
    spec.resource = 'ObjCWebViewJavaScriptBridge/Resources/Proxy.js'
    spec.ios.frameworks = 'UIKit','WebKit'
    spec.osx.frameworks = 'WebKit'
    spec.ios.deployment_target = '8.0'
    spec.osx.deployment_target = '10.10'
end
