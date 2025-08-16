#!/usr/bin/env ruby

# Ensure xcodeproj gem is available with user install path
gem_path = File.expand_path("~/.gem/ruby/2.6.0/gems")
$LOAD_PATH.unshift(gem_path) if File.directory?(gem_path)

# Try to load from user gem path
begin
  require 'xcodeproj'
rescue LoadError
  # Try with explicit path
  Dir["#{gem_path}/*/lib"].each { |lib| $LOAD_PATH.unshift(lib) }
  require 'xcodeproj'
end

# Open the Xcode project
project_path = 'RoadtripCopilot.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'RoadtripCopilot' }

if target.nil?
  puts "Error: Could not find target 'RoadtripCopilot'"
  exit 1
end

# Find or create the Models group
main_group = project.main_group['RoadtripCopilot']
models_group = main_group['Models'] || main_group.new_group('Models')

# Files to add
files_to_add = [
  'RoadtripCopilot/Models/AutoDiscoverManager.swift',
  'RoadtripCopilot/Models/POIRankingEngine.swift', 
  'RoadtripCopilot/Models/POI.swift'
]

# Add each file to the project
files_to_add.each do |file_path|
  # Check if file already exists in project
  existing_ref = models_group.files.find { |f| f.path.end_with?(File.basename(file_path)) }
  
  if existing_ref
    puts "File already in project: #{File.basename(file_path)}"
  else
    # Add new file reference
    file_ref = models_group.new_file(file_path)
    
    # Add to target's build phase
    target.add_file_references([file_ref])
    
    puts "Added to project: #{File.basename(file_path)}"
  end
end

# Save the project
project.save
puts "\n✅ Xcode project updated successfully!"
puts "The following files have been added to the RoadtripCopilot target:"
files_to_add.each { |f| puts "  - #{File.basename(f)}" }