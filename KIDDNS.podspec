#
# Be sure to run `pod lib lint KIDDNS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KIDDNS'
  s.version          = '1.0.0'
  s.summary          = 'Using HTTPDNS over your network'
  s.static_framework = true

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Using HTTPDNS over your network request based on NSURLProtocol, dealt with both normal http and https SNI scenario.
                       DESC

  s.homepage         = 'https://github.com/VIPKID-OpenSource/KIDDNS.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yiyangest' => 'y31210@gmail.com' }
  s.source           = { :git => 'https://github.com/VIPKID-OpenSource/KIDDNS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'KIDDNS/Classes/**/*'
  s.public_header_files = 'KIDDNS/Classes/DNS/DNSCenter.h','KIDDNS/Classes/DNS/KIDDNSLogger.h'

  # s.public_header_files = 'KIDDNS/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'AlicloudHTTPDNS'
end
