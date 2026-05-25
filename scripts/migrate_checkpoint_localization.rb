#!/usr/bin/env ruby
# Migrates Checkpoint from Localizable.strings (en.lproj/) to a String Catalog
# (Localizable.xcstrings). Does two things to the pbxproj:
#   1. Registers `es` as a known region.
#   2. Removes the legacy PBXVariantGroup for Localizable.strings.
#
# Adding the new Localizable.xcstrings file is not needed here — the project's
# Resources folder is a PBXFileSystemSynchronizedRootGroup, which auto-picks up
# any file dropped into it on disk. The .strings file itself must be deleted
# from disk separately (not handled here to avoid surprise deletions).
require "xcodeproj"

PROJECT_PATH = "apps/checkpoint/ios/checkpoint.xcodeproj"

project = Xcodeproj::Project.open(PROJECT_PATH)

regions = project.root_object.known_regions || []
unless regions.include?("es")
  project.root_object.known_regions = (regions + ["es"]).uniq
  puts "Added 'es' to knownRegions"
end

legacy_variant = project.objects.select { |o| o.isa == "PBXVariantGroup" }
                        .find { |vg| vg.name == "Localizable.strings" }

if legacy_variant
  project.targets.each do |target|
    target.resources_build_phase.files.to_a.each do |bf|
      next unless bf.file_ref == legacy_variant
      target.resources_build_phase.remove_build_file(bf)
      puts "Removed legacy Localizable.strings from #{target.name} resources"
    end
  end
  legacy_variant.remove_from_project
  puts "Removed legacy PBXVariantGroup"
end

project.save
puts "Saved #{PROJECT_PATH}"
