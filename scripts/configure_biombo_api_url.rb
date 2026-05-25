#!/usr/bin/env ruby
# Sets the BIOMBO_API_URL build setting per configuration so the Info.plist's
# `$(BIOMBO_API_URL)` substitution resolves correctly. Debug points at the
# local dev backend; Release is left empty so shipping without a real
# configured URL is caught at runtime by BiomboAPIService.
require "xcodeproj"

PROJECT_PATH = "apps/biombo/ios/Biombo.xcodeproj"
DEBUG_URL = "http://localhost:8787"
RELEASE_URL = ""

project = Xcodeproj::Project.open(PROJECT_PATH)
app = project.targets.find { |t| t.name == "Biombo" }
raise "Biombo target not found" if app.nil?

app.build_configurations.each do |config|
  value = config.name == "Release" ? RELEASE_URL : DEBUG_URL
  config.build_settings["BIOMBO_API_URL"] = value
  puts "#{config.name}: BIOMBO_API_URL = \"#{value}\""
end

project.save
