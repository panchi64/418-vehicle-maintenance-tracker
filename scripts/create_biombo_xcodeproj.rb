#!/usr/bin/env ruby
# Creates apps/biombo/ios/Biombo.xcodeproj from scratch with the main app
# target + test target, wired to the DesignKit and Localization local
# packages. Idempotent: if the project already exists, overwrites it.
require "xcodeproj"
require "fileutils"

PROJECT_DIR = "apps/biombo/ios"
PROJECT_PATH = "#{PROJECT_DIR}/Biombo.xcodeproj"
APP_SOURCE_DIR = "#{PROJECT_DIR}/Biombo"
TEST_SOURCE_DIR = "#{PROJECT_DIR}/BiomboTests"
BUNDLE_ID = "com.418-studio.biombo"
DEPLOYMENT_TARGET = "17.0"
DEVELOPMENT_TEAM = ""

FileUtils.rm_rf(PROJECT_PATH)
project = Xcodeproj::Project.new(PROJECT_PATH)

# Register `es` (EN is default).
project.root_object.known_regions = ["en", "Base", "es"]

# Package references (relative to PROJECT_DIR).
package_refs = %w[../../../packages/DesignKit ../../../packages/Localization].map do |rel|
  ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  ref.relative_path = rel
  project.root_object.package_references << ref
  ref
end

design_kit_ref, localization_ref = package_refs

# App target.
app_target = project.new_target(:application, "Biombo", :ios, DEPLOYMENT_TARGET)
app_target.build_configurations.each do |config|
  config.build_settings.merge!(
    "PRODUCT_BUNDLE_IDENTIFIER" => BUNDLE_ID,
    "PRODUCT_NAME" => "Biombo",
    "INFOPLIST_KEY_CFBundleDisplayName" => "Biombo",
    "INFOPLIST_KEY_UILaunchScreen_Generation" => "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone" => "UIInterfaceOrientationPortrait",
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation" => "YES",
    "INFOPLIST_KEY_UILocationWhenInUseUsageDescription" => "Biombo uses your location to show nearby gas station prices.",
    "INFOPLIST_KEY_NSCameraUsageDescription" => "Photograph a gas station price sign so the community can see the current price.",
    "INFOPLIST_KEY_NSPhotoLibraryUsageDescription" => "Select a photo of a gas station price sign to submit.",
    "GENERATE_INFOPLIST_FILE" => "YES",
    "SWIFT_VERSION" => "5.0",
    "IPHONEOS_DEPLOYMENT_TARGET" => DEPLOYMENT_TARGET,
    "TARGETED_DEVICE_FAMILY" => "1",
    "SUPPORTS_MACCATALYST" => "NO",
    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD" => "NO",
    "ENABLE_PREVIEWS" => "YES",
    "CODE_SIGN_STYLE" => "Automatic",
    "DEVELOPMENT_TEAM" => DEVELOPMENT_TEAM,
    "ASSETCATALOG_COMPILER_APPICON_NAME" => "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME" => "AccentColor",
    "DEVELOPMENT_ASSET_PATHS" => "\"Biombo/Preview Content\""
  )
end

# Synchronized folder for app sources (auto-picks up files on disk).
app_sync_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
app_sync_group.path = "Biombo"
app_sync_group.source_tree = "<group>"
project.root_object.main_group.children << app_sync_group
app_target.file_system_synchronized_groups ||= []
app_target.file_system_synchronized_groups << app_sync_group

# Link package products to the app target.
%w[DesignKit Localization].zip([design_kit_ref, localization_ref]).each do |product_name, ref|
  dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep.product_name = product_name
  dep.package = ref
  app_target.package_product_dependencies << dep
  bf = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  bf.product_ref = dep
  app_target.frameworks_build_phase.files << bf
end

# Test target.
test_target = project.new_target(:unit_test_bundle, "BiomboTests", :ios, DEPLOYMENT_TARGET)
test_target.build_configurations.each do |config|
  config.build_settings.merge!(
    "PRODUCT_BUNDLE_IDENTIFIER" => "#{BUNDLE_ID}.tests",
    "PRODUCT_NAME" => "BiomboTests",
    "GENERATE_INFOPLIST_FILE" => "YES",
    "SWIFT_VERSION" => "5.0",
    "IPHONEOS_DEPLOYMENT_TARGET" => DEPLOYMENT_TARGET,
    "TEST_HOST" => "$(BUILT_PRODUCTS_DIR)/Biombo.app/Biombo",
    "BUNDLE_LOADER" => "$(TEST_HOST)",
    "CODE_SIGN_STYLE" => "Automatic",
    "DEVELOPMENT_TEAM" => DEVELOPMENT_TEAM
  )
end
test_target.add_dependency(app_target)

test_sync_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
test_sync_group.path = "BiomboTests"
test_sync_group.source_tree = "<group>"
project.root_object.main_group.children << test_sync_group
test_target.file_system_synchronized_groups ||= []
test_target.file_system_synchronized_groups << test_sync_group

project.save
puts "Created #{PROJECT_PATH}"
puts "  main target: Biombo (#{BUNDLE_ID})"
puts "  test target: BiomboTests"
puts "  package deps: DesignKit, Localization"
