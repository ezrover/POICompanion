#!/usr/bin/env ruby

# Ensure xcodeproj gem is available
gem_path = File.expand_path("~/.gem/ruby/2.6.0/gems")
$LOAD_PATH.unshift(gem_path) if File.directory?(gem_path)

# Load xcodeproj
begin
  require 'xcodeproj'
rescue LoadError
  Dir["#{gem_path}/*/lib"].each { |lib| $LOAD_PATH.unshift(lib) }
  require 'xcodeproj'
end

# Open the project
project_path = 'RoadtripCopilot.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Models group
main_group = project.main_group['RoadtripCopilot']
models_group = main_group['Models']

if models_group.nil?
  puts "Error: Could not find Models group"
  exit 1
end

# Fix the file paths - just use the filename since they're in the Models group
files_to_fix = ['AutoDiscoverManager.swift', 'POIRankingEngine.swift', 'POI.swift']

models_group.files.each do |file_ref|
  filename = File.basename(file_ref.path)
  if files_to_fix.include?(filename)
    puts "Fixing path for #{filename}: #{file_ref.path} -> #{filename}"
    file_ref.path = filename
    file_ref.source_tree = '<group>'
  end
end

# Save the project
project.save
puts "\n✅ Xcode project paths fixed successfully!"