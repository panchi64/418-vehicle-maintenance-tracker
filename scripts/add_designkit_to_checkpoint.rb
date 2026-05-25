#!/usr/bin/env ruby
# Adds the local DesignKit package to checkpoint.xcodeproj and links it to
# the main app + Watch + Widget + WatchWidget targets.
require "xcodeproj"
require "pathname"

PROJECT_PATH = "apps/checkpoint/ios/checkpoint.xcodeproj"
PACKAGE_RELATIVE = "../../../packages/DesignKit"
PRODUCT_NAME = "DesignKit"
TARGET_NAMES = [
  "checkpoint",
  "CheckpointWidgetExtension",
  "CheckpointWatch Watch App",
  "CheckpointWatchWidgetExtension"
].freeze

project = Xcodeproj::Project.open(PROJECT_PATH)

ref = project.root_object.package_references.find do |r|
  r.respond_to?(:relative_path) && r.relative_path == PACKAGE_RELATIVE
end

unless ref
  ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
  ref.relative_path = PACKAGE_RELATIVE
  project.root_object.package_references << ref
  puts "Added package reference #{PACKAGE_RELATIVE}"
end

TARGET_NAMES.each do |name|
  target = project.targets.find { |t| t.name == name }
  unless target
    warn "Target not found: #{name}"
    next
  end

  already_linked = target.package_product_dependencies.any? { |d| d.product_name == PRODUCT_NAME }
  if already_linked
    puts "#{name}: already links #{PRODUCT_NAME}"
    next
  end

  dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep.product_name = PRODUCT_NAME
  dep.package = ref
  target.package_product_dependencies << dep

  frameworks_phase = target.frameworks_build_phase
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = dep
  frameworks_phase.files << build_file
  puts "Linked #{PRODUCT_NAME} to #{name}"
end

project.save
puts "Saved #{PROJECT_PATH}"
