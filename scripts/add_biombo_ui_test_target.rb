#!/usr/bin/env ruby
# Adds a BiomboUITests target to apps/biombo/ios/Biombo.xcodeproj linked to
# the main Biombo app target. Idempotent.
require "xcodeproj"

PROJECT_PATH = "apps/biombo/ios/Biombo.xcodeproj"
TARGET_NAME = "BiomboUITests"
DIR = "BiomboUITests"
BUNDLE_ID = "com.418-studio.biombo.uitests"
DEPLOYMENT_TARGET = "17.0"

project = Xcodeproj::Project.open(PROJECT_PATH)

if project.targets.any? { |t| t.name == TARGET_NAME }
  puts "#{TARGET_NAME} already exists"
  exit 0
end

ui_target = project.new_target(:ui_test_bundle, TARGET_NAME, :ios, DEPLOYMENT_TARGET)
ui_target.build_configurations.each do |config|
  config.build_settings.merge!(
    "PRODUCT_BUNDLE_IDENTIFIER" => BUNDLE_ID,
    "PRODUCT_NAME" => TARGET_NAME,
    "GENERATE_INFOPLIST_FILE" => "YES",
    "SWIFT_VERSION" => "5.0",
    "IPHONEOS_DEPLOYMENT_TARGET" => DEPLOYMENT_TARGET,
    "TEST_TARGET_NAME" => "Biombo",
    "CODE_SIGN_STYLE" => "Automatic",
    "DEVELOPMENT_TEAM" => ""
  )
end

app_target = project.targets.find { |t| t.name == "Biombo" }
ui_target.add_dependency(app_target) if app_target

sync_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
sync_group.path = DIR
sync_group.source_tree = "<group>"
project.root_object.main_group.children << sync_group
ui_target.file_system_synchronized_groups ||= []
ui_target.file_system_synchronized_groups << sync_group

project.save
puts "Added #{TARGET_NAME} to #{PROJECT_PATH}"
