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

# Correct the file paths
files_to_fix = {
  'AutoDiscoverManager.swift' => 'Models/AutoDiscoverManager.swift',
  'POIRankingEngine.swift' => 'Models/POIRankingEngine.swift',
  'POI.swift' => 'Models/POI.swift'
}

models_group.files.each do |file_ref|
  filename = File.basename(file_ref.path)
  if files_to_fix.key?(filename)
    correct_path = files_to_fix[filename]
    puts "Fixing path for #{filename}: #{file_ref.path} -> #{correct_path}"
    file_ref.path = correct_path
  end
end

# Save the project
project.save
puts "\n✅ Xcode project paths fixed successfully!"