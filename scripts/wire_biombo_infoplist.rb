#!/usr/bin/env ruby
# Switches the Biombo main target from GENERATE_INFOPLIST_FILE to an explicit
# Biombo/Info.plist, so the manual URL types / usage descriptions take effect.
# Drops the now-redundant INFOPLIST_KEY_* build settings.
require "xcodeproj"

PROJECT_PATH = "apps/biombo/ios/Biombo.xcodeproj"
PLIST_KEYS_TO_DROP = %w[
  INFOPLIST_KEY_CFBundleDisplayName
  INFOPLIST_KEY_UILaunchScreen_Generation
  INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone
  INFOPLIST_KEY_UIApplicationSceneManifest_Generation
  INFOPLIST_KEY_UILocationWhenInUseUsageDescription
  INFOPLIST_KEY_NSCameraUsageDescription
  INFOPLIST_KEY_NSPhotoLibraryUsageDescription
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)
app = project.targets.find { |t| t.name == "Biombo" }
raise "Biombo target not found" if app.nil?

app.build_configurations.each do |config|
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "NO"
  config.build_settings["INFOPLIST_FILE"] = "Biombo-Support/Info.plist"
  PLIST_KEYS_TO_DROP.each { |k| config.build_settings.delete(k) }
end

project.save
puts "Wired Biombo/Info.plist and cleared INFOPLIST_KEY_* stubs"
