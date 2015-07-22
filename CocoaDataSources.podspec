Pod::Spec.new do |s|

  s.name         = "CocoaDataSources"
  s.version      = "1.0.0"
  s.summary      = "A cluster of data source classes for building Cocoa apps."

  s.description  = <<-DESC
                   A cluster of data source classes for building Cocoa apps. This library includes modified versions of classes from Apple's 2014 WWDC code sample "Advanced User Interfaces Using Collection View".
                   DESC

  s.homepage     = "https://github.com/Tripstr/CocoaDataSources"
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/Tripstr/CocoaDataSources.git", :branch => "master" }
  s.source_files  = ["CocoaDataSources"]
  s.framework     = 'SystemConfiguration'
  s.exclude_files = "Classes/Exclude"
  s.requires_arc = true

end