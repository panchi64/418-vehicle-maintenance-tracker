#!/usr/bin/env ruby
# Creates apps/biombo/ios/Biombo.xcodeproj from scratch: the Biombo app target,
# the BiomboWidgets extension (widgets and Controls, embedded in the app), the
# BiomboTests unit-test target (Swift Testing) and the shared "Biombo" scheme.
# Sources live in file-system-synchronized folders (objectVersion 77), so
# adding a file on disk needs no project edit. BiomboShared/ (the App Group
# snapshot, the Controls' open intent and the palette) is in both the app and
# the extension.
#
# Settings mirror Checkpoint's (iOS 26, default MainActor isolation,
# approachable concurrency, string catalogs), with Swift 6 language mode and
# Spanish as the development region.
#
# Run from the repo root: ruby scripts/create_biombo_xcodeproj.rb
# Overwrites any existing project; sources are untouched.
require "xcodeproj"
require "fileutils"

PROJECT_DIR = "apps/biombo/ios"
PROJECT_PATH = "#{PROJECT_DIR}/Biombo.xcodeproj"
BUNDLE_ID = "com.418-studio.biombo"
WIDGETS_BUNDLE_ID = "#{BUNDLE_ID}.widgets"
DEPLOYMENT_TARGET = "26.0"
DEVELOPMENT_TEAM = "WU2PJ8AT65"
# Development-language (es) value; the English one is in Resources/InfoPlist.xcstrings.
LOCATION_USAGE = "Biombo usa tu ubicación para mostrarte lo que pasa cerca: luz, agua, carreteras y gasolina."
CAMERA_USAGE = "Biombo usa la cámara solo si quieres retratar el letrero de precios de una gasolinera."

FileUtils.rm_rf(PROJECT_PATH)
project = Xcodeproj::Project.new(PROJECT_PATH, false, 77)
root = project.root_object
root.compatibility_version = nil # Xcode 16+ projects rely on preferredProjectObjectVersion
root.minimized_project_reference_proxies = "1"
root.development_region = "es"
root.known_regions = %w[es en Base]
root.attributes["LastSwiftUpdateCheck"] = "2700"
root.attributes["LastUpgradeCheck"] = "2700"

# Project-level settings shared by every target.
project.build_configurations.each do |config|
  config.build_settings.merge!(
    "IPHONEOS_DEPLOYMENT_TARGET" => DEPLOYMENT_TARGET,
    "SWIFT_VERSION" => "6.0",
    "SWIFT_APPROACHABLE_CONCURRENCY" => "YES",
    "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY" => "YES",
    "LOCALIZATION_PREFERS_STRING_CATALOGS" => "YES",
    "ENABLE_USER_SCRIPT_SANDBOXING" => "YES",
    "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS" => "YES",
    # Palette names like `tint` and `fill` would collide with SwiftUI's own
    # ShapeStyle members as Color extensions; use `Color(.ink)` via ColorResource.
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS" => "NO",
    "DEVELOPMENT_TEAM" => DEVELOPMENT_TEAM,
    "CODE_SIGN_STYLE" => "Automatic"
  )
end

def synchronized_group(project, path)
  group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
  group.path = path
  group.source_tree = "<group>"
  project.main_group.children << group
  group
end

# App target.
app = project.new_target(:application, "Biombo", :ios, DEPLOYMENT_TARGET)
app.build_configurations.each do |config|
  config.build_settings.merge!(
    "PRODUCT_BUNDLE_IDENTIFIER" => BUNDLE_ID,
    "PRODUCT_NAME" => "$(TARGET_NAME)",
    "MARKETING_VERSION" => "0.1",
    "CURRENT_PROJECT_VERSION" => "1",
    "GENERATE_INFOPLIST_FILE" => "YES",
    # Keys with no INFOPLIST_KEY_ setting (LSApplicationQueriesSchemes); merged with the generated ones.
    "INFOPLIST_FILE" => "Biombo-Support/Info.plist",
    # The App Group the widgets and Controls read the app's snapshot from.
    "CODE_SIGN_ENTITLEMENTS" => "Biombo-Support/Biombo.entitlements",
    "INFOPLIST_KEY_CFBundleDisplayName" => "Biombo",
    "INFOPLIST_KEY_LSApplicationCategoryType" => "public.app-category.navigation",
    "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription" => LOCATION_USAGE,
    "INFOPLIST_KEY_NSCameraUsageDescription" => CAMERA_USAGE,
    "INFOPLIST_KEY_UIApplicationSceneManifest_Generation" => "YES",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents" => "YES",
    "INFOPLIST_KEY_UILaunchScreen_Generation" => "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone" => "UIInterfaceOrientationPortrait",
    "ASSETCATALOG_COMPILER_APPICON_NAME" => "AppIcon",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME" => "AccentColor",
    "SWIFT_DEFAULT_ACTOR_ISOLATION" => "MainActor",
    "SWIFT_EMIT_LOC_STRINGS" => "YES",
    "STRING_CATALOG_GENERATE_SYMBOLS" => "YES",
    "ENABLE_PREVIEWS" => "YES",
    "TARGETED_DEVICE_FAMILY" => "1",
    "SUPPORTED_PLATFORMS" => "iphoneos iphonesimulator",
    "SUPPORTS_MACCATALYST" => "NO",
    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD" => "NO",
    "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD" => "NO"
  )
end
app_group = synchronized_group(project, "Biombo")
(app.file_system_synchronized_groups ||= []) << app_group
shared_group = synchronized_group(project, "BiomboShared")
app.file_system_synchronized_groups << shared_group

# Placeholder .gitkeep files hold empty folders in git; keep them out of the bundle.
gitkeeps = Dir.glob("#{PROJECT_DIR}/Biombo/**/.gitkeep", File::FNM_DOTMATCH)
              .map { |path| path.delete_prefix("#{PROJECT_DIR}/Biombo/") }.sort
unless gitkeeps.empty?
  exceptions = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
  exceptions.target = app
  exceptions.membership_exceptions = gitkeeps
  (app_group.exceptions ||= []) << exceptions
end

# Widgets and Controls (WidgetKit extension), embedded in the app. It reads
# the snapshot the app writes to the App Group; it never loads places itself.
widgets = project.new_target(:app_extension, "BiomboWidgets", :ios, DEPLOYMENT_TARGET)
widgets.build_configurations.each do |config|
  config.build_settings.merge!(
    "PRODUCT_BUNDLE_IDENTIFIER" => WIDGETS_BUNDLE_ID,
    "PRODUCT_NAME" => "$(TARGET_NAME)",
    "MARKETING_VERSION" => "0.1",
    "CURRENT_PROJECT_VERSION" => "1",
    "GENERATE_INFOPLIST_FILE" => "YES",
    # NSExtension has no INFOPLIST_KEY_ setting.
    "INFOPLIST_FILE" => "BiomboWidgets-Support/Info.plist",
    "INFOPLIST_KEY_CFBundleDisplayName" => "Biombo",
    "CODE_SIGN_ENTITLEMENTS" => "BiomboWidgets-Support/BiomboWidgets.entitlements",
    # No default MainActor isolation here, as in Checkpoint's widget:
    # WidgetKit's providers are nonisolated. Shared files say `nonisolated`
    # explicitly so they mean the same thing in both targets.
    "SWIFT_EMIT_LOC_STRINGS" => "YES",
    "STRING_CATALOG_GENERATE_SYMBOLS" => "YES",
    "APPLICATION_EXTENSION_API_ONLY" => "YES",
    "SKIP_INSTALL" => "YES",
    "LD_RUNPATH_SEARCH_PATHS" => "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks",
    "TARGETED_DEVICE_FAMILY" => "1",
    "SUPPORTED_PLATFORMS" => "iphoneos iphonesimulator",
    "SUPPORTS_MACCATALYST" => "NO"
  )
end
(widgets.file_system_synchronized_groups ||= []) << synchronized_group(project, "BiomboWidgets")
widgets.file_system_synchronized_groups << shared_group
app.add_dependency(widgets)
embed = app.new_copy_files_build_phase("Embed Foundation Extensions")
embed.symbol_dst_subfolder_spec = :plug_ins
embedded = embed.add_file_reference(widgets.product_reference)
embedded.settings = { "ATTRIBUTES" => ["RemoveHeadersOnCopy"] }

# Unit tests (Swift Testing), hosted in the app.
tests = project.new_target(:unit_test_bundle, "BiomboTests", :ios, DEPLOYMENT_TARGET)
tests.build_configurations.each do |config|
  config.build_settings.merge!(
    "PRODUCT_BUNDLE_IDENTIFIER" => "#{BUNDLE_ID}.tests",
    "PRODUCT_NAME" => "$(TARGET_NAME)",
    "GENERATE_INFOPLIST_FILE" => "YES",
    "TEST_HOST" => "$(BUILT_PRODUCTS_DIR)/Biombo.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Biombo",
    "BUNDLE_LOADER" => "$(TEST_HOST)",
    "SWIFT_EMIT_LOC_STRINGS" => "NO",
    "TARGETED_DEVICE_FAMILY" => "1"
  )
end
tests.add_dependency(app)
(tests.file_system_synchronized_groups ||= []) << synchronized_group(project, "BiomboTests")

project.save

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app, tests, launch_target: true)
scheme.save_as(PROJECT_PATH, "Biombo", true)

puts "Created #{PROJECT_PATH} (targets: Biombo, BiomboWidgets, BiomboTests; shared scheme: Biombo)"
