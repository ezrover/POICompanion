#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'RoadtripCopilot.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get the main group
main_group = project.main_group

# Find or create the Models group
models_group = main_group.groups.find { |g| g.name == 'Models' }
if models_group.nil?
  models_group = main_group.new_group('Models')
end

# Find or create the Managers group  
managers_group = main_group.groups.find { |g| g.name == 'Managers' }
if managers_group.nil?
  managers_group = main_group.new_group('Managers')
end

# Files to add
files_to_add = [
  { path: 'Roadtrip-Copilot/Models/Gemma3NE2BLoader.swift', group: models_group },
  { path: 'Roadtrip-Copilot/Models/Gemma3NE4BLoader.swift', group: models_group },
  { path: 'RoadtripCopilot/Managers/ModelManager.swift', group: managers_group }
]

# Add each file
files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]
  
  # Check if file already exists in project
  existing_ref = project.files.find { |f| f.path&.include?(File.basename(file_path)) }
  
  if existing_ref.nil? && File.exist?(file_path)
    # Add the file reference
    file_ref = group.new_reference(file_path)
    
    # Add to build phase
    target.source_build_phase.add_file_reference(file_ref)
    
    puts "Added #{file_path} to project"
  elsif existing_ref
    puts "#{file_path} already in project"
  else
    puts "Warning: #{file_path} not found on disk"
  end
end

# Save the project
project.save

puts "Project updated successfully!"