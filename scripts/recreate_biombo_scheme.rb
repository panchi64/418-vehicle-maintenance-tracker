#!/usr/bin/env ruby
# Rebuilds the shared Biombo scheme so it includes the unit and UI test targets.
# By default refuses to overwrite an existing scheme (so hand edits in Xcode
# aren't silently destroyed). Pass --force to overwrite.
require "xcodeproj"

PROJECT_PATH = "apps/biombo/ios/Biombo.xcodeproj"
SCHEME_NAME = "Biombo"
force = ARGV.include?("--force")

scheme_path = File.join(PROJECT_PATH, "xcshareddata", "xcschemes", "#{SCHEME_NAME}.xcscheme")
if File.exist?(scheme_path) && !force
  puts "#{scheme_path} already exists. Re-run with --force to overwrite."
  exit 0
end

project = Xcodeproj::Project.open(PROJECT_PATH)
app = project.targets.find { |t| t.name == "Biombo" }
unit_tests = project.targets.find { |t| t.name == "BiomboTests" }
ui_tests = project.targets.find { |t| t.name == "BiomboUITests" }

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app, nil)
scheme.add_test_target(unit_tests) if unit_tests
scheme.add_test_target(ui_tests) if ui_tests
scheme.save_as(PROJECT_PATH, SCHEME_NAME, true)
puts "Wrote #{scheme_path}"
